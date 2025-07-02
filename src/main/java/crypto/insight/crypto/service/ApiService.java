package crypto.insight.crypto.service;

import crypto.insight.crypto.config.ApiProperties;
import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.service.provider.DataProvider;
import lombok.extern.slf4j.Slf4j;
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

    /**
     * Gets aggregated crypto data with option to force refresh (bypass cache)
     */
    public Mono<CryptoData> getAggregatedCryptoData(String query, boolean forceRefresh) {
        String normalizedQuery = query.trim().toLowerCase();

        if (forceRefresh) {
            log.info("Force refresh requested for '{}' - bypassing cache", normalizedQuery);
            // Clear cache for this query
            identityCache.evict(normalizedQuery);
            return resolveAndCacheIdentity(normalizedQuery)
                    .flatMap(this::fetchAllDataFromProviders);
        } else {
            return getAggregatedCryptoData(normalizedQuery);
        }
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
                .flatMap(provider -> 
                    provider.fetchData(identity)
                        .doOnError(error -> log.warn("Provider {} failed to fetch data for {}: {}", 
                            provider.getProviderName(), identity.getSymbol(), error.getMessage()))
                        .onErrorResume(error -> {
                            log.debug("Skipping provider {} due to error: {}", provider.getProviderName(), error.getMessage());
                            return Mono.empty(); // Skip this provider and continue with others
                        }))
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
     * Legacy method for backward compatibility with refresh option
     */
    public Mono<Cryptocurrency> getCryptocurrencyData(String symbol, int days, boolean forceRefresh) {
        log.warn("Legacy getCryptocurrencyData called for {} with refresh={}. Delegating to new aggregation method. 'days' parameter is ignored.", symbol, forceRefresh);
        return getAggregatedCryptoData(symbol, forceRefresh)
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
                .imageUrl(cryptoData.getImageUrl())
                .rank(cryptoData.getMarketCapRank() != null ? cryptoData.getMarketCapRank().intValue() : 0)
                .circulatingSupply(cryptoData.getCirculatingSupply())
                .totalSupply(cryptoData.getTotalSupply())
                .maxSupply(cryptoData.getMaxSupply())
                .lastUpdated(cryptoData.getLastUpdated())
                .build();
    }

    /**
     * Searches for cryptocurrencies by query using all available providers, or returns popular ones if query is empty.
     * This method now uses the multi-provider aggregation system for more comprehensive and current data.
     * 
     * @param query The search query (can be empty or null for popular cryptocurrencies)
     * @return A Flux of Cryptocurrency objects matching the search or popular cryptocurrencies
     */
    public Flux<Cryptocurrency> searchCryptocurrencies(String query) {
        log.debug("Searching for cryptocurrencies with query: {}", query);
        
        // If query is empty or null, return a default list of popular cryptocurrencies from all providers
        if (query == null || query.trim().isEmpty()) {
            log.info("Empty search query, returning default list of popular cryptocurrencies from all providers");
            
            // Get popular cryptos from multiple providers and merge them
            String[] popularCryptos = {"BTC", "ETH", "BNB", "XRP", "ADA", "SOL", "DOT", "MATIC", "AVAX", "LINK", "UNI", "LTC", "ATOM", "FTM", "ALGO"};
            
            return Flux.fromArray(popularCryptos)
                    .flatMap(symbol -> getAggregatedCryptoData(symbol)
                            .map(this::mapToLegacyCryptocurrency)
                            .onErrorResume(e -> {
                                log.debug("Failed to fetch data for {}: {}", symbol, e.getMessage());
                                return Mono.empty();
                            }))
                    .take(50) // Limit to 50 popular cryptos
                    .sort((a, b) -> {
                        // Sort by market cap rank if available
                        if (a.getRank() != null && b.getRank() != null) {
                            return Integer.compare(a.getRank(), b.getRank());
                        }
                        return 0;
                    });
        }
        
        // If there's a query, use aggregated search
        return getAggregatedCryptoData(query)
                .map(this::mapToLegacyCryptocurrency)
                .flux()
                .onErrorResume(e -> {
                    log.warn("Aggregated search failed for '{}', falling back to CoinGecko search: {}", query, e.getMessage());
                    return fallbackCoinGeckoSearch(query);
                });
    }
    
    /**
     * Fallback method using CoinGecko search when aggregated search fails
     */
    private Flux<Cryptocurrency> fallbackCoinGeckoSearch(String query) {
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
                            return Flux.fromIterable(mapFromCoinGeckoSearch(coins));
                        } catch (ClassCastException e) {
                            log.error("Unexpected response format from CoinGecko search: {}", e.getMessage());
                            return Flux.empty();
                        }
                    }
                    return Flux.empty();
                })
                .onErrorResume(e -> {
                    log.error("Error in fallback CoinGecko search: {}", e.getMessage());
                    return Flux.empty();
                });
    }

    /**
     * Fetches detailed information for a specific cryptocurrency by its CoinGecko ID.
     * This method now uses aggregated data when possible.
     */
    public Mono<Cryptocurrency> getCryptocurrencyDetails(String id) {
        log.debug("Fetching details for coin ID: {}", id);
        
        // Try to get aggregated data first
        return getAggregatedCryptoData(id)
                .map(this::mapToLegacyCryptocurrency)
                .onErrorResume(e -> {
                    log.debug("Aggregated data failed for '{}', falling back to CoinGecko: {}", id, e.getMessage());
                    return fallbackCoinGeckoDetails(id);
                });
    }
    
    /**
     * Fallback method for getting details from CoinGecko only
     */
    private Mono<Cryptocurrency> fallbackCoinGeckoDetails(String id) {
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

    /**
     * Fetches the market chart data with option to force refresh
     */
    public Mono<Map<String, Object>> getMarketChart(String id, int days, boolean forceRefresh) {
        if (forceRefresh) {
            log.info("Force refresh requested for market chart data: {} for {} days", id, days);
            // For market chart, we don't have explicit caching but the providers might cache
            // We'll just call the regular method as it should get fresh data from APIs
        }
        return getMarketChart(id, days);
    }

    // Helper methods for mapping CoinGecko API responses

    private List<Cryptocurrency> mapFromCoinGeckoSearch(List<Map<String, Object>> coins) {
        return coins.stream()
                .map(coin -> Cryptocurrency.builder()
                        .id(safeString(coin.get("id")))
                        .name(safeString(coin.get("name")))
                        .symbol(safeString(coin.get("symbol")).toUpperCase())
                        .imageUrl(safeString(coin.get("large")))
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
                                .imageUrl(safeString(market.get("image")))
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
                .imageUrl(safeString(imageData.get("large")))
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

    /**
     * Fetches general crypto news from CryptoCompare API.
     * @param limit Number of news articles to fetch
     * @param lang Language preference
     * @return A Flux containing the crypto news
     */
    public Flux<crypto.insight.crypto.model.CryptoNews> getCryptoNews(int limit, String lang) {
        log.debug("Fetching crypto news with limit: {} and language: {}", limit, lang);
        String url = apiProperties.getCryptocompare().getCryptoCompareBaseUrl() + "/v2/news/?lang=" + lang;

        return webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .flatMapMany(response -> {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> newsData = (List<Map<String, Object>>) response.get("Data");
                    if (newsData != null) {
                        return Flux.fromIterable(newsData)
                                .take(limit)
                                .map(this::mapToCryptoNews);
                    }
                    return Flux.empty();
                })
                .doOnError(error -> log.error("Error fetching crypto news: {}", error.getMessage()));
    }

    /**
     * Fetches crypto news for a specific symbol from CryptoCompare API.
     * @param symbol The cryptocurrency symbol
     * @param limit Number of news articles to fetch
     * @param lang Language preference
     * @return A Flux containing the crypto news for the symbol
     */
    public Flux<crypto.insight.crypto.model.CryptoNews> getCryptoNewsBySymbol(String symbol, int limit, String lang) {
        log.debug("Fetching crypto news for symbol: {} with limit: {} and language: {}", symbol, limit, lang);
        String url = apiProperties.getCryptocompare().getCryptoCompareBaseUrl() + "/v2/news/?categories=" + symbol.toUpperCase() + "&lang=" + lang;

        return webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .flatMapMany(response -> {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> newsData = (List<Map<String, Object>>) response.get("Data");
                    if (newsData != null) {
                        return Flux.fromIterable(newsData)
                                .take(limit)
                                .map(this::mapToCryptoNews);
                    }
                    return Flux.empty();
                })
                .doOnError(error -> log.error("Error fetching crypto news for {}: {}", symbol, error.getMessage()));
    }

    /**
     * Maps CryptoCompare news data to CryptoNews model.
     */
    private crypto.insight.crypto.model.CryptoNews mapToCryptoNews(Map<String, Object> newsData) {
        crypto.insight.crypto.model.CryptoNews news = new crypto.insight.crypto.model.CryptoNews();
        news.setId((String) newsData.get("id"));
        news.setTitle((String) newsData.get("title"));
        news.setBody((String) newsData.get("body"));
        news.setUrl((String) newsData.get("url"));
        news.setSource((String) newsData.get("source"));
        news.setImageUrl((String) newsData.get("imageurl"));
        news.setTags((String) newsData.get("tags"));
        news.setCategories((String) newsData.get("categories"));
        news.setLang((String) newsData.get("lang"));
        
        Object publishedOn = newsData.get("published_on");
        if (publishedOn instanceof Number) {
            news.setPublishedOn(((Number) publishedOn).longValue());
        }
        
        return news;
    }

}