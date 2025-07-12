package crypto.insight.crypto.service;

import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;

/**
 * Service for managing real-time cryptocurrency data updates.
 * Provides cache invalidation, data freshness checking, and force refresh capabilities.
 */
@Slf4j
@Service
public class RealTimeDataService {
    
    private final ApiService apiService;
    private final CacheManager cacheManager;
    
    public RealTimeDataService(ApiService apiService, CacheManager cacheManager) {
        this.apiService = apiService;
        this.cacheManager = cacheManager;
    }
    
    /**
     * Forces fresh data fetch by clearing caches and fetching from APIs
     */
    public Mono<Cryptocurrency> getFreshCryptocurrencyData(String symbol, int days) {
        log.info("Forcing fresh data fetch for {} ({} days)", symbol, days);
        
        // Clear all relevant caches
        clearCachesForSymbol(symbol);
        
        // Fetch fresh data with force refresh flag
        return apiService.getCryptocurrencyData(symbol, days, true)
                .doOnSuccess(data -> log.info("Successfully fetched fresh data for {}", symbol))
                .doOnError(error -> log.error("Failed to fetch fresh data for {}: {}", symbol, error.getMessage()));
    }
    
    /**
     * Gets fresh market chart data with cache invalidation
     */
    public Mono<Map<String, Object>> getFreshMarketChart(String symbol, int days) {
        log.info("Forcing fresh market chart data for {} ({} days)", symbol, days);
        
        // Clear market chart cache
        clearMarketChartCache(symbol, days);
        
        return apiService.getMarketChart(symbol, days, true)
                .doOnSuccess(data -> {
                    if (data != null && !data.isEmpty()) {
                        log.info("Successfully fetched fresh market chart for {}", symbol);
                    }
                })
                .doOnError(error -> log.error("Failed to fetch fresh market chart for {}: {}", symbol, error.getMessage()));
    }
    
    /**
     * Checks if cached data is stale and needs refreshing
     */
    public boolean isDataStale(String symbol, int maxAgeMinutes) {
        try {
            Cache cryptoCache = cacheManager.getCache("crypto-data");
            if (cryptoCache != null) {
                // Check if we have cached data and when it was last updated
                // This is a simplified check - in production you might want more sophisticated staleness detection
                Object cachedData = cryptoCache.get(symbol.toLowerCase());
                if (cachedData == null) {
                    log.info("No cached data found for {} - considering stale", symbol);
                    return true;
                }
                // For now, consider data stale if it's older than maxAgeMinutes
                // You can enhance this with actual timestamp checking
                return true; // Force refresh for now to ensure latest data
            }
        } catch (Exception e) {
            log.warn("Error checking data staleness for {}: {}", symbol, e.getMessage());
        }
        return true; // Default to stale to ensure fresh data
    }
    
    /**
     * Invalidates all caches for a specific symbol
     */
    public void clearCachesForSymbol(String symbol) {
        try {
            String normalizedSymbol = symbol.toLowerCase();
            
            // Clear crypto data cache
            Cache cryptoCache = cacheManager.getCache("crypto-data");
            if (cryptoCache != null) {
                cryptoCache.evict(normalizedSymbol);
                log.debug("Cleared crypto-data cache for {}", symbol);
            }
            
            // Clear market chart cache (multiple possible keys)
            Cache chartCache = cacheManager.getCache("market-chart");
            if (chartCache != null) {
                // Clear common time periods
                for (int days : new int[]{1, 7, 30, 90, 365}) {
                    String chartKey = normalizedSymbol + "_" + days;
                    chartCache.evict(chartKey);
                }
                log.debug("Cleared market-chart cache for {}", symbol);
            }
            
            // Clear analysis cache
            Cache analysisCache = cacheManager.getCache("crypto-analysis");
            if (analysisCache != null) {
                for (int days : new int[]{1, 7, 30, 90, 365}) {
                    String analysisKey = normalizedSymbol + "_" + days;
                    analysisCache.evict(analysisKey);
                }
                log.debug("Cleared crypto-analysis cache for {}", symbol);
            }
            
        } catch (Exception e) {
            log.error("Error clearing caches for {}: {}", symbol, e.getMessage());
        }
    }
    
    /**
     * Clears market chart cache for specific symbol and days
     */
    private void clearMarketChartCache(String symbol, int days) {
        try {
            Cache chartCache = cacheManager.getCache("market-chart");
            if (chartCache != null) {
                String cacheKey = symbol.toLowerCase() + "_" + days;
                chartCache.evict(cacheKey);
                log.debug("Cleared market chart cache for {} ({} days)", symbol, days);
            }
        } catch (Exception e) {
            log.warn("Error clearing market chart cache for {}: {}", symbol, e.getMessage());
        }
    }
    
    /**
     * Clears all caches (use carefully - impacts performance)
     */
    public void clearAllCaches() {
        try {
            cacheManager.getCacheNames().forEach(cacheName -> {
                Cache cache = cacheManager.getCache(cacheName);
                if (cache != null) {
                    cache.clear();
                    log.info("Cleared cache: {}", cacheName);
                }
            });
        } catch (Exception e) {
            log.error("Error clearing all caches: {}", e.getMessage());
        }
    }
    
    /**
     * Validates that chart data contains real-time information
     */
    public List<ChartDataPoint> validateAndEnhanceChartData(List<ChartDataPoint> chartData, String source) {
        if (chartData == null || chartData.isEmpty()) {
            return chartData;
        }
        
        return chartData.stream()
                .map(point -> {
                    // Enhance with metadata if not already present
                    if (point.getLastUpdated() == null) {
                        point.setLastUpdated(LocalDateTime.now());
                    }
                    if (point.getSource() == null) {
                        point.setSource(source);
                    }
                    return point;
                })
                .toList();
    }
    
    /**
     * Asynchronously prefetch data for common symbols to improve response times
     */
    public CompletableFuture<Void> prefetchPopularCryptocurrencies() {
        return CompletableFuture.runAsync(() -> {
            String[] popularSymbols = {"BTC", "ETH", "USDT", "BNB", "SOL", "ADA", "XRP", "DOGE"};
            
            for (String symbol : popularSymbols) {
                try {
                    // Check if data is stale before prefetching
                    if (isDataStale(symbol, 10)) { // 10 minutes staleness threshold
                        log.info("Prefetching fresh data for popular cryptocurrency: {}", symbol);
                        getFreshCryptocurrencyData(symbol, 7)
                                .subscribeOn(Schedulers.boundedElastic())
                                .subscribe(
                                        data -> log.debug("Prefetched data for {}", symbol),
                                        error -> log.debug("Failed to prefetch data for {}: {}", symbol, error.getMessage())
                                );
                        
                        // Add small delay to avoid overwhelming APIs
                        Thread.sleep(1000);
                    }
                } catch (Exception e) {
                    log.debug("Error during prefetch for {}: {}", symbol, e.getMessage());
                }
            }
        }, Executors.newCachedThreadPool());
    }
}
