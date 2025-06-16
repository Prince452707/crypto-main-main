package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.AIService;
import crypto.insight.crypto.util.ValidationUtil;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;
import org.springframework.http.HttpStatus;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.TimeoutException;
import java.util.stream.Collectors;

@Slf4j
@RestController
public class CryptoController {
    
    public CryptoController(ApiService apiService, AIService aiService) {
        this.apiService = apiService;
        this.aiService = aiService;
    }
    
    private static final String DEFAULT_ERROR_MSG = "An error occurred while processing your request";
    
    private static final Logger logger = LoggerFactory.getLogger(CryptoController.class);
    private final ApiService apiService;
    private final AIService aiService;
    
    /**
     * Enriches cryptocurrency data with additional information
     * @param cryptos List of Cryptocurrency objects to enrich
     * @return Mono containing a list of maps with enriched data
     */
    private Mono<List<Map<String, Object>>> enrichCryptocurrencyData(List<Cryptocurrency> cryptos) {
        return Flux.fromIterable(cryptos)
            .map(crypto -> {
                Map<String, Object> enriched = new HashMap<>();
                enriched.put("id", crypto.getId());
                enriched.put("name", crypto.getName());
                enriched.put("symbol", crypto.getSymbol());
                if (crypto.getPrice() != null) enriched.put("price", crypto.getPrice());
                if (crypto.getMarketCap() != null) enriched.put("marketCap", crypto.getMarketCap());
                if (crypto.getVolume24h() != null) enriched.put("volume24h", crypto.getVolume24h());
                if (crypto.getPercentChange24h() != null) enriched.put("percentChange24h", crypto.getPercentChange24h());
                return enriched;
            })
            .collectList();
    }
    
    @GetMapping({"/api/v1/crypto/search/{query}", "/api/v3/crypto/search/{query}"})
    public Mono<ResponseEntity<ApiResponse<List<Map<String, Object>>>>> searchCrypto(
            @PathVariable String query,
            @RequestParam(defaultValue = "10") int limit) {
        
        if (query == null || query.trim().isEmpty()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Search query cannot be empty")));
        }
        
        // Validate limit parameter
        if (limit < 1 || limit > 50) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Limit must be between 1 and 50")));
        }
        
        final long startTime = System.currentTimeMillis();
        final String requestId = "req_" + System.currentTimeMillis();
        
        logger.info("[{}] Received search request for query: {}, limit: {}", requestId, query, limit);
        
        // Sanitize and validate query
        String sanitizedQuery = ValidationUtil.sanitizeInput(query);
        if (!ValidationUtil.isValidQuery(sanitizedQuery)) {
            logger.warn("[{}] Invalid query parameter: {}", requestId, query);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Invalid search query")));
        }
        
        logger.debug("[{}] Sanitized query: {}", requestId, sanitizedQuery);
        
