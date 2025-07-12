package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Smart caching service to optimize API calls and reduce external API rate limits
 */
@Slf4j
@Service
public class SmartCachingService {

    @Autowired
    private ApiService apiService;

    @Autowired
    private CacheManager cacheManager;

    // Request tracking to prevent API spam
    private final Map<String, LocalDateTime> lastRequestTimes = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> requestCounts = new ConcurrentHashMap<>();
    private final Set<String> currentlyFetching = ConcurrentHashMap.newKeySet();

    // Cache configuration
    private static final Duration MIN_REQUEST_INTERVAL = Duration.ofSeconds(10); // 10 seconds between requests for same symbol
    private static final Duration CACHE_TTL = Duration.ofMinutes(3); // 3 minutes cache validity
    private static final long MAX_HOURLY_REQUESTS_PER_SYMBOL = 20; // Max 20 requests per symbol per hour

    /**
     * Get cryptocurrency data with intelligent caching and request throttling
     */
    @Cacheable(value = "cryptocurrencies", key = "#symbol.toLowerCase()")
    public Mono<Cryptocurrency> getCryptocurrencyWithSmartCaching(String symbol) {
        String normalizedSymbol = symbol.toLowerCase();
        
        // Check if we're already fetching this symbol
        if (currentlyFetching.contains(normalizedSymbol)) {
            log.debug("Already fetching {}, waiting for completion", symbol);
            return waitForCurrentFetch(normalizedSymbol);
        }

        // Check request throttling
        if (isRequestThrottled(normalizedSymbol)) {
            log.debug("Request throttled for {}. Using cached data or fallback", symbol);
            return getCachedOrFallback(normalizedSymbol);
        }

        // Mark as currently fetching
        currentlyFetching.add(normalizedSymbol);
        updateRequestTracking(normalizedSymbol);

        return apiService.getCryptocurrencyData(symbol, 1)
                .doOnSuccess(crypto -> {
                    currentlyFetching.remove(normalizedSymbol);
                    log.debug("Successfully fetched fresh data for {}", symbol);
                })
                .doOnError(error -> {
                    currentlyFetching.remove(normalizedSymbol);
                    log.warn("Error fetching data for {}: {}", symbol, error.getMessage());
                })
                .onErrorResume(error -> {
                    log.warn("Falling back to cached data for {} due to error: {}", symbol, error.getMessage());
                    return getCachedOrFallback(normalizedSymbol);
                });
    }

    /**
     * Get multiple cryptocurrencies with batch optimization
     */
    public Flux<Cryptocurrency> getMultipleCryptocurrenciesOptimized(List<String> symbols) {
        // Split into cached and uncached symbols
        List<String> uncachedSymbols = new ArrayList<>();
        List<Cryptocurrency> cachedCryptos = new ArrayList<>();

        for (String symbol : symbols) {
            String normalizedSymbol = symbol.toLowerCase();
            Cryptocurrency cached = getCachedCryptocurrency(normalizedSymbol);
            
            if (cached != null && isCacheValid(normalizedSymbol)) {
                cachedCryptos.add(cached);
                log.debug("Using cached data for {}", symbol);
            } else if (!isRequestThrottled(normalizedSymbol)) {
                uncachedSymbols.add(normalizedSymbol);
            }
        }

        // Return cached data immediately
        Flux<Cryptocurrency> cachedFlux = Flux.fromIterable(cachedCryptos);

        // Fetch uncached data with staggered delays to avoid rate limits
        Flux<Cryptocurrency> freshFlux = Flux.fromIterable(uncachedSymbols)
                .index()
                .delayElements(Duration.ofMillis(200)) // 200ms delay between requests
                .flatMap(indexedSymbol -> {
                    String symbol = indexedSymbol.getT2();
                    return getCryptocurrencyWithSmartCaching(symbol)
                            .onErrorResume(error -> {
                                log.warn("Failed to fetch {}: {}", symbol, error.getMessage());
                                return Mono.empty();
                            });
                });

        return Flux.concat(cachedFlux, freshFlux);
    }

