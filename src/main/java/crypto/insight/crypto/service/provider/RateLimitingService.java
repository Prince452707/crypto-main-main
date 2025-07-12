package crypto.insight.crypto.service.provider;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Advanced rate limiting service with exponential backoff and circuit breaker pattern
 * to handle API rate limits from multiple crypto data providers
 */
@Service
@Slf4j
public class RateLimitingService {
    
    // Rate limit tracking per provider
    private final ConcurrentHashMap<String, ProviderRateLimit> providerLimits = new ConcurrentHashMap<>();
    
    // Circuit breaker state per provider
    private final ConcurrentHashMap<String, CircuitBreakerState> circuitBreakers = new ConcurrentHashMap<>();
    
    // Default rate limits (requests per minute)
    private static final int COINGECKO_FREE_LIMIT = 30;
    private static final int COINMARKETCAP_FREE_LIMIT = 10;
    private static final int COINPAPRIKA_FREE_LIMIT = 25;
    private static final int CRYPTOCOMPARE_FREE_LIMIT = 100;
    
    // Circuit breaker thresholds
    private static final int FAILURE_THRESHOLD = 5;
    private static final Duration CIRCUIT_BREAKER_TIMEOUT = Duration.ofMinutes(2);
    
    public static class ProviderRateLimit {
        private final AtomicInteger requestCount = new AtomicInteger(0);
        private final AtomicInteger failureCount = new AtomicInteger(0);
        private volatile Instant windowStart = Instant.now();
        private volatile Instant lastRequest = Instant.now();
        private final int maxRequests;
        private final Duration windowDuration = Duration.ofMinutes(1);
        
        public ProviderRateLimit(int maxRequests) {
            this.maxRequests = maxRequests;
        }
        
        public boolean canMakeRequest() {
            Instant now = Instant.now();
            
            // Reset window if needed
            if (Duration.between(windowStart, now).compareTo(windowDuration) >= 0) {
                requestCount.set(0);
                windowStart = now;
            }
            
            return requestCount.get() < maxRequests;
        }
        
        public void recordRequest() {
            requestCount.incrementAndGet();
            lastRequest = Instant.now();
        }
        
        public void recordFailure() {
            failureCount.incrementAndGet();
        }
        
        public void recordSuccess() {
            failureCount.set(0); // Reset failure count on success
        }
        
        public int getFailureCount() {
            return failureCount.get();
        }
        
        public Duration getTimeUntilNextRequest() {
            // Calculate delay based on failure count (exponential backoff)
            int failures = failureCount.get();
            long delaySeconds = Math.min(300, (long) Math.pow(2, failures)); // Max 5 minutes
            return Duration.ofSeconds(delaySeconds);
        }
    }
    
    public static class CircuitBreakerState {
        private volatile boolean isOpen = false;
        private volatile Instant lastFailureTime = Instant.now();
        private final AtomicInteger consecutiveFailures = new AtomicInteger(0);
        
        public boolean isOpen() {
            if (isOpen && Duration.between(lastFailureTime, Instant.now()).compareTo(CIRCUIT_BREAKER_TIMEOUT) >= 0) {
                // Try to close circuit after timeout
                isOpen = false;
                consecutiveFailures.set(0);
                log.info("Circuit breaker closed after timeout");
            }
            return isOpen;
        }
        
        public void recordFailure() {
            consecutiveFailures.incrementAndGet();
            lastFailureTime = Instant.now();
            
            if (consecutiveFailures.get() >= FAILURE_THRESHOLD) {
                isOpen = true;
                log.warn("Circuit breaker opened after {} consecutive failures", consecutiveFailures.get());
            }
        }
        
        public void recordSuccess() {
            consecutiveFailures.set(0);
            if (isOpen) {
                isOpen = false;
                log.info("Circuit breaker closed after successful request");
            }
        }
    }
    
    public RateLimitingService() {
        // Initialize rate limits for each provider
        providerLimits.put("CoinGecko", new ProviderRateLimit(COINGECKO_FREE_LIMIT));
        providerLimits.put("CoinMarketCap", new ProviderRateLimit(COINMARKETCAP_FREE_LIMIT));
        providerLimits.put("CoinPaprika", new ProviderRateLimit(COINPAPRIKA_FREE_LIMIT));
        providerLimits.put("CryptoCompare", new ProviderRateLimit(CRYPTOCOMPARE_FREE_LIMIT));
        
        // Initialize circuit breakers
        circuitBreakers.put("CoinGecko", new CircuitBreakerState());
        circuitBreakers.put("CoinMarketCap", new CircuitBreakerState());
        circuitBreakers.put("CoinPaprika", new CircuitBreakerState());
        circuitBreakers.put("CryptoCompare", new CircuitBreakerState());
    }
    
