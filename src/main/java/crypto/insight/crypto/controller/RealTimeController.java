package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.service.RealTimeStreamingService;
import crypto.insight.crypto.service.RealTimeDataService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Map;
import java.util.HashMap;

@Slf4j
@RestController
@RequestMapping("/api/v1/realtime")
@CrossOrigin(originPatterns = "*", allowCredentials = "true")
public class RealTimeController {

    @Autowired
    private RealTimeStreamingService streamingService;

    @Autowired
    private RealTimeDataService realTimeDataService;

    /**
     * Force update real-time data for a specific symbol
     */
    @PostMapping("/update/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> forceUpdate(@PathVariable String symbol) {
        log.info("Force update requested for symbol: {}", symbol);
        
        try {
            streamingService.forceUpdateSymbol(symbol);
            
            Map<String, Object> response = new HashMap<>();
            response.put("symbol", symbol);
            response.put("message", "Real-time update triggered");
            response.put("timestamp", System.currentTimeMillis());
            
            return Mono.just(ResponseEntity.ok(ApiResponse.success(response, "Real-time update triggered")));
            
        } catch (Exception e) {
            log.error("Error forcing update for {}: {}", symbol, e.getMessage());
            return Mono.just(ResponseEntity.ok(ApiResponse.error("Error forcing update: " + e.getMessage())));
        }
    }

    /**
     * Get real-time status for tracked symbols
     */
    @GetMapping("/status")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getStatus() {
        try {
            Map<String, Object> status = new HashMap<>();
            status.put("trackedSymbols", streamingService.getTrackedSymbols());
            status.put("timestamp", System.currentTimeMillis());
            
            Map<String, Object> symbolStatus = new HashMap<>();
            for (String symbol : streamingService.getTrackedSymbols()) {
                Map<String, Object> info = new HashMap<>();
                info.put("lastUpdate", streamingService.getLastUpdateTime(symbol));
                info.put("fresh", streamingService.isDataFresh(symbol));
                symbolStatus.put(symbol, info);
            }
            status.put("symbolStatus", symbolStatus);
            
            return Mono.just(ResponseEntity.ok(ApiResponse.success(status, "Real-time status retrieved")));
            
        } catch (Exception e) {
            log.error("Error getting real-time status: {}", e.getMessage());
            return Mono.just(ResponseEntity.ok(ApiResponse.error("Error getting status: " + e.getMessage())));
        }
    }

    /**
     * Check if data is fresh for a specific symbol
     */
    @GetMapping("/fresh/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> checkFreshness(@PathVariable String symbol) {
        try {
            Map<String, Object> response = new HashMap<>();
            response.put("symbol", symbol);
            response.put("fresh", streamingService.isDataFresh(symbol));
            response.put("lastUpdate", streamingService.getLastUpdateTime(symbol));
            response.put("timestamp", System.currentTimeMillis());
            
            return Mono.just(ResponseEntity.ok(ApiResponse.success(response, "Freshness status retrieved")));
            
        } catch (Exception e) {
            log.error("Error checking freshness for {}: {}", symbol, e.getMessage());
            return Mono.just(ResponseEntity.ok(ApiResponse.error("Error checking freshness: " + e.getMessage())));
        }
    }

    /**
     * Clear cache for a specific symbol to force fresh data
     */
    @DeleteMapping("/cache/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> clearCache(@PathVariable String symbol) {
        log.info("Cache clear requested for symbol: {}", symbol);
        
        try {
            realTimeDataService.clearCachesForSymbol(symbol);
            
            Map<String, Object> response = new HashMap<>();
            response.put("symbol", symbol);
            response.put("message", "Cache cleared successfully");
            response.put("timestamp", System.currentTimeMillis());
            
            return Mono.just(ResponseEntity.ok(ApiResponse.success(response, "Cache cleared successfully")));
            
        } catch (Exception e) {
            log.error("Error clearing cache for {}: {}", symbol, e.getMessage());
            return Mono.just(ResponseEntity.ok(ApiResponse.error("Error clearing cache: " + e.getMessage())));
        }
    }

    /**
     * Health check for real-time service
     */
    @GetMapping("/health")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "healthy");
        health.put("timestamp", System.currentTimeMillis());
        health.put("trackedCount", streamingService.getTrackedSymbols().size());
        
        return Mono.just(ResponseEntity.ok(ApiResponse.success(health, "Real-time service is healthy")));
    }
}
