package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.AnalysisType;
import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.AIService;
import crypto.insight.crypto.service.ParallelAIService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;
import org.springframework.http.HttpStatus;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
public class CryptoController {
    
    private final ApiService apiService;
    private final AIService aiService;
    private final ParallelAIService parallelAIService;
    
    public CryptoController(ApiService apiService, AIService aiService, ParallelAIService parallelAIService) {
        this.apiService = apiService;
        this.aiService = aiService;
        this.parallelAIService = parallelAIService;
    }
    


    @GetMapping({
        "/api/v1/crypto/analysis/{symbol}",
        "/api/v3/crypto/analysis/{symbol}",
        "/api/v1/crypto/analysis/{symbol}/{days}",
        "/api/v3/crypto/analysis/{symbol}/{days}",
        "/api/v1/crypto/analysis/{symbol}/",
        "/api/v1/crypto/analyze/{symbol}",
        "/api/v3/crypto/analyze/{symbol}"
    })
    public Mono<ResponseEntity<ApiResponse<AnalysisResponse>>> getAnalysis(
            @PathVariable String symbol,
            @PathVariable(required = false) Integer days,
            @RequestParam(required = false) Integer daysParam,
            @RequestParam(required = false) String types,
            @RequestParam(required = false, defaultValue = "false") boolean refresh) {
        
        log.info("Received analysis request for symbol: {}, days: {}, daysParam: {}, types: {}, refresh: {}", 
                symbol, days, daysParam, types, refresh);
        
        // Parse analysis types
        List<AnalysisType> analysisTypes = AnalysisType.parseTypes(types);
        log.info("Requested analysis types: {}", analysisTypes.stream()
                .map(AnalysisType::getDisplayName)
                .collect(Collectors.toList()));
        
        // Use the most specific parameter (path variable takes precedence over query param)
        int daysToUse = days != null ? days : (daysParam != null ? daysParam : 30);
        
        if (daysToUse < 1 || daysToUse > 365) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Days parameter must be between 1 and 365")));
        }
        
