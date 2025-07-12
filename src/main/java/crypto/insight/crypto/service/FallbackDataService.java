package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Fallback service that provides basic cryptocurrency data when external APIs are unavailable
 * due to rate limiting or other issues.
 */
@Slf4j
@Service
public class FallbackDataService {
    
    // Hardcoded data for top cryptocurrencies as fallback
    private static final Map<String, CryptoFallbackData> FALLBACK_DATA = Map.of(
        "BTC", new CryptoFallbackData("bitcoin", "Bitcoin", "BTC", 1, "₿"),
        "ETH", new CryptoFallbackData("ethereum", "Ethereum", "ETH", 2, "Ξ"),
        "BNB", new CryptoFallbackData("binancecoin", "BNB", "BNB", 3, "BNB"),
        "XRP", new CryptoFallbackData("ripple", "XRP", "XRP", 4, "XRP"),
        "ADA", new CryptoFallbackData("cardano", "Cardano", "ADA", 5, "₳"),
        "DOGE", new CryptoFallbackData("dogecoin", "Dogecoin", "DOGE", 6, "Ð"),
        "SOL", new CryptoFallbackData("solana", "Solana", "SOL", 7, "◎"),
        "MATIC", new CryptoFallbackData("polygon", "Polygon", "MATIC", 8, "MATIC"),
        "DOT", new CryptoFallbackData("polkadot", "Polkadot", "DOT", 9, "●"),
        "LINK", new CryptoFallbackData("chainlink", "Chainlink", "LINK", 10, "LINK")
    );
    
    /**
     * Get fallback cryptocurrency data when APIs are unavailable
     */
    public Mono<Cryptocurrency> getFallbackCryptocurrency(String symbol) {
        String normalizedSymbol = symbol.toUpperCase();
        
        CryptoFallbackData fallbackData = FALLBACK_DATA.get(normalizedSymbol);
        if (fallbackData == null) {
            // Create generic fallback for unknown cryptocurrencies
            fallbackData = new CryptoFallbackData(
                symbol.toLowerCase(), 
                symbol.toUpperCase(), 
                normalizedSymbol, 
                null, 
                normalizedSymbol
            );
        }
        
        log.info("Providing fallback data for cryptocurrency: {}", normalizedSymbol);
        
        Cryptocurrency crypto = Cryptocurrency.builder()
                .id(fallbackData.id)
                .name(fallbackData.name)
                .symbol(fallbackData.symbol)
                .rank(fallbackData.rank)
                .price(BigDecimal.ZERO) // Price unavailable in fallback mode
                .percentChange24h(BigDecimal.ZERO)
                .marketCap(null)
                .volume24h(null)
                .high24h(null)
                .low24h(null)
                .imageUrl(null)
                .lastUpdated(LocalDateTime.now())
                .build();
                
        return Mono.just(crypto);
    }
    
    /**
     * Get fallback analysis data with generic insights
     */
    public Mono<AnalysisResponse> getFallbackAnalysis(String symbol) {
        log.info("Providing fallback analysis for cryptocurrency: {}", symbol);
        
        AnalysisResponse analysis = AnalysisResponse.builder()
                .analysis(Map.of(
                    "general", "Data temporarily unavailable due to API rate limits. " +
                               "This cryptocurrency is being monitored, but detailed analysis " +
                               "requires external data sources that are currently limited.",
                    "sentiment", "NEUTRAL",
                    "riskLevel", "MEDIUM"
                ))
                .chartData(Collections.emptyList())
                .timestamp(LocalDateTime.now())
                .analysisTimestamp(LocalDateTime.now())
                .build();
                
        return Mono.just(analysis);
    }
    
    /**
     * Get empty chart data as fallback
     */
    public Mono<List<ChartDataPoint>> getFallbackChartData(String symbol, int days) {
        log.info("Providing empty chart data for cryptocurrency: {} (fallback mode)", symbol);
        return Mono.just(Collections.emptyList());
    }
    
    /**
     * Check if a symbol is supported in fallback mode
     */
    public boolean isSymbolSupported(String symbol) {
        return FALLBACK_DATA.containsKey(symbol.toUpperCase());
    }
    
    /**
     * Get list of supported cryptocurrencies in fallback mode
     */
    public List<Cryptocurrency> getSupportedCryptocurrencies() {
        return FALLBACK_DATA.values().stream()
                .map(fallbackData -> Cryptocurrency.builder()
                        .id(fallbackData.id)
                        .name(fallbackData.name)
                        .symbol(fallbackData.symbol)
                        .rank(fallbackData.rank)
                        .price(BigDecimal.ZERO)
                        .percentChange24h(BigDecimal.ZERO)
                        .lastUpdated(LocalDateTime.now())
                        .build())
                .collect(Collectors.toList());
    }
    
    private static class CryptoFallbackData {
        final String id;
        final String name;
        final String symbol;
        final Integer rank;
        final String displaySymbol;
        
        CryptoFallbackData(String id, String name, String symbol, Integer rank, String displaySymbol) {
            this.id = id;
            this.name = name;
            this.symbol = symbol;
            this.rank = rank;
            this.displaySymbol = displaySymbol;
        }
    }
}