        return apiService.searchCryptocurrencies(sanitizedQuery)
            .collectList()
            .flatMap(cryptos -> {
                // Limit the number of results before processing
                List<Cryptocurrency> limitedCryptos = cryptos.size() > limit 
                    ? cryptos.subList(0, limit) 
                    : cryptos;
                
                if (limitedCryptos.isEmpty()) {
                    logger.info("[{}] No cryptocurrencies found for query: {}", requestId, sanitizedQuery);
                    return Mono.just(ResponseEntity.ok(
                        ApiResponse.<List<Map<String, Object>>>success(Collections.emptyList(), "No cryptocurrencies found")));
                }
                
                logger.debug("[{}] Processing {} cryptocurrencies for query: {}", 
                    requestId, limitedCryptos.size(), sanitizedQuery);
                
                // Process and enrich the limited results
                return enrichCryptocurrencyData(limitedCryptos)
                    .map(enrichedData -> {
                        logger.info("[{}] Successfully processed {} results in {}ms", 
                            requestId, enrichedData.size(), System.currentTimeMillis() - startTime);
                        return ResponseEntity.ok(ApiResponse.success(enrichedData, "Cryptocurrencies found"));
                    });
            })
            .onErrorResume(IllegalArgumentException.class, e -> {
                logger.warn("[{}] Invalid query parameter: {}", requestId, e.getMessage());
                ApiResponse<List<Map<String, Object>>> response = ApiResponse.error("Invalid search query: " + e.getMessage());
                return Mono.just(ResponseEntity.badRequest().body(response));
            })
            .onErrorResume(TimeoutException.class, e -> {
                logger.error("[{}] Request timed out: {}", requestId, e.getMessage());
                ApiResponse<List<Map<String, Object>>> response = ApiResponse.error("Request timed out. Please try again.");
                return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response));
            })
            .onErrorResume(e -> {
                logger.error("[{}] Error processing search request: {}", requestId, e.getMessage(), e);
                ApiResponse<List<Map<String, Object>>> response = ApiResponse.error("An error occurred while processing your request");
                return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response));
            });
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
     * Get paginated market data for all cryptocurrencies.
     *
     * @param page The page number (1-based)
     * @param perPage Number of items per page (1-250)
     * @return Paginated list of cryptocurrencies with market data
     */
    @GetMapping({"/api/v1/crypto/market-data", "/api/v3/crypto/market-data"})
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>> >> getMarketData(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int perPage) {
        
        final String requestId = "req_" + System.currentTimeMillis();
        log.info("[{}] Fetching market data - page: {}, perPage: {}", requestId, page, perPage);
        
        // Input validation
        if (page < 1) {
            log.warn("[{}] Invalid page number: {}", requestId, page);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Page number must be greater than 0")));
        }
        
        if (perPage < 1 || perPage > 250) {
            log.warn("[{}] Invalid items per page: {}", requestId, perPage);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Items per page must be between 1 and 250")));
        }
        
        // Fetch all cryptocurrencies (empty query returns popular ones)
        return apiService.searchCryptocurrencies("")
            .collectList()
            .flatMap(cryptoList -> {
                if (cryptoList == null || cryptoList.isEmpty()) {
                    log.warn("[{}] No cryptocurrency data available", requestId);
                    return Mono.just(ResponseEntity.ok(
                            ApiResponse.success(Collections.<Cryptocurrency>emptyList(), 
                                    "No cryptocurrency data available")));
                }
                
                log.debug("[{}] Fetched {} cryptocurrencies", requestId, cryptoList.size());
                
                // Implement pagination
                int totalItems = cryptoList.size();
                int totalPages = (int) Math.ceil((double) totalItems / perPage);
                int start = (page - 1) * perPage;
                
                if (start >= totalItems) {
                    log.info("[{}] Requested page {} is out of bounds (total items: {})", 
                            requestId, page, totalItems);
                    return Mono.just(ResponseEntity.ok(
                            ApiResponse.success(Collections.<Cryptocurrency>emptyList(), 
                                    "No data found for the requested page")));
                }
                
                int end = Math.min(start + perPage, totalItems);
                List<Cryptocurrency> paginatedList = cryptoList.subList(start, end);
                
                log.debug("[{}] Returning items {} to {} of {}", 
                        requestId, start + 1, end, totalItems);
                
                // Return the response with pagination metadata
                return Mono.just(ResponseEntity.ok(
                        ApiResponse.success(paginatedList, "Market data fetched successfully")
                                .withMetadata("page", page)
                                .withMetadata("perPage", perPage)
                                .withMetadata("totalItems", totalItems)
                                .withMetadata("totalPages", totalPages)
                                .withMetadata("hasNext", page < totalPages)
                                .withMetadata("hasPrevious", page > 1)));
            })
            .timeout(Duration.ofSeconds(30))
            .onErrorResume(TimeoutException.class, e -> {
                log.error("[{}] Timeout while fetching market data: {}", requestId, e.getMessage());
                return Mono.just(ResponseEntity.status(HttpStatus.REQUEST_TIMEOUT)
                        .body(ApiResponse.error("Request timed out. Please try again.")));
            })
            .onErrorResume(e -> {
                log.error("[{}] Error fetching market data: {}", requestId, e.getMessage(), e);
                return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(ApiResponse.error("Error fetching market data: " + e.getMessage())));
            });
    }

    @GetMapping({"/api/v1/crypto/details/{id}", "/api/v3/crypto/details/{id}"})
    public Mono<ResponseEntity<ApiResponse<Cryptocurrency>>> getCryptoDetails(@PathVariable String id) {
        final String requestId = "req_" + System.currentTimeMillis();
        log.info("[{}] Fetching details for crypto ID: {}", requestId, id);
        
        if (id == null || id.trim().isEmpty()) {
            log.warn("[{}] Empty ID provided", requestId);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("ID cannot be empty")));
        }
        
        return apiService.getCryptocurrencyDetails(id)
                .timeout(Duration.ofSeconds(30))
                .map(details -> {
                    if (details == null) {
                        throw new NoSuchElementException("No details found for id: " + id);
                    }
                    log.debug("[{}] Successfully fetched details for ID: {}", requestId, id);
                    return ResponseEntity.ok(ApiResponse.success(
                            details,
                            "Crypto details fetched successfully"
                    ));
                })
                .onErrorResume(NoSuchElementException.class, e -> {
                    log.warn("[{}] Crypto details not found for id {}: {}", requestId, id, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(ApiResponse.error(e.getMessage())));
                })
                .onErrorResume(TimeoutException.class, e -> {
                    log.error("[{}] Timeout while fetching details for id {}: {}", requestId, id, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.REQUEST_TIMEOUT)
                            .body(ApiResponse.error("Request timed out. Please try again.")));
                })
                .onErrorResume(e -> {
                    log.error("[{}] Error fetching crypto details for id {}: {}", requestId, id, e.getMessage(), e);
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Error fetching crypto details: " + e.getMessage())));
                });
    }

    /**
     * Get price chart data for a specific cryptocurrency symbol.
     *
     * @param symbol The cryptocurrency symbol (e.g., "BTC")
     * @param days Number of days of historical data to return (1-365)
     * @return A list of chart data points with timestamps and prices
     */
    @GetMapping({"/api/v1/crypto/price-chart/{symbol}", "/api/v3/crypto/price-chart/{symbol}"})
    public Mono<ResponseEntity<ApiResponse<List<ChartDataPoint>> >> getPriceChart(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "30") int days) {
        
        final String requestId = "req_" + System.currentTimeMillis();
        log.info("[{}] Fetching price chart for symbol: {}, days: {}", requestId, symbol, days);
        
        // Input validation
        if (symbol == null || symbol.trim().isEmpty()) {
            log.warn("[{}] Empty symbol provided", requestId);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Symbol cannot be empty")));
        }
        
        if (days < 1 || days > 365) {
            log.warn("[{}] Invalid days parameter: {}", requestId, days);
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Days parameter must be between 1 and 365")));
        }
        
        // Get the market chart data from the service
        return apiService.getMarketChart(symbol, days)
                .flatMap(data -> {
                    if (data == null || data.isEmpty()) {
                        log.warn("[{}] No chart data found for symbol: {}", requestId, symbol);
                        return Mono.error(new NoSuchElementException("No chart data found for symbol: " + symbol));
                    }
                    
                    // Extract price data with proper type checking
                    Object pricesObj = data.get("prices");
                    if (!(pricesObj instanceof List)) {
                        log.warn("[{}] Invalid price data format for symbol: {}", requestId, symbol);
                        return Mono.error(new IllegalStateException("Invalid price data format"));
                    }
                    
                    List<?> priceList = (List<?>) pricesObj;
                    List<ChartDataPoint> chartData = new ArrayList<>();
                    
                    // Process each price point
                    for (Object pricePoint : priceList) {
                        if (pricePoint instanceof List) {
                            List<?> point = (List<?>) pricePoint;
                            if (point.size() >= 2 && point.get(0) instanceof Number && point.get(1) instanceof Number) {
                                try {
                                    long timestamp = ((Number) point.get(0)).longValue();
                                    double price = ((Number) point.get(1)).doubleValue();
                                    chartData.add(new ChartDataPoint(timestamp, price));
                                } catch (Exception e) {
                                    log.warn("[{}] Error processing price point: {}", requestId, e.getMessage());
                                    // Skip invalid data points
                                }
                            }
                        }
                    }
                    
                    if (chartData.isEmpty()) {
                        log.warn("[{}] No valid price data points found for symbol: {}", requestId, symbol);
                        return Mono.error(new NoSuchElementException("No valid price data found in chart data for symbol: " + symbol));
                    }
                    
                    log.debug("[{}] Successfully processed {} price points for symbol: {}", 
                            requestId, chartData.size(), symbol);
                    
                    return Mono.just(ResponseEntity.ok(ApiResponse.success(
                            chartData,
                            "Chart data fetched successfully"
                    )));
                })
                .timeout(Duration.ofSeconds(30))
                .onErrorResume(NoSuchElementException.class, e -> {
                    log.warn("[{}] Chart data not found: {}", requestId, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(ApiResponse.error(e.getMessage())));
                })
                .onErrorResume(TimeoutException.class, e -> {
                    log.error("[{}] Timeout while fetching chart data: {}", requestId, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.REQUEST_TIMEOUT)
                            .body(ApiResponse.error("Request timed out. Please try again.")));
                })
                .onErrorResume(IllegalArgumentException.class, e -> {
                    log.error("[{}] Invalid argument: {}", requestId, e.getMessage());
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Invalid request: " + e.getMessage())));
                })
                .onErrorResume(e -> {
                    log.error("[{}] Error fetching chart data: {}", requestId, e.getMessage(), e);
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Error fetching chart data")));
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