    /**
     * Check if a request should be throttled
     */
    private boolean isRequestThrottled(String symbol) {
        LocalDateTime lastRequest = lastRequestTimes.get(symbol);
        
        if (lastRequest != null) {
            Duration timeSinceLastRequest = Duration.between(lastRequest, LocalDateTime.now());
            if (timeSinceLastRequest.compareTo(MIN_REQUEST_INTERVAL) < 0) {
                return true; // Too soon since last request
            }
        }

        // Check hourly request limit
        AtomicLong requestCount = requestCounts.get(symbol);
        if (requestCount != null && requestCount.get() >= MAX_HOURLY_REQUESTS_PER_SYMBOL) {
            return true;
        }

        return false;
    }

    /**
     * Update request tracking for a symbol
     */
    private void updateRequestTracking(String symbol) {
        lastRequestTimes.put(symbol, LocalDateTime.now());
        requestCounts.computeIfAbsent(symbol, k -> new AtomicLong(0)).incrementAndGet();
    }

    /**
     * Get cached cryptocurrency data
     */
    private Cryptocurrency getCachedCryptocurrency(String symbol) {
        Cache cache = cacheManager.getCache("cryptocurrencies");
        if (cache != null) {
            Cache.ValueWrapper wrapper = cache.get(symbol);
            if (wrapper != null) {
                return (Cryptocurrency) wrapper.get();
            }
        }
        return null;
    }

    /**
     * Check if cached data is still valid
     */
    private boolean isCacheValid(String symbol) {
        // For now, rely on Spring's cache TTL
        // Could be enhanced with more sophisticated cache validation
        return getCachedCryptocurrency(symbol) != null;
    }

    /**
     * Get cached data or fallback to basic data
     */
    private Mono<Cryptocurrency> getCachedOrFallback(String symbol) {
        Cryptocurrency cached = getCachedCryptocurrency(symbol);
        
        if (cached != null) {
            return Mono.just(cached);
        }

        // Create a basic fallback cryptocurrency object
        return Mono.just(Cryptocurrency.builder()
                .id(symbol.toLowerCase())
                .name(symbol.toUpperCase())
                .symbol(symbol.toUpperCase())
                .price(BigDecimal.ZERO)
                .percentChange24h(BigDecimal.ZERO)
                .lastUpdated(LocalDateTime.now())
                .build());
    }

    /**
     * Wait for currently fetching request to complete
     */
    private Mono<Cryptocurrency> waitForCurrentFetch(String symbol) {
        return Mono.defer(() -> {
            if (currentlyFetching.contains(symbol)) {
                return Mono.delay(Duration.ofMillis(100))
                        .then(waitForCurrentFetch(symbol));
            } else {
                Cryptocurrency cached = getCachedCryptocurrency(symbol);
                if (cached != null) {
                    return Mono.just(cached);
                } else {
                    return getCachedOrFallback(symbol);
                }
            }
        });
    }

    /**
     * Clear cache for a specific symbol
     */
    @CacheEvict(value = "cryptocurrencies", key = "#symbol.toLowerCase()")
    public void clearCacheForSymbol(String symbol) {
        log.debug("Cleared cache for {}", symbol);
        currentlyFetching.remove(symbol.toLowerCase());
    }

    /**
     * Clear all cached data
     */
    @CacheEvict(value = "cryptocurrencies", allEntries = true)
    public void clearAllCache() {
        log.info("Cleared all cryptocurrency cache");
        currentlyFetching.clear();
        lastRequestTimes.clear();
    }

    /**
     * Reset request counters (called by scheduled task)
     */
    public void resetHourlyCounters() {
        requestCounts.clear();
        log.debug("Reset hourly request counters");
    }

    /**
     * Get cache statistics
     */
    public Map<String, Object> getCacheStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        Cache cache = cacheManager.getCache("cryptocurrencies");
        if (cache != null && cache.getNativeCache() instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<Object, Object> nativeCache = (Map<Object, Object>) cache.getNativeCache();
            stats.put("cacheSize", nativeCache.size());
        } else {
            stats.put("cacheSize", 0);
        }
        
        stats.put("currentlyFetching", currentlyFetching.size());
        stats.put("trackedSymbols", lastRequestTimes.size());
        stats.put("totalRequests", requestCounts.values().stream().mapToLong(AtomicLong::get).sum());
        stats.put("lastResetTime", LocalDateTime.now().toString());
        
        return stats;
    }
}
