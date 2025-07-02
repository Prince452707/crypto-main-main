package crypto.insight.crypto.config;

import crypto.insight.crypto.config.properties.CoinGeckoProperties;
import crypto.insight.crypto.config.properties.CoinPaprikaProperties;
import crypto.insight.crypto.config.properties.CryptoCompareProperties;
import crypto.insight.crypto.config.properties.MobulaProperties;
import io.netty.handler.ssl.SslContextBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;
import reactor.netty.tcp.SslProvider;

import javax.net.ssl.SSLException;
import java.time.Duration;

@Configuration
public class WebClientConfig {

    @Bean(name = "webClient")
    public WebClient webClient() throws SSLException {
        SslProvider sslProvider = SslProvider.builder()
                .sslContext(SslContextBuilder.forClient().build())
                .handshakeTimeout(Duration.ofSeconds(30))
                .build();

        HttpClient httpClient = HttpClient.create()
                .secure(sslProvider)
                .responseTimeout(Duration.ofSeconds(30));

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .build();
    }

    @Bean("cryptoCompareWebClient")
    public WebClient cryptoCompareWebClient(CryptoCompareProperties properties) {
        return WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Apikey " + properties.getKey())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Bean("coinGeckoWebClient")
    public WebClient coinGeckoWebClient(CoinGeckoProperties properties) {
        return WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Bean("coinPaprikaWebClient")
    public WebClient coinPaprikaWebClient(CoinPaprikaProperties properties) {
        return WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Bean("mobulaWebClient")
    public WebClient mobulaWebClient(MobulaProperties properties) {
        return WebClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader("X-API-KEY", properties.getKey())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    @Bean("ollamaWebClient")
    public WebClient ollamaWebClient() {
        HttpClient httpClient = HttpClient.create()
                .responseTimeout(Duration.ofSeconds(120)); // Increased timeout for AI operations

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .baseUrl("http://localhost:11434")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }
}
