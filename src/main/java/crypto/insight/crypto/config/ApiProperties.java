package crypto.insight.crypto.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for external API clients.
 * Uses 'crypto.api' prefix for all properties.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "crypto.api")
public class ApiProperties {
    
    private final CryptoCompare cryptocompare = new CryptoCompare();
    private final CoinGecko coingecko = new CoinGecko();
    private final CoinMarketCap coinmarketcap = new CoinMarketCap();
    private final RetryConfig retry = new RetryConfig();

    /**
     * Configuration for CryptoCompare API
     */
    @Data
    public static class CryptoCompare {
        private String key;
        private String baseUrl = "https://min-api.cryptocompare.com/data";
        private int rateLimitPerMinute = 30; // Default rate limit
    }

    /**
     * Configuration for CoinGecko API
     */
    @Data
    public static class CoinGecko {
        private String key;
        private String baseUrl = "https://api.coingecko.com/api/v3";
        private int rateLimitPerMinute = 50; // Free tier limit
        
        public String getBaseUrl() {
            return baseUrl != null ? baseUrl : "https://api.coingecko.com/api/v3";
        }
    }

    /**
     * Configuration for CoinMarketCap API
     */
    @Data
    public static class CoinMarketCap {
        private String key;
        private String baseUrl = "https://pro-api.coinmarketcap.com/v1";
        private int rateLimitPerMinute = 30; // Default rate limit
    }

    /**
     * Retry configuration for API calls
     */
    @Data
    public static class RetryConfig {
        private int maxAttempts = 3;
        private long backoffInitial = 1000; // 1 second
        private double backoffMultiplier = 2.0;
    }
    
    // Helper methods for backward compatibility
    public String getCoinGeckoBaseUrl() {
        return coingecko.getBaseUrl();
    }
    
    public int getCoinGeckoRateLimit() {
        return coingecko.getRateLimitPerMinute();
    }
}
