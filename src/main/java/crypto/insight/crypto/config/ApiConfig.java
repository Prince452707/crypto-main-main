package crypto.insight.crypto.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "api")
public class ApiConfig {
    private CryptoCompare cryptocompare = new CryptoCompare();
    private CoinGecko coingecko = new CoinGecko();
    private Coinpaprika coinpaprika = new Coinpaprika();
    private Mobula mobula = new Mobula();
    private CoinMarketCap coinmarketcap = new CoinMarketCap();

    @Data
    public static class CryptoCompare {
        private String key;
        private String baseUrl;
    }

    @Data
    public static class CoinGecko {
        private String baseUrl;
    }

    @Data
    public static class Coinpaprika {
        private String baseUrl;
    }

    @Data
    public static class Mobula {
        private String key;
        private String baseUrl;
    }

    @Data
    public static class CoinMarketCap {
        private String key;
        private String baseUrl;
    }
}
