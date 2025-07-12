package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

@Slf4j
@Service
public class UltraFastApiService {
    
    private final WebClient webClient;
    private final Executor parallelExecutor;
    
    // Ultra-aggressive caching
    private static final Duration CACHE_DURATION = Duration.ofSeconds(30);
    
    public UltraFastApiService(@Qualifier("optimizedWebClient") WebClient webClient) {
        this.webClient = webClient;
        this.parallelExecutor = Executors.newCachedThreadPool(); // High concurrency thread pool
    }

    /**
     * Get market data with parallel processing and aggressive caching
     */
    @Cacheable(value = "ultraFastMarketData", key = "#page + '_' + #perPage")
    public Mono<List<Cryptocurrency>> getMarketDataUltraFast(int page, int perPage) {
        log.debug("Fetching ultra-fast market data: page={}, perPage={}", page, perPage);
        
        return webClient.get()
                .uri("https://api.coingecko.com/api/v3/coins/markets" +
                     "?vs_currency=usd&order=market_cap_desc&per_page={perPage}&page={page}" +
                     "&sparkline=false&locale=en&precision=2", perPage, page)
                .retrieve()
                .bodyToFlux(Map.class)
                .parallel(8) // Process in parallel streams
                .runOn(Schedulers.parallel())
                .map(this::mapToCryptocurrency)
                .sequential()
                .collectList()
                .timeout(Duration.ofSeconds(10))
                .onErrorResume(e -> {
                    log.warn("Failed to fetch market data, using fallback: {}", e.getMessage());
                    return Mono.just(List.of());
                });
    }

    /**
     * Search cryptocurrencies with parallel execution
     */
    @Cacheable(value = "ultraFastSearch", key = "#query + '_' + #limit")
    public Mono<List<Cryptocurrency>> searchCryptocurrenciesUltraFast(String query, int limit) {
        log.debug("Ultra-fast search for: {}", query);
        
        // Parallel search across multiple endpoints for maximum speed
        Mono<List<Cryptocurrency>> coinGeckoSearch = searchFromCoinGecko(query, limit);
        
        return coinGeckoSearch
                .timeout(Duration.ofSeconds(5))
                .onErrorResume(e -> {
                    log.warn("Search failed, using empty results: {}", e.getMessage());
                    return Mono.just(List.of());
                });
    }

    /**
     * Get cryptocurrency details with ultra-fast caching
     */
    @Cacheable(value = "ultraFastDetails", key = "#symbol.toLowerCase()")
    public Mono<Cryptocurrency> getCryptocurrencyDetailsUltraFast(String symbol) {
        log.debug("Fetching ultra-fast details for: {}", symbol);
        
        return webClient.get()
                .uri("https://api.coingecko.com/api/v3/coins/{symbol}", symbol.toLowerCase())
                .retrieve()
                .bodyToMono(Map.class)
                .map(this::mapDetailsToCryptocurrency)
                .timeout(Duration.ofSeconds(8))
                .onErrorResume(e -> {
                    log.warn("Failed to fetch details for {}: {}", symbol, e.getMessage());
                    return Mono.empty();
                });
    }

    /**
     * Batch load multiple cryptocurrencies in parallel
     */
    public Mono<List<Cryptocurrency>> batchLoadUltraFast(List<String> symbols) {
        log.debug("Batch loading {} cryptocurrencies", symbols.size());
        
        return Flux.fromIterable(symbols)
                .parallel(Math.min(symbols.size(), 10)) // Max 10 parallel requests
                .runOn(Schedulers.parallel())
                .flatMap(symbol -> getCryptocurrencyDetailsUltraFast(symbol)
                        .onErrorResume(e -> Mono.empty()))
                .sequential()
                .collectList()
                .timeout(Duration.ofSeconds(15));
    }

