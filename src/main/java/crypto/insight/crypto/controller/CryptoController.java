package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.AIService;
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
    
    public CryptoController(ApiService apiService, AIService aiService) {
        this.apiService = apiService;
        this.aiService = aiService;
    }
    
    private final ApiService apiService;
    private final AIService aiService;
    


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
            @RequestParam(required = false) Integer daysParam) {
        
        log.info("Received analysis request for symbol: {}, days: {}, daysParam: {}", symbol, days, daysParam);
        
        // Use the most specific parameter (path variable takes precedence over query param)
        int daysToUse = days != null ? days : (daysParam != null ? daysParam : 30);
        
        if (daysToUse < 1 || daysToUse > 365) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Days parameter must be between 1 and 365")));
        }
        
        return apiService.getCryptocurrencyData(symbol, daysToUse)
                .flatMap(crypto -> {
                    // Get market chart data if available, but don't fail if it's not
                    Mono<List<ChartDataPoint>> marketChartMono = apiService.getMarketChart(symbol, daysToUse)
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
                        
                        return Mono.fromFuture(aiService.generateComprehensiveAnalysis(
                                crypto,
                                chartData,
                                daysToUse
                        ));
                    });
                })
                .<ResponseEntity<ApiResponse<AnalysisResponse>>>map(analysis -> {
                    AnalysisResponse response = (AnalysisResponse) analysis;
                    return ResponseEntity.ok(ApiResponse.success(
                            response,
                            "Analysis completed successfully" + 
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
    @GetMapping({"/api/v1/crypto/{symbol}", "/api/v3/crypto/{symbol}"})
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
}