        return apiService.getCryptocurrencyData(symbol, daysToUse, refresh)
                .flatMap(crypto -> {
                    // Get market chart data if available, but don't fail if it's not
                    Mono<List<ChartDataPoint>> marketChartMono = apiService.getMarketChart(symbol, daysToUse, refresh)
                            .onErrorResume(e -> {
                                log.warn("Market chart data not available for {}: {}", symbol, e.getMessage());
                                return Mono.just(Collections.emptyMap());
                            })
                            .defaultIfEmpty(Collections.emptyMap())
                            .map(chartData -> {
                                Object pricesObj = chartData.get("prices");
                                if (pricesObj instanceof List) {
                                    return ((List<?>) pricesObj).stream()
                                            .filter(List.class::isInstance)
                                            .map(point -> (List<?>) point)
                                            .filter(point -> point.size() >= 2)
                                            .map(point -> new ChartDataPoint(
                                                    ((Number) point.get(0)).longValue(),
                                                    ((Number) point.get(1)).doubleValue()
                                            ))
                                            .collect(Collectors.toList());
                                }
                                return Collections.<ChartDataPoint>emptyList();
                            });
                    
                    return marketChartMono.flatMap(chartData -> {
                        // If we have crypto data but no chart data, still proceed with analysis
                        if (chartData.isEmpty()) {
                            log.info("No market chart data available for {}, proceeding with basic analysis", symbol);
                        }
                        
                        // Choose analysis method based on types requested
                        if (analysisTypes.size() == 7) {
                            // All types requested - use full parallel analysis
                            return Mono.fromFuture(parallelAIService.generateParallelAnalysis(
                                    crypto,
                                    chartData,
                                    daysToUse
                            ));
                        } else {
                            // Specific types requested - use selective analysis
                            return Mono.fromFuture(parallelAIService.generateParallelAnalysisByType(
                                    crypto,
                                    chartData,
                                    daysToUse,
                                    analysisTypes
                            ));
                        }
                    });
                })
                .<ResponseEntity<ApiResponse<AnalysisResponse>>>map(analysis -> {
                    AnalysisResponse response = (AnalysisResponse) analysis;
                    
                    // Create success message with info about analysis types
                    String message = analysisTypes.size() == 7 
                        ? "Complete analysis completed successfully" 
                        : "Selected analysis completed successfully: " + 
                          analysisTypes.stream().map(AnalysisType::getDisplayName).collect(Collectors.joining(", "));
                    
                    return ResponseEntity.ok(ApiResponse.success(
                            response,
                            message + 
                                (response.getChartData() == null || response.getChartData().isEmpty() ? " (no market chart data available)" : "")
                    ));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching analysis for symbol {}: {}", symbol, e.getMessage(), e);
                    String errorMessage = e instanceof NoSuchElementException 
                            ? e.getMessage() 
                            : "Error fetching analysis: " + e.getMessage();
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error(errorMessage)));
                });
    }






    
    /**
     * Get detailed information about a cryptocurrency by its symbol.
     *
     * @param symbol The cryptocurrency symbol (e.g., "BTC")
     * @return ResponseEntity containing the cryptocurrency details or an error message
     */
    @GetMapping({"/api/v1/crypto/info/{symbol}", "/api/v3/crypto/info/{symbol}"})
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getCryptoDetailsBySymbol(
            @PathVariable String symbol) {
        final String requestId = UUID.randomUUID().toString();
        final long startTime = System.currentTimeMillis();
        
        // Sanitize input
        String sanitizedSymbol = symbol.trim().toUpperCase();
        log.info("[{}] Received request for crypto details - Symbol: {}", requestId, sanitizedSymbol);

        // First search for the cryptocurrency by symbol to get its ID
        return apiService.searchCryptocurrencies(sanitizedSymbol)
                .filter(crypto -> sanitizedSymbol.equalsIgnoreCase(crypto.getSymbol()))
                .next()
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, 
                        "Cryptocurrency not found with symbol: " + sanitizedSymbol)))
                .flatMap(crypto -> {
                    // Now fetch details using the resolved ID
                    log.debug("[{}] Found crypto ID: {} for symbol: {}", requestId, crypto.getId(), sanitizedSymbol);
                    return apiService.getCryptocurrencyDetails(crypto.getId())
                            .map(details -> {
                                log.info("[{}] Successfully fetched details for {} ({}). Took {}ms", 
                                        requestId, crypto.getName(), crypto.getSymbol(), 
                                        (System.currentTimeMillis() - startTime));
                                // Convert Cryptocurrency to Map<String, Object>
                                Map<String, Object> detailsMap = new HashMap<>();
                                detailsMap.put("id", details.getId());
                                detailsMap.put("name", details.getName());
                                detailsMap.put("symbol", details.getSymbol());
                                if (details.getPrice() != null) detailsMap.put("price", details.getPrice());
                                if (details.getMarketCap() != null) detailsMap.put("marketCap", details.getMarketCap());
                                if (details.getVolume24h() != null) detailsMap.put("volume24h", details.getVolume24h());
                                if (details.getPercentChange24h() != null) detailsMap.put("percentChange24h", details.getPercentChange24h());
                                // Add more fields as needed
                                
                                return ResponseEntity.ok(ApiResponse.success(detailsMap, "Success"));
                            });
                })
                .onErrorResume(ResponseStatusException.class, e -> {
                    log.warn("[{}] Failed to find cryptocurrency with symbol {}: {}", 
                            requestId, sanitizedSymbol, e.getMessage());
                    return Mono.just(ResponseEntity
                            .status(e.getStatusCode())
                            .body(ApiResponse.error(e.getReason())));
                })
                .onErrorResume(e -> {
                    log.error("[{}] Error fetching details for {}: {}", 
                            requestId, sanitizedSymbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity
                            .status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to fetch cryptocurrency details")));
                });
    }

    /**
     * Get available analysis types
     */
    @GetMapping("/api/v1/crypto/analysis-types")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAnalysisTypes() {
        Map<String, Object> response = new HashMap<>();
        
        List<Map<String, String>> types = Arrays.stream(AnalysisType.values())
                .map(type -> {
                    Map<String, String> typeInfo = new HashMap<>();
                    typeInfo.put("code", type.getCode());
                    typeInfo.put("displayName", type.getDisplayName());
                    return typeInfo;
                })
                .collect(Collectors.toList());
        
        response.put("availableTypes", types);
        response.put("usage", "Add '?types=general,technical,sentiment' to specify analysis types");
        response.put("example", "/api/v1/crypto/analysis/BTC?types=general,technical");
        response.put("refresh", "Add '&refresh=true' to force fresh data from APIs (bypasses cache)");
        response.put("exampleWithRefresh", "/api/v1/crypto/analysis/BTC?types=general,technical&refresh=true");
        
        return ResponseEntity.ok(ApiResponse.success(response, "Available analysis types"));
    }
}