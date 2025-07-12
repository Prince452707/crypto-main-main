package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Service
public class CircuitBreakerService {
    
    private final Map<String, CircuitBreakerState> circuitBreakers = new ConcurrentHashMap<>();
    private final Map<String, Object> fallbackCache = new ConcurrentHashMap<>();
    
    // Circuit breaker configuration
    private static final int FAILURE_THRESHOLD = 5;
    private static final Duration TIMEOUT_DURATION = Duration.ofSeconds(30);
    private static final int SUCCESS_THRESHOLD = 3;
    
    public enum State {
        CLOSED,    // Normal operation
        OPEN,      // Circuit open, using fallbacks
        HALF_OPEN  // Testing if service recovered
    }
    
    /**
     * Execute with circuit breaker protection
     */
    public <T> Mono<T> executeWithBreaker(String serviceName, Mono<T> operation, T fallbackValue) {
        CircuitBreakerState breaker = getOrCreateBreaker(serviceName);
        
        if (breaker.state == State.OPEN) {
            if (breaker.shouldAttemptReset()) {
                breaker.state = State.HALF_OPEN;
                log.debug("Circuit breaker {} moved to HALF_OPEN", serviceName);
            } else {
                // Return cached fallback immediately
                return Mono.just(getFallbackValue(serviceName, fallbackValue));
            }
        }
        
        return operation
                .timeout(Duration.ofSeconds(10))
                .doOnSuccess(result -> {
                    breaker.onSuccess();
                    cacheFallbackValue(serviceName, result);
                })
                .doOnError(error -> breaker.onFailure())
                .onErrorReturn(getFallbackValue(serviceName, fallbackValue));
    }
    
    /**
     * Fast-fail for critical operations
     */
    public <T> Mono<T> executeWithFastFail(String serviceName, Mono<T> operation, T fallbackValue) {
        CircuitBreakerState breaker = getOrCreateBreaker(serviceName);
        
        if (breaker.state == State.OPEN) {
            // Immediate fallback without trying
            return Mono.just(getFallbackValue(serviceName, fallbackValue));
        }
        
        return operation
                .timeout(Duration.ofSeconds(5)) // Shorter timeout for fast-fail
                .doOnSuccess(result -> {
                    breaker.onSuccess();
                    cacheFallbackValue(serviceName, result);
                })
                .doOnError(error -> breaker.onFailure())
                .onErrorReturn(getFallbackValue(serviceName, fallbackValue));
    }
    
    /**
     * Bulk operation with individual circuit breakers
     */
    public Mono<List<Cryptocurrency>> executeBulkWithBreakers(
            List<String> symbols, 
            java.util.function.Function<String, Mono<Cryptocurrency>> operation) {
        
        List<Mono<Cryptocurrency>> operations = symbols.stream()
                .map(symbol -> executeWithBreaker(
                    "crypto-details-" + symbol,
                    operation.apply(symbol),
                    createFallbackCrypto(symbol)
                ))
                .toList();
        
        return Mono.zip(operations, results -> 
            java.util.Arrays.stream(results)
                .map(result -> (Cryptocurrency) result)
                .filter(crypto -> crypto != null)
                .toList()
        );
    }
    
    /**
     * Get or create circuit breaker for service
     */
    private CircuitBreakerState getOrCreateBreaker(String serviceName) {
        return circuitBreakers.computeIfAbsent(serviceName, k -> new CircuitBreakerState());
    }
    
    /**
     * Cache fallback values for instant retrieval
     */
    private <T> void cacheFallbackValue(String serviceName, T value) {
        fallbackCache.put(serviceName, value);
    }
    
    /**
     * Get cached fallback value or default
     */
    @SuppressWarnings("unchecked")
    private <T> T getFallbackValue(String serviceName, T defaultValue) {
        Object cached = fallbackCache.get(serviceName);
        if (cached != null) {
            try {
                return (T) cached;
            } catch (ClassCastException e) {
                log.warn("Fallback cache type mismatch for {}", serviceName);
            }
        }
        return defaultValue;
    }
    
    /**
     * Create fallback cryptocurrency object
     */
    private Cryptocurrency createFallbackCrypto(String symbol) {
        return Cryptocurrency.builder()
                .symbol(symbol.toUpperCase())
                .name("Loading...")
                .price(BigDecimal.ZERO)
                .marketCap(BigDecimal.ZERO)
                .volume24h(BigDecimal.ZERO)
                .percentChange24h(BigDecimal.ZERO)
                .build();
    }
    
    /**
     * Get circuit breaker statistics
     */
    public Map<String, Object> getCircuitBreakerStats() {
        Map<String, Object> stats = new ConcurrentHashMap<>();
        
        circuitBreakers.forEach((service, breaker) -> {
            stats.put(service, Map.of(
                "state", breaker.state,
                "failures", breaker.failureCount.get(),
                "successes", breaker.successCount.get(),
                "lastFailure", breaker.lastFailureTime,
                "totalRequests", breaker.failureCount.get() + breaker.successCount.get()
            ));
        });
        
        stats.put("totalServices", circuitBreakers.size());
        stats.put("openCircuits", circuitBreakers.values().stream()
                .mapToInt(breaker -> breaker.state == State.OPEN ? 1 : 0)
                .sum());
        stats.put("cachedFallbacks", fallbackCache.size());
        
        return stats;
    }
    
    /**
     * Reset all circuit breakers (for testing/maintenance)
     */
    public void resetAllBreakers() {
        circuitBreakers.values().forEach(breaker -> {
            breaker.state = State.CLOSED;
            breaker.failureCount.set(0);
            breaker.successCount.set(0);
            breaker.lastFailureTime.set(0);
        });
        log.info("All circuit breakers reset");
    }
    
    /**
     * Circuit breaker state management
     */
    private static class CircuitBreakerState {
        volatile State state = State.CLOSED;
        final AtomicInteger failureCount = new AtomicInteger(0);
        final AtomicInteger successCount = new AtomicInteger(0);
        final AtomicLong lastFailureTime = new AtomicLong(0);
        
        void onSuccess() {
            successCount.incrementAndGet();
            
            if (state == State.HALF_OPEN && successCount.get() >= SUCCESS_THRESHOLD) {
                state = State.CLOSED;
                failureCount.set(0);
                log.debug("Circuit breaker moved to CLOSED after {} successes", SUCCESS_THRESHOLD);
            }
        }
        
        void onFailure() {
            int failures = failureCount.incrementAndGet();
            lastFailureTime.set(System.currentTimeMillis());
            
            if (state == State.CLOSED && failures >= FAILURE_THRESHOLD) {
                state = State.OPEN;
                log.warn("Circuit breaker OPENED after {} failures", failures);
            } else if (state == State.HALF_OPEN) {
                state = State.OPEN;
                log.debug("Circuit breaker moved back to OPEN from HALF_OPEN");
            }
        }
        
        boolean shouldAttemptReset() {
            return System.currentTimeMillis() - lastFailureTime.get() > TIMEOUT_DURATION.toMillis();
        }
    }
}
