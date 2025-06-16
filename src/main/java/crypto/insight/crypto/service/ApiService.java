package crypto.insight.crypto.service;

import crypto.insight.crypto.config.ApiProperties;
import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.service.provider.DataProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.Cache;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Orchestration service for aggregating cryptocurrency data from multiple providers.
 * This service manages identity resolution, data fetching with fallbacks, and caching,
 * while also providing legacy and specific-purpose endpoints for the controllers.
 */
@Slf4j
@Service
public class ApiService {

    private final List<DataProvider> dataProviders;
    private final Cache identityCache;
    private final WebClient webClient;
    private final ApiProperties apiProperties;

    @Autowired
    public ApiService(List<DataProvider> dataProviders, 
                     @org.springframework.beans.factory.annotation.Qualifier("identityCache") Cache identityCache,
                     @org.springframework.beans.factory.annotation.Qualifier("webClient") WebClient webClient,
                     ApiProperties apiProperties) {
        this.dataProviders = dataProviders;
        this.identityCache = identityCache;
        this.webClient = webClient;
        this.apiProperties = apiProperties;
    }

    /**
     * Main entry point to get aggregated data for a cryptocurrency.
     * It resolves the identity and then fetches data from all available sources.
     *
     * @param query The user's search query (e.g., "BTC", "Bitcoin", "bitcoin").
     * @return A Mono containing the aggregated crypto data.
     */
    public Mono<CryptoData> getAggregatedCryptoData(String query) {
        String normalizedQuery = query.trim().toLowerCase();

        return Mono.justOrEmpty(identityCache.get(normalizedQuery, CryptoIdentity.class))
                .doOnNext(cachedIdentity -> log.info("Cache hit for identity: '{}' -> {}", normalizedQuery, cachedIdentity.getSymbol()))
                .switchIfEmpty(resolveAndCacheIdentity(normalizedQuery))
                .flatMap(this::fetchAllDataFromProviders);
    }

