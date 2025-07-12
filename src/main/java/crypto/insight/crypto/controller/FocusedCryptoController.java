package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.service.FocusedCryptoDetailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Controller for handling focused cryptocurrency data requests
 * with intelligent rate limiting and comprehensive data aggregation
 */
@RestController
@RequestMapping("/api/v1/crypto/focused")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = "*", allowCredentials = "true")
public class FocusedCryptoController {

    private final FocusedCryptoDetailService focusedCryptoDetailService;

    /**
     * Get comprehensive data for a specific cryptocurrency
     * This endpoint aggregates data from all available providers with smart rate limiting
     */
    @GetMapping("/{cryptoId}")
    public Mono<ResponseEntity<Map<String, Object>>> getFocusedCryptoData(
            @PathVariable String cryptoId,
            @RequestParam(defaultValue = "false") boolean forceRefresh) {
        
        log.info("Request for focused crypto data: {} (forceRefresh: {})", cryptoId, forceRefresh);
        
        return focusedCryptoDetailService.getFocusedCryptoData(cryptoId, forceRefresh)
                .map(data -> {
                    Map<String, Object> response = Map.of(
                        "success", true,
                        "data", data,
                        "timestamp", LocalDateTime.now(),
                        "cached", !forceRefresh
                    );
                    return ResponseEntity.ok(response);
                })
                .onErrorResume(error -> {
                    log.error("Error fetching focused crypto data for {}: {}", cryptoId, error.getMessage());
                    Map<String, Object> errorResponse = Map.of(
                        "success", false,
                        "error", error.getMessage(),
                        "timestamp", LocalDateTime.now()
                    );
                    return Mono.just(ResponseEntity.badRequest().body(errorResponse));
                });
    }

    /**
     * Refresh data for a specific cryptocurrency (force refresh)
     */
    @PostMapping("/{cryptoId}/refresh")
    public Mono<ResponseEntity<Map<String, Object>>> refreshCryptoData(@PathVariable String cryptoId) {
        log.info("Force refresh request for crypto: {}", cryptoId);
        
        return focusedCryptoDetailService.refreshCryptoData(cryptoId)
                .map(data -> {
                    Map<String, Object> response = Map.of(
                        "success", true,
                        "data", data,
                        "timestamp", LocalDateTime.now(),
                        "refreshed", true
                    );
                    return ResponseEntity.ok(response);
                })
                .onErrorResume(error -> {
                    log.error("Error refreshing crypto data for {}: {}", cryptoId, error.getMessage());
                    Map<String, Object> errorResponse = Map.of(
                        "success", false,
                        "error", error.getMessage(),
                        "timestamp", LocalDateTime.now()
                    );
                    return Mono.just(ResponseEntity.badRequest().body(errorResponse));
                });
    }

    /**
     * Get current rate limiting status for all providers
     */
    @GetMapping("/status/rate-limits")
    public ResponseEntity<Map<String, Object>> getRateLimitStatus() {
        String status = focusedCryptoDetailService.getRateLimitStatus();
        Map<String, Object> response = Map.of(
            "success", true,
            "rateLimitStatus", status,
            "timestamp", LocalDateTime.now()
        );
        return ResponseEntity.ok(response);
    }

    /**
     * Clear cache for a specific cryptocurrency
     */
    @DeleteMapping("/{cryptoId}/cache")
    public ResponseEntity<Map<String, Object>> clearCache(@PathVariable String cryptoId) {
        log.info("Clear cache request for crypto: {}", cryptoId);
        
        focusedCryptoDetailService.clearCache(cryptoId);
        
        Map<String, Object> response = Map.of(
            "success", true,
            "message", "Cache cleared for " + cryptoId,
            "timestamp", LocalDateTime.now()
        );
        return ResponseEntity.ok(response);
    }

    /**
     * Preload popular cryptocurrencies for better performance
     */
    @PostMapping("/preload")
    public ResponseEntity<Map<String, Object>> preloadPopularCryptos() {
        log.info("Preload request for popular cryptocurrencies");
        
        focusedCryptoDetailService.preloadPopularCryptos();
        
        Map<String, Object> response = Map.of(
            "success", true,
            "message", "Preloading popular cryptocurrencies started",
            "timestamp", LocalDateTime.now()
        );
        return ResponseEntity.ok(response);
    }
}
