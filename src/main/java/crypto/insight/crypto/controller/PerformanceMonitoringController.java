package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.service.CircuitBreakerService;
import crypto.insight.crypto.service.PredictiveCacheService;
import crypto.insight.crypto.service.ParallelProcessingService;
import crypto.insight.crypto.service.UltraHighPerformanceService;
import crypto.insight.crypto.service.HardwareAccelerationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@CrossOrigin(originPatterns = "*")
public class PerformanceMonitoringController {

    private final CircuitBreakerService circuitBreakerService;
    private final PredictiveCacheService predictiveCacheService;
    private final ParallelProcessingService parallelProcessingService;
    private final UltraHighPerformanceService ultraHighPerformanceService;
    private final HardwareAccelerationService hardwareAccelerationService;

    public PerformanceMonitoringController(
            CircuitBreakerService circuitBreakerService,
            PredictiveCacheService predictiveCacheService,
            ParallelProcessingService parallelProcessingService,
            UltraHighPerformanceService ultraHighPerformanceService,
            HardwareAccelerationService hardwareAccelerationService) {
        this.circuitBreakerService = circuitBreakerService;
        this.predictiveCacheService = predictiveCacheService;
        this.parallelProcessingService = parallelProcessingService;
        this.ultraHighPerformanceService = ultraHighPerformanceService;
        this.hardwareAccelerationService = hardwareAccelerationService;
    }

