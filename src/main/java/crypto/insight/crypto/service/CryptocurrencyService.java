package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Service interface for cryptocurrency-related operations.
 */
public interface CryptocurrencyService {
    
    /**
     * Fetches detailed data for a specific cryptocurrency by its symbol.
     *
     * @param symbol The cryptocurrency symbol (e.g., "BTC")
     * @return A Mono emitting the cryptocurrency data
     */
    Mono<Cryptocurrency> getCryptocurrencyData(String symbol, int days);
    
    /**
     * Fetches market chart data for a specific cryptocurrency.
     *
     * @param symbol The cryptocurrency symbol (e.g., "BTC")
     * @param days Number of days of historical data to fetch
     * @return A Mono emitting a list of price points
     */
    Mono<List<List<Number>>> getMarketChart(String symbol, int days);
    
    /**
     * Searches for cryptocurrencies matching the given query.
     *
     * @param query The search query
     * @return A Flux emitting matching cryptocurrencies
     */
    // Flux<Cryptocurrency> searchCryptocurrencies(String query);
    
    /**
     * Fetches the top N cryptocurrencies by market cap.
     *
     * @param limit Maximum number of cryptocurrencies to return
     * @return A Flux emitting the top cryptocurrencies
     */
    // Flux<Cryptocurrency> getTopCryptocurrencies(int limit);
    
    /**
     * Fetches historical price data for a cryptocurrency.
     *
     * @param symbol The cryptocurrency symbol
     * @param days Number of days of historical data
     * @return A Mono emitting the historical data
     */
    // Mono<HistoricalData> getHistoricalData(String symbol, int days);
}
