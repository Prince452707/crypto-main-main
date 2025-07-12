package crypto.insight.crypto.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.time.Duration;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    @Primary
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager(
                "cryptoSearch",
                "cryptoDetails", 
                "ohlcvData",
                "teamData",
                "marketChart",
                "combinedCryptoData",
                "cryptoNews",
                "cryptoIdentities",
                "cryptoData", // Add cache for crypto data
                // Ultra-fast caches
                "ultraFastMarketData",
                "ultraFastSearch", 
                "ultraFastDetails",
                // Focused crypto caches
                "detailCache",
                "priceCache",
                "rateLimitCache",
                // Optimization caches
                "cryptocurrencies",
                "market-data",
                "chart-data",
                "analysis-data"
        );
        
        // Set all caches to expire after 5 minutes
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .maximumSize(1000)
                .expireAfterWrite(Duration.ofMinutes(5)) // 5 minutes for all cache entries
                .recordStats());
        
        return cacheManager;
    }
    
    /**
     * Real-time price cache with very short TTL
     */
    @Bean(name = "realTimePriceCache")
    public Cache realTimePriceCache() {
        return new CaffeineCache("realTimePrices", 
                Caffeine.newBuilder()
                        .maximumSize(200)
                        .expireAfterWrite(Duration.ofSeconds(15)) // 15 seconds for real-time prices
                        .recordStats()
                        .build());
    }
    
    /**
     * Chart data cache with medium TTL
     */
    @Bean(name = "chartDataCache")
    public Cache chartDataCache() {
        return new CaffeineCache("chartData", 
                Caffeine.newBuilder()
                        .maximumSize(100)
                        .expireAfterWrite(Duration.ofMinutes(2)) // 2 minutes for chart data
                        .recordStats()
                        .build());
    }
    
    // Individual cache beans that some services depend on via @Qualifier
    // These are separate from the CacheManager's internal caches
    
    @Bean(name = "identityCache")
    public Cache identityCache() {
        // Identity cache with longer expiration (30 minutes) since crypto IDs don't change often
        return new CaffeineCache("identityCache", 
                Caffeine.newBuilder()
                        .maximumSize(1000)
                        .expireAfterWrite(Duration.ofMinutes(30))
                        .build());
    }
    
    @Bean(name = "dataCache")
    public Cache dataCache() {
        // Data cache with very short expiration (30 seconds) for real-time price data
        return new CaffeineCache("dataCache", 
                Caffeine.newBuilder()
                        .maximumSize(100)
                        .expireAfterWrite(Duration.ofSeconds(30))
                        .recordStats()
                        .build());
    }
}