    /**
     * Check if a request can be made to the specified provider
     */
    public boolean canMakeRequest(String providerName) {
        CircuitBreakerState circuitBreaker = circuitBreakers.get(providerName);
        if (circuitBreaker != null && circuitBreaker.isOpen()) {
            log.debug("Circuit breaker is open for provider: {}", providerName);
            return false;
        }
        
        ProviderRateLimit rateLimit = providerLimits.get(providerName);
        if (rateLimit != null) {
            return rateLimit.canMakeRequest();
        }
        
        return true; // Default to allow if provider not configured
    }
    
    /**
     * Get the delay before the next request can be made
     */
    public Duration getDelayBeforeNextRequest(String providerName) {
        ProviderRateLimit rateLimit = providerLimits.get(providerName);
        if (rateLimit != null) {
            return rateLimit.getTimeUntilNextRequest();
        }
        return Duration.ZERO;
    }
    
    /**
     * Record a successful request
     */
    public void recordSuccess(String providerName) {
        ProviderRateLimit rateLimit = providerLimits.get(providerName);
        if (rateLimit != null) {
            rateLimit.recordRequest();
            rateLimit.recordSuccess();
        }
        
        CircuitBreakerState circuitBreaker = circuitBreakers.get(providerName);
        if (circuitBreaker != null) {
            circuitBreaker.recordSuccess();
        }
    }
    
    /**
     * Record a failed request (rate limited or other error)
     */
    public void recordFailure(String providerName, boolean isRateLimited) {
        ProviderRateLimit rateLimit = providerLimits.get(providerName);
        if (rateLimit != null) {
            if (isRateLimited) {
                rateLimit.recordRequest(); // Count as a request even if rate limited
            }
            rateLimit.recordFailure();
        }
        
        CircuitBreakerState circuitBreaker = circuitBreakers.get(providerName);
        if (circuitBreaker != null) {
            circuitBreaker.recordFailure();
        }
    }
    
    /**
     * Get provider priority based on current state (less failures = higher priority)
     */
    public int getProviderPriority(String providerName) {
        CircuitBreakerState circuitBreaker = circuitBreakers.get(providerName);
        if (circuitBreaker != null && circuitBreaker.isOpen()) {
            return Integer.MAX_VALUE; // Lowest priority
        }
        
        ProviderRateLimit rateLimit = providerLimits.get(providerName);
        if (rateLimit != null) {
            return rateLimit.getFailureCount();
        }
        
        return 0; // Default priority
    }
    
    /**
     * Create a rate-limited Mono that respects the provider's limits
     */
    public <T> Mono<T> executeWithRateLimit(String providerName, Mono<T> operation) {
        return Mono.defer(() -> {
            if (!canMakeRequest(providerName)) {
                Duration delay = getDelayBeforeNextRequest(providerName);
                log.debug("Rate limiting {} - delaying request by {} seconds", providerName, delay.getSeconds());
                
                return Mono.delay(delay)
                    .then(operation)
                    .doOnSuccess(result -> recordSuccess(providerName))
                    .doOnError(error -> {
                        boolean isRateLimited = error.getMessage().contains("429") || 
                                               error.getMessage().contains("Too Many Requests");
                        recordFailure(providerName, isRateLimited);
                    });
            } else {
                return operation
                    .doOnSuccess(result -> recordSuccess(providerName))
                    .doOnError(error -> {
                        boolean isRateLimited = error.getMessage().contains("429") || 
                                               error.getMessage().contains("Too Many Requests");
                        recordFailure(providerName, isRateLimited);
                    });
            }
        });
    }
    
    /**
     * Get rate limit status for all providers
     */
    public String getRateLimitStatus() {
        StringBuilder status = new StringBuilder();
        status.append("Rate Limit Status:\n");
        
        for (String provider : providerLimits.keySet()) {
            ProviderRateLimit limit = providerLimits.get(provider);
            CircuitBreakerState circuit = circuitBreakers.get(provider);
            
            status.append(String.format("  %s: Requests=%d/%d, Failures=%d, Circuit=%s\n",
                provider, 
                limit.requestCount.get(), 
                limit.maxRequests,
                limit.getFailureCount(),
                circuit.isOpen() ? "OPEN" : "CLOSED"
            ));
        }
        
        return status.toString();
    }
}