    /**
     * Preload critical data for instant access
     */
    public CompletableFuture<Void> preloadCriticalDataAsync() {
        return CompletableFuture.runAsync(() -> {
            try {
                log.info("Preloading critical data for ultra-fast access...");
                
                // Preload top market data
                getMarketDataUltraFast(1, 50).block();
                
                // Preload top cryptocurrencies
                List<String> topCryptos = List.of("bitcoin", "ethereum", "binancecoin", "cardano", "solana", 
                                                "ripple", "polkadot", "dogecoin", "avalanche-2", "polygon");
                batchLoadUltraFast(topCryptos).block();
                
                log.info("Critical data preloaded successfully");
            } catch (Exception e) {
                log.warn("Preload failed: {}", e.getMessage());
            }
        }, parallelExecutor);
    }

    private Mono<List<Cryptocurrency>> searchFromCoinGecko(String query, int limit) {
        return webClient.get()
                .uri("https://api.coingecko.com/api/v3/search?query={query}", query)
                .retrieve()
                .bodyToMono(Map.class)
                .map(response -> {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> coins = (List<Map<String, Object>>) response.get("coins");
                    return coins.stream()
                            .limit(limit)
                            .map(this::mapSearchToCryptocurrency)
                            .toList();
                });
    }

    private Cryptocurrency mapToCryptocurrency(Map<String, Object> data) {
        return Cryptocurrency.builder()
                .id((String) data.get("id"))
                .name((String) data.get("name"))
                .symbol(((String) data.get("symbol")).toUpperCase())
                .price(parseBigDecimal(data.get("current_price")))
                .marketCap(parseBigDecimal(data.get("market_cap")))
                .volume24h(parseBigDecimal(data.get("total_volume")))
                .percentChange24h(parseBigDecimal(data.get("price_change_percentage_24h")))
                .rank(parseInt(data.get("market_cap_rank")))
                .imageUrl((String) data.get("image"))
                .build();
    }

    private Cryptocurrency mapDetailsToCryptocurrency(Map<String, Object> data) {
        @SuppressWarnings("unchecked")
        Map<String, Object> marketData = (Map<String, Object>) data.get("market_data");
        @SuppressWarnings("unchecked")
        Map<String, Object> currentPrice = (Map<String, Object>) marketData.get("current_price");
        @SuppressWarnings("unchecked")
        Map<String, Object> marketCap = (Map<String, Object>) marketData.get("market_cap");
        @SuppressWarnings("unchecked")
        Map<String, Object> totalVolume = (Map<String, Object>) marketData.get("total_volume");
        @SuppressWarnings("unchecked")
        Map<String, Object> priceChange24h = (Map<String, Object>) marketData.get("price_change_percentage_24h_in_currency");
        
        return Cryptocurrency.builder()
                .id((String) data.get("id"))
                .name((String) data.get("name"))
                .symbol(((String) data.get("symbol")).toUpperCase())
                .price(parseBigDecimal(currentPrice.get("usd")))
                .marketCap(parseBigDecimal(marketCap.get("usd")))
                .volume24h(parseBigDecimal(totalVolume.get("usd")))
                .percentChange24h(parseBigDecimal(priceChange24h.get("usd")))
                .rank(parseInt(marketData.get("market_cap_rank")))
                .description((String) ((Map<String, Object>) data.get("description")).get("en"))
                .build();
    }

    private Cryptocurrency mapSearchToCryptocurrency(Map<String, Object> data) {
        return Cryptocurrency.builder()
                .id((String) data.get("id"))
                .name((String) data.get("name"))
                .symbol(((String) data.get("symbol")).toUpperCase())
                .rank(parseInt(data.get("market_cap_rank")))
                .imageUrl((String) data.get("large"))
                .build();
    }

    private Double parseDouble(Object value) {
        if (value == null) return null;
        if (value instanceof Number) return ((Number) value).doubleValue();
        try {
            return Double.parseDouble(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }
    
    private BigDecimal parseBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal) return (BigDecimal) value;
        if (value instanceof Number) return new BigDecimal(((Number) value).toString());
        try {
            return new BigDecimal(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Integer parseInt(Object value) {
        if (value == null) return null;
        if (value instanceof Number) return ((Number) value).intValue();
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
