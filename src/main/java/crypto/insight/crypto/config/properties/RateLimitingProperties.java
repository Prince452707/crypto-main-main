package crypto.insight.crypto.config.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@Data
@ConfigurationProperties(prefix = "app.rate-limiting")
public class RateLimitingProperties {
    
    /**
     * Global rate limiting settings
     */
    private Global global = new Global();
    
    /**
     * Provider-specific rate limiting settings
     */
    private Providers providers = new Providers();
    
    @Data
    public static class Global {
        private boolean enabled = true;
        private int maxRequestsPerSecond = 10;
        private Duration cooldownPeriod = Duration.ofMinutes(5);
        private boolean fallbackToCache = true;
    }
    
    @Data
    public static class Providers {
        private Provider coinGecko = new Provider(50, Duration.ofMinutes(1));
        private Provider coinMarketCap = new Provider(30, Duration.ofMinutes(1));
        private Provider cryptoCompare = new Provider(100, Duration.ofMinutes(1));
        private Provider coinPaprika = new Provider(25, Duration.ofMinutes(1));
    }
    
    @Data
    public static class Provider {
        private int maxRequestsPerMinute;
        private Duration rateLimitWindow;
        private boolean enabled = true;
        private Duration backoffDelay = Duration.ofSeconds(30);
        
        public Provider() {}
        
        public Provider(int maxRequestsPerMinute, Duration rateLimitWindow) {
            this.maxRequestsPerMinute = maxRequestsPerMinute;
            this.rateLimitWindow = rateLimitWindow;
        }
    }
}
