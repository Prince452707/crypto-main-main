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
                "cryptoData" // Add cache for crypto data
        );
        
        // Configure cache to expire after 30 seconds to ensure very fresh data
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .maximumSize(200)
                .expireAfterWrite(Duration.ofSeconds(30))
                .recordStats());
        
        return cacheManager;
    }
    
    @Bean(name = "identityCache")
    public Cache identityCache() {
        // Identity cache with longer expiration (30 minutes) since crypto IDs don't change often
        return new CaffeineCache("cryptoIdentities", 
                Caffeine.newBuilder()
                        .maximumSize(1000)
                        .expireAfterWrite(Duration.ofMinutes(30))
                        .build());
    }
    
    @Bean(name = "dataCache")
    public Cache dataCache() {
        // Data cache with very short expiration (30 seconds) for real-time price data
        return new CaffeineCache("cryptoData", 
                Caffeine.newBuilder()
                        .maximumSize(100)
                        .expireAfterWrite(Duration.ofSeconds(30))
                        .build());
    }
}
