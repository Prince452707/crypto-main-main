package crypto.insight.crypto.service.provider;

import com.fasterxml.jackson.databind.JsonNode;
import crypto.insight.crypto.config.ApiProperties;
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
 * Data provider implementation for CryptoCompare API.
 * This provider fetches cryptocurrency data from the CryptoCompare service.
 */
@Service
@Order(1) // Highest priority
@Slf4j
public class CryptoCompareProvider implements DataProvider {

    private final WebClient webClient;
    private final ApiProperties apiProperties;

    public CryptoCompareProvider(WebClient.Builder webClientBuilder, ApiProperties apiProperties) {
        this.webClient = webClientBuilder.baseUrl("https://min-api.cryptocompare.com").build();
        this.apiProperties = apiProperties;
    }

    @Override
    public String getProviderName() {
        return "CryptoCompare";
    }

    @Override
    public Mono<CryptoIdentity> resolveIdentity(String query) {
        return webClient.get()
                .uri("/data/all/coinlist")
                .retrieve()
                .bodyToMono(JsonNode.class)
                .flatMap(response -> {
                    JsonNode data = response.path("Data");
                    final String upperCaseQuery = query.toUpperCase();
                    
                    // First try exact symbol match
                    if (data.has(upperCaseQuery)) {
                        return Mono.just(createIdentityFromNode(query, data.get(upperCaseQuery)));
                    }
                    
                    // If no exact match, search by name
                    return Flux.fromIterable(data::fields)
                            .filter(entry -> {
                                JsonNode coinInfo = entry.getValue();
                                String coinName = coinInfo.path("CoinName").asText("");
                                return coinName.equalsIgnoreCase(query);
                            })
                            .next()
                            .map(entry -> createIdentityFromNode(query, entry.getValue()))
                            .switchIfEmpty(Mono.error(new RuntimeException("Coin not found in CryptoCompare: " + query)));
                });
    }

    private CryptoIdentity createIdentityFromNode(String query, JsonNode coinInfo) {
        CryptoIdentity identity = new CryptoIdentity(query);
        identity.setCryptocompareId(coinInfo.path("Id").asText());
        identity.setSymbol(coinInfo.path("Symbol").asText());
        identity.setName(coinInfo.path("CoinName").asText());
        return identity;
    }

    @Override
    public Mono<CryptoData> fetchData(CryptoIdentity identity) {
        String symbol = identity.getSymbol();
        if (symbol == null) {
            return Mono.empty(); // Cannot fetch without a symbol
        }

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/data/pricemultifull")
                        .queryParam("fsyms", symbol)
                        .queryParam("tsyms", "USD")
                        .queryParam("api_key", apiProperties.getCryptocompare().getKey())
                        .build())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .map(response -> {
                    JsonNode raw = response.path("RAW").path(symbol).path("USD");
                    if (raw.isMissingNode()) {
                        throw new RuntimeException("Data not available for symbol in CryptoCompare: " + symbol);
                    }
                    
                    CryptoData data = new CryptoData(identity);
                    data.setSource(getProviderName());
                    
                    // Set price data
                    data.setCurrentPrice(safeBigDecimal(raw.path("PRICE")));
                    data.setPrice(safeBigDecimal(raw.path("PRICE"))); // For backward compatibility
                    
                    // Set market data
                    data.setMarketCap(safeBigDecimal(raw.path("MKTCAP")));
                    data.setVolume24h(safeBigDecimal(raw.path("TOTALVOLUME24H")));
                    
                    // Set price change data
                    data.setPriceChange24h(safeBigDecimal(raw.path("CHANGEPCT24HOUR")));
                    data.setPercentChange24h(safeBigDecimal(raw.path("CHANGEPCT24HOUR")));
                    
                    return data;
                })
                .onErrorResume(e -> {
                    log.warn("Failed to fetch from {}: {}", getProviderName(), e.getMessage());
                    return Mono.empty();
                });
    }
    
    private BigDecimal safeBigDecimal(JsonNode node) {
        return node != null && !node.isMissingNode() && !node.isNull() ? 
               node.decimalValue() : null;
    }
}
