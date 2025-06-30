package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.*;
import crypto.insight.crypto.service.ApiService;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@CrossOrigin(originPatterns = "*")
public class CryptoApiController {

    public CryptoApiController(ApiService apiService) {
        this.apiService = apiService;
    }

    private final ApiService apiService;

    @GetMapping("/crypto/search/{query}")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> searchCryptocurrencies(
            @PathVariable String query,
            @RequestParam(defaultValue = "10") int limit) {
        return apiService.searchCryptocurrencies(query)
                .collectList()
                .map(cryptos -> {
                    List<Cryptocurrency> limited = cryptos.stream()
                            .limit(limit)
                            .toList();
                    return ResponseEntity.ok(ApiResponse.success(limited, "Cryptocurrencies found"));
                })
                .onErrorResume(e -> {
                    log.error("Error searching cryptocurrencies: {}", e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error searching cryptocurrencies: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/market-data")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> getMarketData(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int perPage) {
        return apiService.searchCryptocurrencies("")
                .collectList()
                .map(cryptos -> {
                    int start = (page - 1) * perPage;
                    if (start >= cryptos.size()) {
                        return ResponseEntity.ok(ApiResponse.success(List.<Cryptocurrency>of(), "No more data available"));
                    }
                    int end = Math.min(start + perPage, cryptos.size());
                    List<Cryptocurrency> paginatedList = cryptos.subList(start, end);
                    return ResponseEntity.ok(ApiResponse.success(paginatedList, "Market data fetched successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching market data: {}", e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.<List<Cryptocurrency>>error("Error fetching market data: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Cryptocurrency>>> getCryptocurrency(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "30") int days) {
        return apiService.getCryptocurrencyData(symbol, days)
                .map(crypto -> ResponseEntity.ok(ApiResponse.success(crypto, "Cryptocurrency data fetched successfully")))
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()))
                .onErrorResume(e -> {
                    log.error("Error fetching cryptocurrency data for {}: {}", symbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error fetching cryptocurrency data: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/{symbol}/market-chart")
    public Mono<ResponseEntity<ApiResponse<List<List<Number>>>>> getMarketChart(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "30") int days) {
        return apiService.getMarketChart(symbol, days)
                .map(chartData -> {
                    Object pricesObj = chartData.get("prices");
                    @SuppressWarnings("unchecked")
                    List<List<Number>> prices = pricesObj instanceof List ? (List<List<Number>>) pricesObj : List.of();
                    return ResponseEntity.ok(ApiResponse.success(prices, "Market chart data fetched successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching market chart for {}: {}", symbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error fetching market chart: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/{symbol}/details")
    public Mono<ResponseEntity<ApiResponse<CryptoDetails>>> getCryptoDetails(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "30") int days) {
        return apiService.getCryptocurrencyData(symbol, days)
                .<ResponseEntity<ApiResponse<CryptoDetails>>>flatMap(crypto -> 
                    apiService.getCryptocurrencyDetails(crypto.getId())
                        .<ResponseEntity<ApiResponse<CryptoDetails>>>map(details -> 
                            ResponseEntity.ok(ApiResponse.success(
                                new CryptoDetails(details), 
                                "Cryptocurrency details fetched successfully"))
                        )
                )
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()))
                .onErrorResume(e -> {
                    log.error("Error fetching cryptocurrency details for {}: {}", symbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error fetching cryptocurrency details: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/details/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Cryptocurrency>>> getCryptocurrencyDetails(
            @PathVariable String symbol) {
        return apiService.getCryptocurrencyDetails(symbol)
                .map(crypto -> ResponseEntity.ok(ApiResponse.success(crypto, "Cryptocurrency details fetched successfully")))
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()))
                .onErrorResume(e -> {
                    log.error("Error fetching cryptocurrency details for {}: {}", symbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error fetching cryptocurrency details: " + e.getMessage())));
                });
    }

    @GetMapping("/crypto/price-chart/{symbol}")
    public Mono<ResponseEntity<ApiResponse<List<List<Number>>>>> getPriceChart(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "30") int days) {
        return apiService.getMarketChart(symbol, days)
                .map(chartData -> {
                    Object pricesObj = chartData.get("prices");
                    @SuppressWarnings("unchecked")
                    List<List<Number>> prices = pricesObj instanceof List ? (List<List<Number>>) pricesObj : List.of();
                    return ResponseEntity.ok(ApiResponse.success(prices, "Price chart data fetched successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Error fetching price chart for {}: {}", symbol, e.getMessage(), e);
                    return Mono.just(ResponseEntity.badRequest()
                            .body(ApiResponse.error("Error fetching price chart: " + e.getMessage())));
                });
    }

}
