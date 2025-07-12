package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.service.UltraFastApiService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/ultra-fast")
@CrossOrigin(originPatterns = "*")
public class UltraFastController {

    private final UltraFastApiService ultraFastApiService;

    public UltraFastController(UltraFastApiService ultraFastApiService) {
        this.ultraFastApiService = ultraFastApiService;
    }

    /**
     * Ultra-fast market data endpoint with aggressive caching
     */
    @GetMapping("/crypto/market-data")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> getMarketDataUltraFast(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int perPage) {
        
        log.debug("Ultra-fast market data request: page={}, perPage={}", page, perPage);
        
        return ultraFastApiService.getMarketDataUltraFast(page, perPage)
                .map(cryptos -> ResponseEntity.ok(
                    ApiResponse.success(cryptos, "Market data fetched ultra-fast")
                ))
                .onErrorReturn(ResponseEntity.badRequest().body(
                    ApiResponse.error("Failed to fetch market data")
                ));
    }

    /**
     * Ultra-fast cryptocurrency search
     */
    @GetMapping("/crypto/search/{query}")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> searchCryptocurrenciesUltraFast(
            @PathVariable String query,
            @RequestParam(defaultValue = "10") int limit) {
        
        log.debug("Ultra-fast search request: query={}, limit={}", query, limit);
        
        return ultraFastApiService.searchCryptocurrenciesUltraFast(query, limit)
                .map(results -> ResponseEntity.ok(
                    ApiResponse.success(results, "Search completed ultra-fast")
                ))
                .onErrorReturn(ResponseEntity.badRequest().body(
                    ApiResponse.error("Search failed")
                ));
    }

    /**
     * Ultra-fast cryptocurrency details
     */
    @GetMapping("/crypto/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Cryptocurrency>>> getCryptocurrencyDetailsUltraFast(
            @PathVariable String symbol) {
        
        log.debug("Ultra-fast details request: symbol={}", symbol);
        
        return ultraFastApiService.getCryptocurrencyDetailsUltraFast(symbol)
                .map(crypto -> ResponseEntity.ok(
                    ApiResponse.success(crypto, "Details fetched ultra-fast")
                ))
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()));
    }

    /**
     * Ultra-fast batch load for multiple cryptocurrencies
     */
    @PostMapping("/crypto/batch")
    public Mono<ResponseEntity<ApiResponse<List<Cryptocurrency>>>> batchLoadUltraFast(
            @RequestBody List<String> symbols) {
        
        log.debug("Ultra-fast batch load request: {} symbols", symbols.size());
        
        return ultraFastApiService.batchLoadUltraFast(symbols)
                .map(cryptos -> ResponseEntity.ok(
                    ApiResponse.success(cryptos, "Batch load completed ultra-fast")
                ))
                .onErrorReturn(ResponseEntity.badRequest().body(
                    ApiResponse.error("Batch load failed")
                ));
    }

    /**
     * Health check for ultra-fast service
     */
    @GetMapping("/health")
    public Mono<ResponseEntity<ApiResponse<String>>> healthCheck() {
        return Mono.just(ResponseEntity.ok(
            ApiResponse.success("UP", "Ultra-fast service is running")
        ));
    }

    /**
     * Trigger manual preload
     */
    @PostMapping("/preload")
    public Mono<ResponseEntity<ApiResponse<String>>> triggerPreload() {
        log.info("Manual preload triggered");
        
        ultraFastApiService.preloadCriticalDataAsync()
                .thenRun(() -> log.info("Manual preload completed"));
        
        return Mono.just(ResponseEntity.ok(
            ApiResponse.success("TRIGGERED", "Preload initiated")
        ));
    }
}
