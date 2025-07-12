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
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;

@Service
@Order(1) // Higher priority due to comprehensive data
@Slf4j
public class CoinGeckoProvider implements DataProvider {

    private final WebClient webClient;

    public CoinGeckoProvider(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
            .baseUrl("https://api.coingecko.com/api/v3")
            .build();
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
                .timeout(Duration.ofSeconds(10))
                .onErrorMap(WebClientResponseException.class, ex -> {
                    if (ex.getStatusCode().value() == 429) {
                        log.warn("CoinGecko rate limit hit for query: {}", query);
                        return new RuntimeException("Rate limit exceeded for CoinGecko: " + ex.getMessage());
                    }
                    return ex;
                })
                .map(response -> {
                    if (response.getCoins() == null || response.getCoins().isEmpty()) {
                        throw new RuntimeException("No coins found on CoinGecko for: " + query);
                    }
                    CoinGeckoCoin bestMatch = response.getCoins().get(0);
                    CryptoIdentity identity = new CryptoIdentity(query);
                    identity.setCoingeckoId(bestMatch.getId());
                    identity.setName(bestMatch.getName());
                    identity.setSymbol(bestMatch.getSymbol().toUpperCase());
                    return identity;
                });
    }

    @Override
    public Mono<CryptoData> fetchData(CryptoIdentity identity) {
        if (identity.getCoingeckoId() == null) {
            return Mono.error(new IllegalArgumentException("CoinGecko ID is required for fetch"));
        }

        return webClient.get()
                .uri("/coins/{id}?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false", 
                     identity.getCoingeckoId())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .timeout(Duration.ofSeconds(15))
                .onErrorMap(WebClientResponseException.class, ex -> {
                    if (ex.getStatusCode().value() == 429) {
                        log.warn("CoinGecko rate limit hit for {}", identity.getSymbol());
                        return new RuntimeException("Rate limit exceeded for CoinGecko: " + ex.getMessage());
                    }
                    return ex;
                })
                .map(response -> {
                    JsonNode marketData = response.path("market_data");
                    CryptoData data = new CryptoData(identity);
                    data.setSource(getProviderName());
                    
                    // Price data
                    JsonNode currentPrice = marketData.path("current_price").path("usd");
                    if (!currentPrice.isMissingNode()) {
                        data.setCurrentPrice(new BigDecimal(currentPrice.asText()));
                    }
                    
                    // Market cap
                    JsonNode marketCap = marketData.path("market_cap").path("usd");
                    if (!marketCap.isMissingNode()) {
                        data.setMarketCap(new BigDecimal(marketCap.asText()));
                    }
                    
                    // Volume
                    JsonNode volume = marketData.path("total_volume").path("usd");
                    if (!volume.isMissingNode()) {
                        data.setVolume24h(new BigDecimal(volume.asText()));
                    }
                    
                    // Price change percentage
                    JsonNode priceChange = marketData.path("price_change_percentage_24h");
                    if (!priceChange.isMissingNode()) {
                        data.setPriceChange24h(new BigDecimal(priceChange.asText()));
                    }
                    
                    // Market cap rank
                    JsonNode marketCapRank = response.path("market_cap_rank");
                    if (!marketCapRank.isMissingNode()) {
                        data.setMarketCapRank(marketCapRank.asInt());
                    }
                    
                    // Supply data
                    JsonNode circulatingSupply = marketData.path("circulating_supply");
                    if (!circulatingSupply.isMissingNode()) {
                        data.setCirculatingSupply(new BigDecimal(circulatingSupply.asText()));
                    }
                    
                    JsonNode totalSupply = marketData.path("total_supply");
                    if (!totalSupply.isMissingNode()) {
                        data.setTotalSupply(new BigDecimal(totalSupply.asText()));
                    }
                    
                    JsonNode maxSupply = marketData.path("max_supply");
                    if (!maxSupply.isMissingNode()) {
                        data.setMaxSupply(new BigDecimal(maxSupply.asText()));
                    }
                    
                    // Image URL
                    JsonNode image = response.path("image").path("large");
                    if (!image.isMissingNode()) {
                        data.setImageUrl(image.asText());
                    }
                    
                    log.debug("Fetched comprehensive data from CoinGecko for {}", identity.getSymbol());
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