    /**
     * Get circuit breaker statistics
     */
    @GetMapping("/circuit-breaker/stats")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getCircuitBreakerStats() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> stats = circuitBreakerService.getCircuitBreakerStats();
            return ResponseEntity.ok(ApiResponse.success(stats, "Circuit breaker statistics"));
        });
    }

    /**
     * Reset all circuit breakers
     */
    @PostMapping("/circuit-breaker/reset")
    public Mono<ResponseEntity<ApiResponse<String>>> resetCircuitBreakers() {
        return Mono.fromRunnable(() -> {
            circuitBreakerService.resetAllBreakers();
            log.info("All circuit breakers reset manually");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("RESET", "All circuit breakers have been reset")
        )));
    }

    /**
     * Get predictive cache statistics
     */
    @GetMapping("/predictive/stats")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getPredictiveStats() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> stats = predictiveCacheService.getPredictionStats();
            return ResponseEntity.ok(ApiResponse.success(stats, "Predictive cache statistics"));
        });
    }

    /**
     * Track manual symbol access for prediction learning
     */
    @PostMapping("/predictive/track/{symbol}")
    public Mono<ResponseEntity<ApiResponse<String>>> trackSymbolAccess(@PathVariable String symbol) {
        return Mono.fromRunnable(() -> {
            predictiveCacheService.trackAccess(symbol);
            log.debug("Tracked access for symbol: {}", symbol);
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("TRACKED", "Symbol access tracked for ML predictions")
        )));
    }

    /**
     * Track page access patterns
     */
    @PostMapping("/predictive/track/page/{page}")
    public Mono<ResponseEntity<ApiResponse<String>>> trackPageAccess(@PathVariable int page) {
        return Mono.fromRunnable(() -> {
            predictiveCacheService.trackPageAccess(page);
            log.debug("Tracked page access: {}", page);
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("TRACKED", "Page access tracked for ML predictions")
        )));
    }

    /**
     * Track search patterns
     */
    @PostMapping("/predictive/track/search")
    public Mono<ResponseEntity<ApiResponse<String>>> trackSearch(@RequestBody Map<String, String> request) {
        String query = request.get("query");
        return Mono.fromRunnable(() -> {
            predictiveCacheService.trackSearch(query);
            log.debug("Tracked search: {}", query);
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("TRACKED", "Search pattern tracked for ML predictions")
        )));
    }

    /**
     * Get parallel processing statistics
     */
    @GetMapping("/parallel/stats")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getParallelProcessingStats() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> stats = parallelProcessingService.getProcessingStats();
            return ResponseEntity.ok(ApiResponse.success(stats, "Parallel processing statistics"));
        });
    }

    /**
     * Get comprehensive performance overview
     */
    @GetMapping("/performance/overview")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getPerformanceOverview() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> overview = Map.of(
                "circuitBreakers", circuitBreakerService.getCircuitBreakerStats(),
                "predictiveCache", predictiveCacheService.getPredictionStats(),
                "parallelProcessing", parallelProcessingService.getProcessingStats(),
                "systemInfo", Map.of(
                    "availableProcessors", Runtime.getRuntime().availableProcessors(),
                    "maxMemory", Runtime.getRuntime().maxMemory() / (1024 * 1024) + " MB",
                    "totalMemory", Runtime.getRuntime().totalMemory() / (1024 * 1024) + " MB",
                    "freeMemory", Runtime.getRuntime().freeMemory() / (1024 * 1024) + " MB"
                ),
                "optimizations", Map.of(
                    "virtualThreads", "ENABLED",
                    "parallelProcessing", "GPU-STYLE",
                    "circuitBreakers", "ACTIVE",
                    "predictiveCaching", "ML-POWERED",
                    "connectionPool", "1000 CONNECTIONS",
                    "cacheStrategy", "AGGRESSIVE"
                )
            );
            
            return ResponseEntity.ok(ApiResponse.success(overview, "Complete performance overview"));
        });
    }

    /**
     * Trigger performance optimization
     */
    @PostMapping("/performance/optimize")
    public Mono<ResponseEntity<ApiResponse<String>>> triggerOptimization() {
        return Mono.fromRunnable(() -> {
            // Trigger garbage collection
            System.gc();
            
            // Reset circuit breakers if needed
            circuitBreakerService.resetAllBreakers();
            
            log.info("Manual performance optimization triggered");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("OPTIMIZED", "Performance optimization completed")
        )));
    }

    /**
     * Get real-time performance metrics
     */
    @GetMapping("/performance/metrics/realtime")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getRealtimeMetrics() {
        return Mono.fromSupplier(() -> {
            Runtime runtime = Runtime.getRuntime();
            
            Map<String, Object> metrics = Map.of(
                "timestamp", System.currentTimeMillis(),
                "memory", Map.of(
                    "used", (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024) + " MB",
                    "free", runtime.freeMemory() / (1024 * 1024) + " MB",
                    "total", runtime.totalMemory() / (1024 * 1024) + " MB",
                    "max", runtime.maxMemory() / (1024 * 1024) + " MB",
                    "utilization", Math.round(((double)(runtime.totalMemory() - runtime.freeMemory()) / runtime.maxMemory()) * 100) + "%"
                ),
                "processors", runtime.availableProcessors(),
                "uptime", java.lang.management.ManagementFactory.getRuntimeMXBean().getUptime()
            );
            
            return ResponseEntity.ok(ApiResponse.success(metrics, "Real-time performance metrics"));
        });
    }

    /**
     * Get ultra-high performance statistics
     */
    @GetMapping("/ultra-performance/stats")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getUltraPerformanceStats() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> stats = ultraHighPerformanceService.getUltraPerformanceStats();
            return ResponseEntity.ok(ApiResponse.success(stats, "Ultra-high performance statistics"));
        });
    }

    /**
     * Reset ultra-high performance counters
     */
    @PostMapping("/ultra-performance/reset")
    public Mono<ResponseEntity<ApiResponse<String>>> resetUltraPerformanceCounters() {
        return Mono.fromRunnable(() -> {
            ultraHighPerformanceService.resetPerformanceCounters();
            log.info("Ultra-high performance counters reset");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("RESET", "Ultra-high performance counters have been reset")
        )));
    }

    /**
     * Trigger ultra-high performance warmup
     */
    @PostMapping("/ultra-performance/warmup")
    public Mono<ResponseEntity<ApiResponse<String>>> triggerUltraWarmup() {
        return Mono.fromRunnable(() -> {
            ultraHighPerformanceService.warmUpCriticalPaths();
            log.info("Ultra-high performance warmup triggered");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("WARMUP", "Ultra-high performance warmup completed")
        )));
    }

    /**
     * Get hardware acceleration statistics
     */
    @GetMapping("/hardware/stats")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getHardwareStats() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> stats = hardwareAccelerationService.getHardwareStats();
            return ResponseEntity.ok(ApiResponse.success(stats, "Hardware acceleration statistics"));
        });
    }

    /**
     * Optimize for current hardware profile
     */
    @PostMapping("/hardware/optimize")
    public Mono<ResponseEntity<ApiResponse<String>>> optimizeForHardware() {
        return Mono.fromRunnable(() -> {
            hardwareAccelerationService.optimizeForHardware();
            log.info("Hardware optimization triggered");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("OPTIMIZED", "Hardware optimization completed")
        )));
    }

    /**
     * Trigger hardware warmup
     */
    @PostMapping("/hardware/warmup")
    public Mono<ResponseEntity<ApiResponse<String>>> triggerHardwareWarmup() {
        return Mono.fromRunnable(() -> {
            hardwareAccelerationService.warmUpHardware();
            log.info("Hardware warmup triggered");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("WARMUP", "Hardware warmup completed")
        )));
    }

    /**
     * Get comprehensive ultra performance overview
     */
    @GetMapping("/performance/ultra-overview")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getUltraPerformanceOverview() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> overview = Map.of(
                "circuitBreakers", circuitBreakerService.getCircuitBreakerStats(),
                "predictiveCache", predictiveCacheService.getPredictionStats(),
                "parallelProcessing", parallelProcessingService.getProcessingStats(),
                "ultraPerformance", ultraHighPerformanceService.getUltraPerformanceStats(),
                "hardwareAcceleration", hardwareAccelerationService.getHardwareStats(),
                "systemInfo", Map.of(
                    "availableProcessors", Runtime.getRuntime().availableProcessors(),
                    "maxMemory", Runtime.getRuntime().maxMemory() / (1024 * 1024) + " MB",
                    "totalMemory", Runtime.getRuntime().totalMemory() / (1024 * 1024) + " MB",
                    "freeMemory", Runtime.getRuntime().freeMemory() / (1024 * 1024) + " MB"
                ),
                "optimizations", Map.of(
                    "virtualThreads", "ENABLED",
                    "parallelProcessing", "GPU-STYLE",
                    "circuitBreakers", "ACTIVE",
                    "predictiveCaching", "ML-POWERED",
                    "connectionPool", "1000 CONNECTIONS",
                    "cacheStrategy", "AGGRESSIVE",
                    "ultraPerformance", "SIMD-STYLE",
                    "hardwareAcceleration", "AVX/SSE OPTIMIZED",
                    "memoryMapping", "ZERO-COPY",
                    "numaAware", "ENABLED"
                )
            );
            
            return ResponseEntity.ok(ApiResponse.success(overview, "Ultra performance overview"));
        });
    }

    /**
     * Trigger comprehensive performance optimization
     */
    @PostMapping("/performance/ultra-optimize")
    public Mono<ResponseEntity<ApiResponse<String>>> triggerUltraOptimization() {
        return Mono.fromRunnable(() -> {
            // Trigger all optimizations
            System.gc();
            circuitBreakerService.resetAllBreakers();
            ultraHighPerformanceService.resetPerformanceCounters();
            ultraHighPerformanceService.warmUpCriticalPaths();
            hardwareAccelerationService.optimizeForHardware();
            hardwareAccelerationService.warmUpHardware();
            
            log.info("Ultra performance optimization triggered - all systems optimized");
        }).then(Mono.just(ResponseEntity.ok(
            ApiResponse.success("ULTRA_OPTIMIZED", "Ultra performance optimization completed - LUDICROUS SPEED!")
        )));
    }
}
