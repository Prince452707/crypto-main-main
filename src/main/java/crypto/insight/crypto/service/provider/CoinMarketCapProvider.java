package crypto.insight.crypto.service.provider;

import com.fasterxml.jackson.databind.JsonNode;
import crypto.insight.crypto.config.ApiProperties;
import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Service
@Order(2) // Second priority
@Slf4j
public class CoinMarketCapProvider implements DataProvider {

    private final WebClient webClient;
    private final ApiProperties apiProperties;

    public CoinMarketCapProvider(WebClient.Builder webClientBuilder, ApiProperties apiProperties) {
        this.webClient = webClientBuilder.baseUrl("https://pro-api.coinmarketcap.com").build();
        this.apiProperties = apiProperties;
    }

    @Override
    public String getProviderName() {
        return "CoinMarketCap";
    }

    @Override
    public Mono<CryptoIdentity> resolveIdentity(String query) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/v1/cryptocurrency/map")
                        .queryParam("symbol", query.toUpperCase())
                        .build())
                .header("X-CMC_PRO_API_KEY", apiProperties.getCoinmarketcap().getKey())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .map(response -> {
                    JsonNode data = response.path("data");
                    if (data.isArray() && !data.isEmpty()) {
                        JsonNode coinInfo = data.get(0);
                        CryptoIdentity identity = new CryptoIdentity(query);
                        identity.setCoinmarketcapId(String.valueOf(coinInfo.path("id").asInt()));
                        identity.setSymbol(coinInfo.path("symbol").asText());
                        identity.setName(coinInfo.path("name").asText());
                        return identity;
                    }
                    throw new RuntimeException("Symbol not found in CoinMarketCap map: " + query);
                });
    }

    @Override
    public Mono<CryptoData> fetchData(CryptoIdentity identity) {
        String symbol = identity.getSymbol();
        if (symbol == null) {
            return Mono.empty();
        }

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/v2/cryptocurrency/quotes/latest")
                        .queryParam("symbol", symbol)
                        .build())
                .header("X-CMC_PRO_API_KEY", apiProperties.getCoinmarketcap().getKey())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .map(response -> {
                    JsonNode data = response.path("data").path(symbol).get(0);
                    JsonNode quote = data.path("quote").path("USD");
                    CryptoData cryptoData = new CryptoData(identity);
                    cryptoData.setSource(getProviderName());
                    cryptoData.setCurrentPrice(quote.path("price").decimalValue());
                    cryptoData.setMarketCap(quote.path("market_cap").decimalValue());
                    cryptoData.setVolume24h(quote.path("volume_24h").decimalValue());
                    cryptoData.setPriceChange24h(quote.path("percent_change_24h").decimalValue());
                    return cryptoData;
                }).onErrorResume(e -> {
                    log.warn("Failed to fetch from {}: {}", getProviderName(), e.getMessage());
                    return Mono.empty();
                });
    }
}
