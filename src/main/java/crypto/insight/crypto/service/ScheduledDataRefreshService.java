package crypto.insight.crypto.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.CacheManager;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import reactor.core.scheduler.Schedulers;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;

/**
 * Scheduled service to automatically refresh cryptocurrency data for popular symbols
 * This ensures users get fresh data even when cached data expires
 */
@Slf4j
@Service
public class ScheduledDataRefreshService {
    
    private final RealTimeDataService realTimeDataService;
    private final ApiService apiService;
    private final CacheManager cacheManager;
    
    // Popular cryptocurrencies to refresh automatically
    private final List<String> popularSymbols = List.of(
        "BTC", "ETH", "USDT", "BNB", "SOL", "USDC", "ADA", "XRP", 
        "DOGE", "AVAX", "TRX", "DOT", "MATIC", "LTC", "SHIB", "LINK"
    );
    
    public ScheduledDataRefreshService(
            RealTimeDataService realTimeDataService, 
            ApiService apiService,
            CacheManager cacheManager) {
        this.realTimeDataService = realTimeDataService;
        this.apiService = apiService;
        this.cacheManager = cacheManager;
    }
    
    /**
     * Refresh popular cryptocurrencies every 2 minutes
     */
    @Scheduled(fixedRate = 120000) // 2 minutes
    public void refreshPopularCryptocurrencies() {
        log.info("Starting scheduled refresh of popular cryptocurrencies at {}", LocalDateTime.now());
        
        popularSymbols.forEach(symbol -> {
            CompletableFuture.runAsync(() -> {
                try {
                    // Check if data is stale before refreshing
                    if (realTimeDataService.isDataStale(symbol, 3)) { // 3 minutes threshold
                        log.debug("Refreshing data for popular symbol: {}", symbol);
                        
                        // Refresh basic crypto data
                        realTimeDataService.getFreshCryptocurrencyData(symbol, 7)
                                .subscribeOn(Schedulers.boundedElastic())
                                .subscribe(
                                    data -> log.trace("Refreshed data for {}", symbol),
                                    error -> log.debug("Failed to refresh data for {}: {}", symbol, error.getMessage())
                                );
                        
                        // Small delay to avoid overwhelming APIs
                        Thread.sleep(500);
                    }
                } catch (Exception e) {
                    log.debug("Error during scheduled refresh for {}: {}", symbol, e.getMessage());
                }
            }, Executors.newCachedThreadPool());
        });
    }
    
    /**
     * Clean up expired cache entries every 5 minutes
     */
    @Scheduled(fixedRate = 300000) // 5 minutes
    public void cleanupCaches() {
        log.debug("Starting scheduled cache cleanup at {}", LocalDateTime.now());
        
        try {
            // Get cache statistics if available
            cacheManager.getCacheNames().forEach(cacheName -> {
                var cache = cacheManager.getCache(cacheName);
                if (cache != null) {
                    // Force eviction of expired entries by accessing cache
                    // This triggers Caffeine's cleanup process
                    cache.getNativeCache();
                }
            });
            
            log.debug("Cache cleanup completed");
        } catch (Exception e) {
            log.warn("Error during cache cleanup: {}", e.getMessage());
        }
    }
    
    /**
     * Refresh chart data for top 5 cryptocurrencies every 5 minutes
     */
    @Scheduled(fixedRate = 300000) // 5 minutes
    public void refreshTopChartData() {
        log.info("Starting scheduled chart data refresh at {}", LocalDateTime.now());
        
        List<String> topSymbols = popularSymbols.subList(0, Math.min(5, popularSymbols.size()));
        
        topSymbols.forEach(symbol -> {
            CompletableFuture.runAsync(() -> {
                try {
                    log.debug("Refreshing chart data for top symbol: {}", symbol);
                    
                    realTimeDataService.getFreshMarketChart(symbol, 7)
                            .subscribeOn(Schedulers.boundedElastic())
                            .subscribe(
                                data -> log.trace("Refreshed chart data for {}", symbol),
                                error -> log.debug("Failed to refresh chart data for {}: {}", symbol, error.getMessage())
                            );
                    
                    // Delay between chart refreshes
                    Thread.sleep(1000);
                } catch (Exception e) {
                    log.debug("Error during chart refresh for {}: {}", symbol, e.getMessage());
                }
            }, Executors.newCachedThreadPool());
        });
    }
    
    /**
     * Daily cache statistics logging
     */
    @Scheduled(cron = "0 0 9 * * *") // 9 AM daily
    public void logCacheStatistics() {
        log.info("=== Daily Cache Statistics ===");
        
        cacheManager.getCacheNames().forEach(cacheName -> {
            var cache = cacheManager.getCache(cacheName);
            if (cache != null) {
                try {
                    // Try to get native cache for statistics
                    Object nativeCache = cache.getNativeCache();
                    if (nativeCache instanceof com.github.benmanes.caffeine.cache.Cache) {
                        var caffeineCache = (com.github.benmanes.caffeine.cache.Cache<?, ?>) nativeCache;
                        var stats = caffeineCache.stats();
                        
                        log.info("Cache '{}': Size={}, Hit Rate={:.2f}%, Evictions={}", 
                                cacheName, 
                                caffeineCache.estimatedSize(),
                                stats.hitRate() * 100,
                                stats.evictionCount());
                    } else {
                        log.info("Cache '{}': Native cache type not supported for statistics", cacheName);
                    }
                } catch (Exception e) {
                    log.debug("Could not get statistics for cache '{}': {}", cacheName, e.getMessage());
                }
            }
        });
        
        log.info("=== End Cache Statistics ===");
    }
    
    /**
     * Manual trigger for cache refresh (can be called via REST endpoint)
     */
    public void triggerManualRefresh() {
        log.info("Manual cache refresh triggered");
        
        // Clear all caches
        realTimeDataService.clearAllCaches();
        
        // Refresh top 3 cryptocurrencies immediately
        List<String> topThree = popularSymbols.subList(0, 3);
        topThree.forEach(symbol -> {
            realTimeDataService.getFreshCryptocurrencyData(symbol, 7)
                    .subscribeOn(Schedulers.boundedElastic())
                    .subscribe(
                        data -> log.info("Manually refreshed data for {}", symbol),
                        error -> log.error("Failed to manually refresh data for {}: {}", symbol, error.getMessage())
                    );
        });
    }
}