    private Mono<CryptoIdentity> resolveAndCacheIdentity(String query) {
        log.info("Cache miss for identity: '{}'. Resolving from providers.", query);
        return Flux.fromIterable(dataProviders)
                .concatMap(provider -> provider.resolveIdentity(query)
                        .doOnSuccess(id -> log.info("Provider '{}' resolved '{}' -> {}", provider.getProviderName(), query, id.getSymbol()))
                        .onErrorResume(e -> {
                            log.debug("Provider '{}' failed to resolve identity for '{}': {}", provider.getProviderName(), query, e.getMessage());
                            return Mono.empty();
                        }))
                .collectList()
                .flatMap(identities -> {
                    if (identities.isEmpty()) {
                        return Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "Could not resolve cryptocurrency: " + query));
                    }
                    
                    // Start with the first identity and merge all others into it
                    CryptoIdentity mergedIdentity = identities.get(0);
                    for (int i = 1; i < identities.size(); i++) {
                        mergedIdentity.merge(identities.get(i));
                    }
                    
                    log.info("Merged identity for '{}': {}", query, mergedIdentity);
                    identityCache.put(query, mergedIdentity);
                    return Mono.just(mergedIdentity);
                });
    }

    private Mono<CryptoData> fetchAllDataFromProviders(CryptoIdentity identity) {
        log.info("Fetching all data for resolved identity: {} ({})", identity.getSymbol(), identity.getName());

        return Flux.fromIterable(dataProviders)
                .flatMap(provider -> provider.fetchData(identity))
                .reduce(new CryptoData(identity), (aggregatedData, newData) -> {
                    log.debug("Merging data from provider: {}", newData.getSource());
                    aggregatedData.mergeWith(newData);
                    return aggregatedData;
                });
    }

    /**
     * Legacy method for backward compatibility.
     */
    public Mono<Cryptocurrency> getCryptocurrencyData(String symbol, int days) {
        log.warn("Legacy getCryptocurrencyData called for {}. Delegating to new aggregation method. 'days' parameter is ignored.", symbol);
        return getAggregatedCryptoData(symbol)
                .map(this::mapToLegacyCryptocurrency);
    }

    /**
     * Maps the new CryptoData model to the old Cryptocurrency model for backward compatibility.
     */
    private Cryptocurrency mapToLegacyCryptocurrency(CryptoData cryptoData) {
        if (cryptoData == null || cryptoData.getIdentity() == null) {
            return null;
        }
        
        CryptoIdentity identity = cryptoData.getIdentity();

        return Cryptocurrency.builder()
                .id(identity.getId())
                .symbol(identity.getSymbol())
                .name(identity.getName())
                .price(cryptoData.getPrice() != null ? cryptoData.getPrice() : BigDecimal.ZERO)
                .marketCap(cryptoData.getMarketCap())
                .volume24h(cryptoData.getVolume24h())
                .percentChange24h(cryptoData.getPercentChange24h())
                .image(cryptoData.getImageUrl())
                .rank(cryptoData.getMarketCapRank() != null ? cryptoData.getMarketCapRank().intValue() : 0)
                .circulatingSupply(cryptoData.getCirculatingSupply())
                .totalSupply(cryptoData.getTotalSupply())
                .maxSupply(cryptoData.getMaxSupply())
                .lastUpdated(cryptoData.getLastUpdated())
                .build();
    }

    /**
     * Searches for cryptocurrencies based on a query string using CoinGecko.
     * If the query is empty, returns a default list of popular cryptocurrencies.
     */
    /**
     * Searches for cryptocurrencies by query or returns a default list of popular ones if query is empty.
     * 
     * @param query The search query (can be empty or null for popular cryptocurrencies)
     * @return A Flux of Cryptocurrency objects matching the search or popular cryptocurrencies
     */
    public Flux<Cryptocurrency> searchCryptocurrencies(String query) {
        log.debug("Searching for cryptocurrencies with query: {}", query);
        
        // If query is empty or null, return a default list of popular cryptocurrencies
        if (query == null || query.trim().isEmpty()) {
            log.info("Empty search query, returning default list of popular cryptocurrencies");
            String defaultUrl = apiProperties.getCoinGeckoBaseUrl() + 
                    "/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false";
            
            return webClient.get()
                    .uri(defaultUrl)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<List<Map<String, Object>>>() {})
                    .doOnNext(markets -> {
                        if (markets == null || markets.isEmpty()) {
                            log.warn("Received empty markets data from CoinGecko");
                        } else {
                            log.debug("Successfully fetched {} popular cryptocurrencies", markets.size());
                        }
                    })
                    .flatMapMany(markets -> {
                        if (markets == null || markets.isEmpty()) {
                            return Flux.empty();
                        }
                        try {
                            List<Cryptocurrency> cryptoList = mapFromCoinGeckoMarkets(markets);
                            log.debug("Mapped {} market items to Cryptocurrency objects", cryptoList.size());
                            return Flux.fromIterable(cryptoList);
                        } catch (Exception e) {
                            log.error("Error mapping market data to Cryptocurrency objects: {}", e.getMessage(), e);
                            return Flux.error(e);
                        }
                    })
                    .onErrorResume(e -> {
                        log.error("Error fetching default cryptocurrencies: {}", e.getMessage(), e);
                        return Flux.empty();
                    });
        }
        
        // If there's a query, search for it
        String url = apiProperties.getCoinGeckoBaseUrl() + "/search?query=" + query;

        return webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .flatMapMany(response -> {
                    Object coinsObj = response.get("coins");
                    if (coinsObj instanceof List) {
                        try {
                            @SuppressWarnings("unchecked")
                            List<Map<String, Object>> coins = (List<Map<String, Object>>) coinsObj;
                            if (coins.isEmpty()) {
                                log.info("No results found for query: {}", query);
                                return Flux.empty();
                            }
                            return Flux.fromIterable(mapFromCoinGeckoSearch(coins));
                        } catch (ClassCastException e) {
                            log.warn("Unexpected coins format in response", e);
                        }
                    }
                    return Flux.empty();
                })
                .onErrorResume(e -> {
                    log.error("Error searching for cryptocurrencies: {}", e.getMessage());
                    return Flux.empty();
                });
    }

    /**
     * Fetches detailed information for a specific cryptocurrency by its CoinGecko ID.
     */
    public Mono<Cryptocurrency> getCryptocurrencyDetails(String id) {
        log.debug("Fetching details for coin ID: {}", id);
        String url = apiProperties.getCoinGeckoBaseUrl() + "/coins/" + id;

        return webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .map(this::mapFromCoinGeckoDetails);
    }

    /**
     * Fetches the market chart data for a specific cryptocurrency with fallback mechanisms.
     * Tries multiple endpoints and formats to ensure data is returned when available.
     */
    public Mono<Map<String, Object>> getMarketChart(String id, int days) {
        log.info("Fetching market chart for coin ID: {} for {} days", id, days);
        
        // Ensure we're using the correct CoinGecko ID format (ix-swap instead of ixs)
        String coingeckoId = id;
        if (id.equals("ixs")) {
            coingeckoId = "ix-swap";
            log.info("Mapped ID '{}' to CoinGecko ID '{}'", id, coingeckoId);
        }
        
        // Primary endpoint - market chart with prices
        String primaryUrl = String.format("%s/coins/%s/market_chart?vs_currency=usd&days=%d&interval=daily",
                apiProperties.getCoinGeckoBaseUrl(), coingeckoId, days);
        
        // Fallback endpoint - ohlc data if market_chart fails
        String fallbackUrl = String.format("%s/coins/%s/ohlc?vs_currency=usd&days=%d",
                apiProperties.getCoinGeckoBaseUrl(), coingeckoId, days);
                
        log.debug("Using URLs - Primary: {}, Fallback: {}", primaryUrl, fallbackUrl);

        return webClient.get()
                .uri(primaryUrl)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .onErrorResume(e -> {
                    log.warn("Primary market chart endpoint failed for {}: {}. Trying fallback...", id, e.getMessage());
                    return webClient.get()
                            .uri(fallbackUrl)
                            .retrieve()
                            .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                            .map(this::convertOhlcToMarketChart);
                })
                .doOnSuccess(data -> {
                    if (data != null && !data.isEmpty()) {
                        log.info("Successfully fetched market chart data for {}", id);
                    } else {
                        log.warn("Received empty market chart data for {}", id);
                    }
                })
                .onErrorResume(e -> {
                    log.error("Failed to fetch market chart data for {}: {}", id, e.getMessage());
                    return Mono.just(Map.of(
                        "prices", List.of(),
                        "market_caps", List.of(),
                        "total_volumes", List.of()
                    ));
                });
    }
    
    /**
     * Converts OHLC data to market chart format
     */
    private Map<String, Object> convertOhlcToMarketChart(Map<String, Object> ohlcData) {
        if (ohlcData == null || ohlcData.isEmpty()) {
            return Map.of(
                "prices", List.of(),
                "market_caps", List.of(),
                "total_volumes", List.of()
            );
        }
        
        // Convert OHLC format to market chart format
        List<List<Number>> prices = new ArrayList<>();
        if (ohlcData.get("prices") instanceof List) {
            @SuppressWarnings("unchecked")
            List<List<Number>> ohlcPrices = (List<List<Number>>) ohlcData.get("prices");
            for (List<Number> ohlc : ohlcPrices) {
                if (ohlc != null && ohlc.size() >= 2) {
                    // Use timestamp and close price
                    prices.add(List.of(ohlc.get(0), ohlc.get(4)));
                }
            }
        }
        
        return Map.of(
            "prices", prices,
            "market_caps", ohlcData.getOrDefault("market_caps", List.of()),
            "total_volumes", ohlcData.getOrDefault("total_volumes", List.of())
        );
    }

    // Helper methods for mapping CoinGecko API responses

    private List<Cryptocurrency> mapFromCoinGeckoSearch(List<Map<String, Object>> coins) {
        return coins.stream()
                .map(coin -> Cryptocurrency.builder()
                        .id(safeString(coin.get("id")))
                        .name(safeString(coin.get("name")))
                        .symbol(safeString(coin.get("symbol")).toUpperCase())
                        .image(safeString(coin.get("large")))
                        .rank(safeInteger(coin.get("market_cap_rank")))
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Maps a list of market data from CoinGecko to a list of Cryptocurrency objects.
     * 
     * @param markets List of market data maps from CoinGecko API
     * @return List of mapped Cryptocurrency objects
     * @throws NullPointerException if the input list is null
     * @throws ClassCastException if the market data has unexpected types
     */
    private List<Cryptocurrency> mapFromCoinGeckoMarkets(List<Map<String, Object>> markets) {
        if (markets == null) {
            throw new NullPointerException("Markets list cannot be null");
        }
        
        log.debug("Mapping {} market items to Cryptocurrency objects", markets.size());
        
        return markets.stream()
                .map(market -> {
                    try {
                        if (market == null) {
                            log.warn("Encountered null market item, skipping");
                            return null;
                        }
                        
                        String id = safeString(market.get("id"));
                        String name = safeString(market.get("name"));
                        String symbol = safeString(market.get("symbol"));
                        
                        if (id == null || name == null || symbol == null) {
                            log.warn("Missing required fields in market data: id={}, name={}, symbol={}", 
                                    id, name, symbol);
                            return null;
                        }
                        
                        log.trace("Mapping market data for {}/{} (ID: {})", symbol, name, id);
                        
                        return Cryptocurrency.builder()
                                .id(id)
                                .name(name)
                                .symbol(symbol.toUpperCase())
                                .price(safeBigDecimal(market.get("current_price")))
                                .marketCap(safeBigDecimal(market.get("market_cap")))
                                .volume24h(safeBigDecimal(market.get("total_volume")))
                                .percentChange24h(safeBigDecimal(market.get("price_change_percentage_24h")))
                                .image(safeString(market.get("image")))
                                .rank(safeInteger(market.get("market_cap_rank")))
                                .circulatingSupply(safeBigDecimal(market.get("circulating_supply")))
                                .totalSupply(safeBigDecimal(market.get("total_supply")))
                                .maxSupply(safeBigDecimal(market.get("max_supply")))
                                .high24h(safeBigDecimal(market.get("high_24h")))
                                .low24h(safeBigDecimal(market.get("low_24h")))
                                .build();
                    } catch (Exception e) {
                        log.error("Error mapping market data item: {}", e.getMessage(), e);
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    private Cryptocurrency mapFromCoinGeckoDetails(Map<String, Object> data) {
        // ... (rest of the code remains the same)
        if (data == null) {
            throw new IllegalArgumentException("Data map cannot be null");
        }
        
        Map<String, Object> marketData = data.get("market_data") instanceof Map 
            ? (Map<String, Object>) data.get("market_data") 
            : Map.of();
            
        Map<String, Object> currentPrice = marketData.get("current_price") instanceof Map 
            ? (Map<String, Object>) marketData.get("current_price") 
            : Map.of();
            
        Map<String, Object> marketCap = marketData.get("market_cap") instanceof Map 
            ? (Map<String, Object>) marketData.get("market_cap") 
            : Map.of();
            
        Map<String, Object> totalVolume = marketData.get("total_volume") instanceof Map 
            ? (Map<String, Object>) marketData.get("total_volume") 
            : Map.of();
            
        Map<String, Object> imageData = data.get("image") instanceof Map 
            ? (Map<String, Object>) data.get("image") 
            : Map.of();

        return Cryptocurrency.builder()
                .id(safeString(data.get("id")))
                .symbol(safeString(data.get("symbol")).toUpperCase())
                .name(safeString(data.get("name")))
                .image(safeString(imageData.get("large")))
                .price(safeBigDecimal(currentPrice.get("usd")))
                .marketCap(safeBigDecimal(marketCap.get("usd")))
                .volume24h(safeBigDecimal(totalVolume.get("usd")))
                .circulatingSupply(safeBigDecimal(marketData.get("circulating_supply")))
                .totalSupply(safeBigDecimal(marketData.get("total_supply")))
                .maxSupply(safeBigDecimal(marketData.get("max_supply")))
                .rank(safeInteger(data.get("market_cap_rank")))
                .lastUpdated(LocalDateTime.now())
                .build();
    }

    // Safe parsing methods

    private String safeString(Object obj) {
        return obj != null ? obj.toString() : "";
    }

    private Integer safeInteger(Object obj) {
        if (obj == null) return 0;
        try {
            if (obj instanceof Number) {
                return ((Number) obj).intValue();
            }
            return Integer.parseInt(obj.toString());
        } catch (NumberFormatException e) {
            log.warn("Failed to parse integer: {}", obj);
            return 0;
        }
    }

    private BigDecimal safeBigDecimal(Object obj) {
        if (obj == null) return BigDecimal.ZERO;
        try {
            if (obj instanceof Number) {
                return new BigDecimal(obj.toString());
            }
            return new BigDecimal(obj.toString().replaceAll("[^\\d.-]+", ""));
        } catch (NumberFormatException e) {
            log.warn("Failed to parse BigDecimal: {}", obj);
            return BigDecimal.ZERO;
        }
    }

    /**
     * Fetches market data for a cryptocurrency from CoinGecko API.
     * @param coinId The CoinGecko coin ID
     * @return A Mono containing the cryptocurrency data
     */
    public Mono<Cryptocurrency> getMarketData(String coinId) {
        log.debug("Fetching market data for coin ID: {}", coinId);
        String url = apiProperties.getCoinGeckoBaseUrl() + "/coins/" + coinId;

        return webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .map(this::mapFromCoinGeckoDetails);
    }


}