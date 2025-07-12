package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.AnalysisType;
import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.AIService;
import crypto.insight.crypto.service.ParallelAIService;
import crypto.insight.crypto.service.RealTimeDataService;
import crypto.insight.crypto.service.FallbackDataService;
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
    private final RealTimeDataService realTimeDataService;
    private final FallbackDataService fallbackDataService;
    
    public CryptoController(ApiService apiService, AIService aiService, ParallelAIService parallelAIService, 
                          RealTimeDataService realTimeDataService, FallbackDataService fallbackDataService) {
        this.apiService = apiService;
        this.aiService = aiService;
        this.parallelAIService = parallelAIService;
        this.realTimeDataService = realTimeDataService;
        this.fallbackDataService = fallbackDataService;
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

        // First try to search for the cryptocurrency by symbol to get its ID
        return apiService.searchCryptocurrencies(sanitizedSymbol)
                .filter(crypto -> sanitizedSymbol.equalsIgnoreCase(crypto.getSymbol()))
                .next()
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
                .switchIfEmpty(
                    // If API search fails, try fallback data
                    fallbackDataService.getFallbackCryptocurrency(sanitizedSymbol)
                            .map(fallbackCrypto -> {
                                log.info("[{}] Using fallback data for {} due to API issues", requestId, sanitizedSymbol);
                                Map<String, Object> detailsMap = new HashMap<>();
                                detailsMap.put("id", fallbackCrypto.getId());
                                detailsMap.put("name", fallbackCrypto.getName());
                                detailsMap.put("symbol", fallbackCrypto.getSymbol());
                                detailsMap.put("price", fallbackCrypto.getPrice());
                                detailsMap.put("fallbackMode", true);
                                detailsMap.put("message", "Data temporarily limited due to API rate limits");
                                
                                return ResponseEntity.ok(ApiResponse.success(detailsMap, 
                                    "Fallback data provided - limited functionality due to API rate limits"));
                            })
                )
                .onErrorResume(e -> {
                    log.warn("[{}] API error for {}, trying fallback: {}", requestId, sanitizedSymbol, e.getMessage());
                    // If everything fails, try fallback one more time
                    return fallbackDataService.getFallbackCryptocurrency(sanitizedSymbol)
                            .map(fallbackCrypto -> {
                                log.info("[{}] Using fallback data for {} after API error", requestId, sanitizedSymbol);
                                Map<String, Object> detailsMap = new HashMap<>();
                                detailsMap.put("id", fallbackCrypto.getId());
                                detailsMap.put("name", fallbackCrypto.getName());
                                detailsMap.put("symbol", fallbackCrypto.getSymbol());
                                detailsMap.put("price", fallbackCrypto.getPrice());
                                detailsMap.put("fallbackMode", true);
                                detailsMap.put("message", "APIs temporarily unavailable - using fallback data");
                                
                                return ResponseEntity.ok(ApiResponse.success(detailsMap, 
                                    "Fallback data provided - APIs are temporarily rate limited"));
                            })
                            .onErrorReturn(ResponseEntity
                                    .status(HttpStatus.NOT_FOUND)
                                    .body(ApiResponse.error("Cryptocurrency not found: " + sanitizedSymbol)));
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

    /**
     * Get fresh cryptocurrency data with forced refresh
     */
    @GetMapping({
        "/api/v1/crypto/fresh/{symbol}",
        "/api/v3/crypto/fresh/{symbol}",
        "/api/v1/crypto/fresh/{symbol}/{days}",
        "/api/v3/crypto/fresh/{symbol}/{days}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getFreshCryptoData(
            @PathVariable String symbol,
            @PathVariable(required = false) Integer days,
            @RequestParam(required = false) Integer daysParam) {
        
        int daysToUse = days != null ? days : (daysParam != null ? daysParam : 30);
        log.info("Fetching FRESH data for symbol: {}, days: {}", symbol, daysToUse);
        
        return realTimeDataService.getFreshCryptocurrencyData(symbol, daysToUse)
                .map(crypto -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("cryptocurrency", crypto);
                    response.put("lastUpdated", java.time.LocalDateTime.now());
                    response.put("dataSource", "Fresh from APIs");
                    response.put("requestedDays", daysToUse);
                    
                    return ResponseEntity.ok(ApiResponse.success(
                            response, 
                            "Fresh cryptocurrency data fetched successfully"
                    ));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching fresh crypto data for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Failed to fetch fresh data: " + e.getMessage())));
                });
    }

    /**
     * Get fresh market chart data with forced refresh
     */
    @GetMapping({
        "/api/v1/crypto/fresh-chart/{symbol}",
        "/api/v3/crypto/fresh-chart/{symbol}",
        "/api/v1/crypto/fresh-chart/{symbol}/{days}",
        "/api/v3/crypto/fresh-chart/{symbol}/{days}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getFreshChartData(
            @PathVariable String symbol,
            @PathVariable(required = false) Integer days,
            @RequestParam(required = false) Integer daysParam) {
        
        int daysToUse = days != null ? days : (daysParam != null ? daysParam : 30);
        log.info("Fetching FRESH chart data for symbol: {}, days: {}", symbol, daysToUse);
        
        return realTimeDataService.getFreshMarketChart(symbol, daysToUse)
                .map(chartData -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("chartData", chartData);
                    response.put("symbol", symbol);
                    response.put("days", daysToUse);
                    response.put("lastUpdated", java.time.LocalDateTime.now());
                    response.put("dataSource", "Fresh from APIs");
                    
                    // Convert to ChartDataPoint format if prices exist
                    if (chartData.containsKey("prices")) {
                        Object pricesObj = chartData.get("prices");
                        if (pricesObj instanceof List) {
                            List<ChartDataPoint> chartPoints = ((List<?>) pricesObj).stream()
                                    .filter(List.class::isInstance)
                                    .map(point -> (List<?>) point)
                                    .filter(point -> point.size() >= 2)
                                    .map(point -> new ChartDataPoint(
                                            ((Number) point.get(0)).longValue(),
                                            ((Number) point.get(1)).doubleValue(),
                                            "CoinGecko"
                                    ))
                                    .collect(Collectors.toList());
                            response.put("formattedChartData", chartPoints);
                        }
                    }
                    
                    return ResponseEntity.ok(ApiResponse.success(
                            response, 
                            "Fresh chart data fetched successfully"
                    ));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching fresh chart data for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Failed to fetch fresh chart data: " + e.getMessage())));
                });
    }

    /**
     * Clear caches for a specific cryptocurrency
     */
    @PostMapping({
        "/api/v1/crypto/clear-cache/{symbol}",
        "/api/v3/crypto/clear-cache/{symbol}"
    })
    public ResponseEntity<ApiResponse<String>> clearCacheForSymbol(@PathVariable String symbol) {
        log.info("Clearing caches for symbol: {}", symbol);
        
        try {
            realTimeDataService.clearCachesForSymbol(symbol);
            return ResponseEntity.ok(ApiResponse.success(
                    "Success", 
                    "Caches cleared for " + symbol + ". Next request will fetch fresh data."
            ));
        } catch (Exception e) {
            log.error("Error clearing caches for {}: {}", symbol, e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to clear caches: " + e.getMessage()));
        }
    }

    /**
     * Clear all caches (use carefully)
     */
    @PostMapping({
        "/api/v1/crypto/clear-all-caches",
        "/api/v3/crypto/clear-all-caches"
    })
    public ResponseEntity<ApiResponse<String>> clearAllCaches() {
        log.info("Clearing ALL caches");
        
        try {
            realTimeDataService.clearAllCaches();
            return ResponseEntity.ok(ApiResponse.success(
                    "Success", 
                    "All caches cleared. Next requests will fetch fresh data."
            ));
        } catch (Exception e) {
            log.error("Error clearing all caches: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to clear all caches: " + e.getMessage()));
        }
    }

    /**
     * Get data freshness status for a symbol
     */
    @GetMapping({
        "/api/v1/crypto/status/{symbol}",
        "/api/v3/crypto/status/{symbol}"
    })
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDataStatus(@PathVariable String symbol) {
        Map<String, Object> status = new HashMap<>();
        
        boolean isStale = realTimeDataService.isDataStale(symbol, 5); // 5 minutes threshold
        
        status.put("symbol", symbol);
        status.put("isStale", isStale);
        status.put("recommendation", isStale ? "Consider refreshing data" : "Data is fresh");
        status.put("checkedAt", java.time.LocalDateTime.now());
        status.put("stalenessThreshold", "5 minutes");
        
        return ResponseEntity.ok(ApiResponse.success(
                status, 
                "Data freshness status for " + symbol
        ));
    }
    
    /**
     * AI-powered Q&A endpoint for specific cryptocurrency
     */
    @PostMapping({
        "/api/v1/crypto/question/{symbol}",
        "/api/v3/crypto/question/{symbol}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> answerCryptoQuestion(
            @PathVariable String symbol,
            @RequestBody Map<String, String> request) {
        
        log.info("Received Q&A request for symbol: {}", symbol);
        
        String question = request.get("question");
        if (question == null || question.trim().isEmpty()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Question is required")));
        }
        
        return apiService.getCryptocurrencyData(symbol, 30, false)
                .flatMap(crypto -> {
                    // Get chart data
                    Mono<List<ChartDataPoint>> chartDataMono = apiService.getMarketChart(symbol, 30, false)
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
                            })
                            .onErrorResume(e -> {
                                log.warn("Chart data not available for {}: {}", symbol, e.getMessage());
                                return Mono.just(Collections.emptyList());
                            });
                    
                    return chartDataMono.flatMap(chartData -> {
                        return Mono.fromFuture(aiService.answerCryptoQuestion(symbol, question, crypto, chartData))
                                .map(answer -> {
                                    Map<String, Object> response = new HashMap<>();
                                    response.put("symbol", symbol);
                                    response.put("question", question);
                                    response.put("answer", answer);
                                    response.put("timestamp", System.currentTimeMillis());
                                    
                                    return ResponseEntity.ok(ApiResponse.success(response, "Question answered successfully"));
                                });
                    });
                })
                .onErrorResume(e -> {
                    log.error("Error answering question for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to answer question: " + e.getMessage())));
                });
    }
    
    /**
     * AI-powered general cryptocurrency Q&A endpoint
     */
    @PostMapping({
        "/api/v1/crypto/question",
        "/api/v3/crypto/question"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> answerGeneralCryptoQuestion(
            @RequestBody Map<String, String> request) {
        
        log.info("Received general crypto Q&A request");
        
        String question = request.get("question");
        if (question == null || question.trim().isEmpty()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Question is required")));
        }
        
        return Mono.fromFuture(aiService.answerGeneralCryptoQuestion(question))
                .map(answer -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("question", question);
                    response.put("answer", answer);
                    response.put("timestamp", System.currentTimeMillis());
                    
                    return ResponseEntity.ok(ApiResponse.success(response, "General question answered successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error answering general question: {}", e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to answer question: " + e.getMessage())));
                });
    }
    
    /**
     * AI-powered similar cryptocurrency finder endpoint
     */
    @GetMapping({
        "/api/v1/crypto/similar/{symbol}",
        "/api/v3/crypto/similar/{symbol}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> findSimilarCryptocurrencies(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "5") int limit,
            @RequestParam(defaultValue = "false") boolean includeAnalysis) {
        
        log.info("Finding similar cryptocurrencies for: {}, limit: {}, includeAnalysis: {}", symbol, limit, includeAnalysis);
        
        if (limit < 1 || limit > 20) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Limit must be between 1 and 20")));
        }
        
        return Mono.fromFuture(aiService.findSimilarCryptocurrencies(symbol, limit, includeAnalysis))
                .map(result -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("symbol", symbol);
                    response.put("similar_cryptocurrencies", result.get("similar_cryptocurrencies"));
                    response.put("comparison_analysis", result.get("comparison_analysis"));
                    response.put("similarity_criteria", result.get("similarity_criteria"));
                    response.put("timestamp", System.currentTimeMillis());
                    
                    return ResponseEntity.ok(ApiResponse.success(response, "Similar cryptocurrencies found successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error finding similar cryptocurrencies for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to find similar cryptocurrencies: " + e.getMessage())));
                });
    }
    
    /**
     * Bookmark management endpoints
     */
    @PostMapping({
        "/api/v1/crypto/bookmark/{symbol}",
        "/api/v3/crypto/bookmark/{symbol}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> addBookmark(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "default") String userId) {
        
        log.info("Adding bookmark for symbol: {}, userId: {}", symbol, userId);
        
        return apiService.getCryptocurrencyData(symbol, 7, false)
                .map(crypto -> {
                    // In a real app, this would persist to a database
                    Map<String, Object> response = new HashMap<>();
                    response.put("symbol", symbol);
                    response.put("name", crypto.getName());
                    response.put("added", true);
                    response.put("timestamp", System.currentTimeMillis());
                    
                    return ResponseEntity.ok(ApiResponse.success(response, "Bookmark added successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error adding bookmark for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to add bookmark: " + e.getMessage())));
                });
    }
    
    @DeleteMapping({
        "/api/v1/crypto/bookmark/{symbol}",
        "/api/v3/crypto/bookmark/{symbol}"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> removeBookmark(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "default") String userId) {
        
        log.info("Removing bookmark for symbol: {}, userId: {}", symbol, userId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("symbol", symbol);
        response.put("removed", true);
        response.put("timestamp", System.currentTimeMillis());
        
        return Mono.just(ResponseEntity.ok(ApiResponse.success(response, "Bookmark removed successfully")));
    }
    
    @GetMapping({
        "/api/v1/crypto/bookmarks",
        "/api/v3/crypto/bookmarks"
    })
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getBookmarks(
            @RequestParam(defaultValue = "default") String userId) {
        
        log.info("Getting bookmarks for userId: {}", userId);
        
        // In a real app, this would fetch from a database
        // For now, return sample bookmarks
        List<String> defaultBookmarks = Arrays.asList("BTC", "ETH", "BNB", "ADA", "SOL");
        
        return apiService.searchCryptocurrencies("")
                .filter(crypto -> defaultBookmarks.contains(crypto.getSymbol().toUpperCase()))
                .collectList()
                .map(bookmarkedCryptos -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("bookmarks", bookmarkedCryptos);
                    response.put("count", bookmarkedCryptos.size());
                    response.put("timestamp", System.currentTimeMillis());
                    
                    return ResponseEntity.ok(ApiResponse.success(response, "Bookmarks retrieved successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error getting bookmarks: {}", e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Failed to get bookmarks: " + e.getMessage())));
                });
    }
}