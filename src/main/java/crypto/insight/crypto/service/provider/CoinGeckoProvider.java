package crypto.insight.crypto.service.provider;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@Service
@Order(3) // Lowest priority
@Slf4j
public class CoinGeckoProvider implements DataProvider {

    private final WebClient webClient;

    public CoinGeckoProvider(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.coingecko.com/api/v3").build();
    }

    @Override
    public String getProviderName() {
        return "CoinGecko";
    }

    @Override
    public Mono<CryptoIdentity> resolveIdentity(String query) {
        return webClient.get()
                .uri("/search?query={query}", query)
                .retrieve()
                .bodyToMono(CoinGeckoSearchResponse.class)
                .map(response -> {
                    if (response.getCoins() == null || response.getCoins().isEmpty()) {
                        throw new RuntimeException("No coins found on CoinGecko for: " + query);
                    }
                    CoinGeckoCoin bestMatch = response.getCoins().get(0);
                    CryptoIdentity identity = new CryptoIdentity(query);
                    identity.setCoingeckoId(bestMatch.getId());
                    identity.setName(bestMatch.getName());
                    identity.setSymbol(bestMatch.getSymbol());
                    return identity;
                });
    }

    @Override
    public Mono<CryptoData> fetchData(CryptoIdentity identity) {
        if (identity.getCoingeckoId() == null) {
            return Mono.error(new IllegalArgumentException("CoinGecko ID is required for fetch"));
        }

        return webClient.get()
                .uri("/coins/{id}", identity.getCoingeckoId())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .map(response -> {
                    JsonNode marketData = response.path("market_data");
                    CryptoData data = new CryptoData(identity);
                    data.setSource(getProviderName());
                    data.setCurrentPrice(marketData.path("current_price").path("usd").decimalValue());
                    data.setMarketCap(marketData.path("market_cap").path("usd").decimalValue());
                    data.setVolume24h(marketData.path("total_volume").path("usd").decimalValue());
                    data.setPriceChange24h(marketData.path("price_change_percentage_24h").decimalValue());
                    return data;
                });
    }

    // DTOs for CoinGecko responses
    @Data
    private static class CoinGeckoSearchResponse {
        private List<CoinGeckoCoin> coins;
    }

    @Data
    private static class CoinGeckoCoin {
        private String id;
        private String name;
        private String symbol;
        @JsonProperty("market_cap_rank")
        private int marketCapRank;
    }
}
