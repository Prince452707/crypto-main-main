package crypto.insight.crypto.config;

import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCache;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    @Primary
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager(
                "cryptoSearch",
                "cryptoDetails",
                "ohlcvData",
                "teamData",
                "marketChart",
                "combinedCryptoData",
                "cryptoNews",
                "cryptoIdentities"
        );
    }
    
    @Bean(name = "identityCache")
    public Cache identityCache() {
        return new ConcurrentMapCache("cryptoIdentities");
    }
}
