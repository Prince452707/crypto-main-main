package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.service.SmartCachingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Optimized controller for cryptocurrency data with smart caching
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/optimized")
@CrossOrigin(originPatterns = "*", allowCredentials = "true")
public class OptimizedCryptoController {

    @Autowired
    private SmartCachingService smartCachingService;

    /**
     * Get cryptocurrency data with optimized caching
     * Reduces API calls by using intelligent caching and request throttling
     */
    @GetMapping("/crypto/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Cryptocurrency>>> getOptimizedCrypto(@PathVariable String symbol) {
        log.info("Optimized request for cryptocurrency: {}", symbol);
        
        return smartCachingService.getCryptocurrencyWithSmartCaching(symbol)
                .map(crypto -> {
                    log.debug("Successfully returned optimized data for {}", symbol);
                    return ResponseEntity.ok(ApiResponse.success(crypto, "Cryptocurrency data retrieved (optimized)"));
                })
                .onErrorResume(e -> {
                    log.error("Error in optimized crypto request for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error retrieving cryptocurrency: " + e.getMessage())));
                });
    }

    /**
     * Get multiple cryptocurrencies with batch optimization
     * Significantly reduces API calls by batching and caching
     */
    @PostMapping("/crypto/batch")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> getOptimizedBatch(
            @RequestBody List<String> symbols) {
        
        log.info("Optimized batch request for {} symbols: {}", symbols.size(), symbols);
        
        if (symbols.size() > 20) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Maximum 20 symbols allowed per batch request")));
        }
        
        return smartCachingService.getMultipleCryptocurrenciesOptimized(symbols)
                .collectList()
                .map(cryptos -> {
                    log.debug("Successfully returned {} cryptocurrencies from optimized batch", cryptos.size());
                    return ResponseEntity.ok(ApiResponse.success(cryptos, 
                            String.format("Retrieved %d cryptocurrencies (optimized)", cryptos.size())));
                })
                .onErrorResume(e -> {
                    log.error("Error in optimized batch request: {}", e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error retrieving cryptocurrencies: " + e.getMessage())));
                });
    }

    /**
     * Get popular cryptocurrencies with optimized caching
     */
    @GetMapping("/crypto/popular")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> getPopularCryptosOptimized(
            @RequestParam(defaultValue = "10") int limit) {
        
        log.info("Optimized request for popular cryptocurrencies (limit: {})", limit);
        
        // Popular cryptocurrency symbols
        List<String> popularSymbols = Arrays.asList(
                "bitcoin", "ethereum", "binancecoin", "cardano", "solana",
                "xrp", "polkadot", "dogecoin", "avalanche", "polygon"
        ).subList(0, Math.min(limit, 10));
        
        return smartCachingService.getMultipleCryptocurrenciesOptimized(popularSymbols)
                .collectList()
                .map(cryptos -> {
                    log.debug("Successfully returned {} popular cryptocurrencies", cryptos.size());
                    return ResponseEntity.ok(ApiResponse.success(cryptos, "Popular cryptocurrencies retrieved (optimized)"));
                })
                .onErrorResume(e -> {
                    log.error("Error in optimized popular cryptos request: {}", e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error retrieving popular cryptocurrencies: " + e.getMessage())));
                });
    }

    /**
     * Clear cache for specific symbol (admin endpoint)
     */
    @DeleteMapping("/cache/{symbol}")
    public ResponseEntity<ApiResponse<String>> clearCacheForSymbol(@PathVariable String symbol) {
        log.info("Clearing cache for symbol: {}", symbol);
        
        smartCachingService.clearCacheForSymbol(symbol);
        
        return ResponseEntity.ok(ApiResponse.success(
                "Cache cleared for " + symbol, 
                "Cache successfully cleared"));
    }

    /**
     * Clear all cache (admin endpoint)
     */
    @DeleteMapping("/cache/all")
    public ResponseEntity<ApiResponse<String>> clearAllCache() {
        log.info("Clearing all cache");
        
        smartCachingService.clearAllCache();
        
        return ResponseEntity.ok(ApiResponse.success(
                "All cache cleared", 
                "Cache successfully cleared"));
    }

    /**
     * Get cache statistics (monitoring endpoint)
     */
    @GetMapping("/cache/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCacheStats() {
        Map<String, Object> stats = smartCachingService.getCacheStatistics();
        
        return ResponseEntity.ok(ApiResponse.success(stats, "Cache statistics retrieved"));
    }

    /**
     * Health check for optimized endpoints
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        Map<String, Object> health = Map.of(
                "status", "healthy",
                "service", "OptimizedCryptoController",
                "features", Arrays.asList("smart_caching", "request_throttling", "batch_optimization"),
                "timestamp", System.currentTimeMillis()
        );
        
        return ResponseEntity.ok(ApiResponse.success(health, "Optimized service is healthy"));
    }
}
