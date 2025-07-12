package crypto.insight.crypto.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import crypto.insight.crypto.service.SmartCachingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Configuration for API call optimization and caching
 */
@Slf4j
@Configuration
@EnableCaching
@EnableScheduling
public class OptimizationConfig {

    @Autowired(required = false)
    private SmartCachingService smartCachingService;



    /**
     * Reset hourly request counters every hour
     */
    @Scheduled(fixedRate = 3600000) // Every hour
    public void resetHourlyCounters() {
        if (smartCachingService != null) {
            smartCachingService.resetHourlyCounters();
            log.debug("🔄 Reset hourly request counters");
        }
    }

    /**
     * Log cache statistics every 5 minutes
     */
    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void logCacheStatistics() {
        if (smartCachingService != null) {
            try {
                var stats = smartCachingService.getCacheStatistics();
                log.info("📊 Cache Stats - Size: {}, Currently Fetching: {}, Total Requests: {}", 
                        stats.get("cacheSize"), 
                        stats.get("currentlyFetching"),
                        stats.get("totalRequests"));
            } catch (Exception e) {
                log.warn("⚠️ Failed to log cache statistics: {}", e.getMessage());
            }
        }
    }

    /**
     * Clean up stale cache entries every 10 minutes
     */
    @Scheduled(fixedRate = 600000) // Every 10 minutes
    public void cleanupStaleEntries() {
        // This could be enhanced to remove stale entries based on TTL
        log.debug("🧹 Cache cleanup scheduled task executed");
    }
}
