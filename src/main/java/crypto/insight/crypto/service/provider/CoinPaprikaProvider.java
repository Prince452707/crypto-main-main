package crypto.insight.crypto.service.provider;

import com.fasterxml.jackson.databind.JsonNode;
import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;

/**
 * Data provider implementation for CoinPaprika API.
 * CoinPaprika provides free cryptocurrency data without requiring an API key.
 */
@Service
@Order(4) // Fourth priority - Free tier but reliable
@Slf4j
public class CoinPaprikaProvider implements DataProvider {

    private final WebClient webClient;

    public CoinPaprikaProvider(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.coinpaprika.com/v1").build();
    }

    @Override
    public String getProviderName() {
        return "CoinPaprika";
    }

    @Override
    public Mono<CryptoIdentity> resolveIdentity(String query) {
        // First, search for coins matching the query
        return webClient.get()
                .uri("/search?q={query}&limit=10", query)
                .retrieve()
                .bodyToMono(JsonNode.class)
                .flatMap(response -> {
                    JsonNode currencies = response.path("currencies");
                    if (currencies.isArray() && !currencies.isEmpty()) {
                        // Find exact symbol match first
                        for (JsonNode currency : currencies) {
                            String symbol = currency.path("symbol").asText();
                            if (symbol.equalsIgnoreCase(query)) {
                                return Mono.just(createIdentityFromNode(query, currency));
                            }
                        }
                        
                        // If no exact match, use the first result
                        JsonNode firstResult = currencies.get(0);
                        return Mono.just(createIdentityFromNode(query, firstResult));
                    }
                    
                    // Fallback: try to find in all coins list
                    return searchInCoinsList(query);
                })
                .onErrorResume(e -> {
                    log.debug("Search endpoint failed for '{}', trying coins list: {}", query, e.getMessage());
                    return searchInCoinsList(query);
                });
    }

    private Mono<CryptoIdentity> searchInCoinsList(String query) {
        return webClient.get()
                .uri("/coins")
                .retrieve()
                .bodyToMono(JsonNode.class)
                .flatMap(response -> {
                    if (response.isArray()) {
                        String upperQuery = query.toUpperCase();
                        for (JsonNode coin : response) {
                            String symbol = coin.path("symbol").asText();
                            if (symbol.equalsIgnoreCase(upperQuery)) {
                                return Mono.just(createIdentityFromCoinNode(query, coin));
                            }
                        }
                    }
                    return Mono.error(new RuntimeException("Symbol not found in CoinPaprika: " + query));
                });
    }

    private CryptoIdentity createIdentityFromNode(String query, JsonNode currency) {
        CryptoIdentity identity = new CryptoIdentity(query);
        identity.setCoinpaprikaId(currency.path("id").asText());
        identity.setSymbol(currency.path("symbol").asText());
        identity.setName(currency.path("name").asText());
        return identity;
    }

    private CryptoIdentity createIdentityFromCoinNode(String query, JsonNode coin) {
        CryptoIdentity identity = new CryptoIdentity(query);
        identity.setCoinpaprikaId(coin.path("id").asText());
        identity.setSymbol(coin.path("symbol").asText());
        identity.setName(coin.path("name").asText());
        return identity;
    }

    @Override
    public Mono<CryptoData> fetchData(CryptoIdentity identity) {
        String coinId = identity.getCoinpaprikaId();
        if (coinId == null || coinId.isEmpty()) {
            log.debug("CoinPaprika ID not available for {}, skipping data fetch", identity.getSymbol());
            return Mono.empty(); // Return empty instead of error to allow other providers to work
        }

        // Get ticker data for the coin
        return webClient.get()
                .uri("/tickers/{id}", coinId)
                .retrieve()
                .bodyToMono(JsonNode.class)
                .map(response -> {
                    JsonNode quotes = response.path("quotes").path("USD");
                    
                    CryptoData data = new CryptoData(identity);
                    data.setSource(getProviderName());
                    data.setLastUpdated(java.time.LocalDateTime.now());
                    
                    // Set current price
                    if (!quotes.path("price").isMissingNode()) {
                        data.setCurrentPrice(new BigDecimal(quotes.path("price").asDouble()));
                    }
                    
                    // Set market cap
                    if (!quotes.path("market_cap").isMissingNode()) {
                        data.setMarketCap(new BigDecimal(quotes.path("market_cap").asLong()));
                    }
                    
                    // Set 24h volume
                    if (!quotes.path("volume_24h").isMissingNode()) {
                        data.setVolume24h(new BigDecimal(quotes.path("volume_24h").asLong()));
                    }
                    
                    // Set 24h price change percentage
                    if (!quotes.path("percent_change_24h").isMissingNode()) {
                        data.setPriceChange24h(new BigDecimal(quotes.path("percent_change_24h").asDouble()));
                    }
                    
                    // Set market cap rank
                    if (!response.path("rank").isMissingNode()) {
                        data.setMarketCapRank(response.path("rank").asInt());
                    }
                    
                    // Set circulating supply
                    if (!response.path("circulating_supply").isMissingNode()) {
                        data.setCirculatingSupply(new BigDecimal(response.path("circulating_supply").asLong()));
                    }
                    
                    // Set total supply
                    if (!response.path("total_supply").isMissingNode()) {
                        data.setTotalSupply(new BigDecimal(response.path("total_supply").asLong()));
                    }
                    
                    // Set max supply
                    if (!response.path("max_supply").isMissingNode() && !response.path("max_supply").isNull()) {
                        data.setMaxSupply(new BigDecimal(response.path("max_supply").asLong()));
                    }
                    
                    log.debug("Successfully fetched data from CoinPaprika for {}: ${}", 
                             identity.getSymbol(), data.getCurrentPrice());
                    
                    return data;
                })
                .onErrorResume(e -> {
                    log.warn("Failed to fetch data from CoinPaprika for {}: {}", identity.getSymbol(), e.getMessage());
                    return Mono.empty();
                });
    }
}
