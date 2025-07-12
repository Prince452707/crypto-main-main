package crypto.insight.crypto.config;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;
import reactor.netty.resources.ConnectionProvider;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Configuration
public class OptimizedWebClientConfig {

    @Bean
    public WebClient.Builder webClientBuilder() {
        // Configure connection pooling for maximum performance
        ConnectionProvider connectionProvider = ConnectionProvider.builder("crypto-api-pool")
                .maxConnections(200)
                .maxIdleTime(Duration.ofMinutes(1))
                .maxLifeTime(Duration.ofMinutes(5))
                .pendingAcquireTimeout(Duration.ofSeconds(10))
                .evictInBackground(Duration.ofSeconds(30))
                .build();

        // Configure HTTP client with optimizations
        HttpClient httpClient = HttpClient.create(connectionProvider)
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)
                .option(ChannelOption.SO_KEEPALIVE, true)
                .option(ChannelOption.TCP_NODELAY, true)
                .doOnConnected(conn -> 
                    conn.addHandlerLast(new ReadTimeoutHandler(15, TimeUnit.SECONDS))
                        .addHandlerLast(new WriteTimeoutHandler(10, TimeUnit.SECONDS)))
                .compress(true)
                .keepAlive(true);

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1024)); // 1MB buffer
    }

    @Bean("optimizedWebClient")
    public WebClient optimizedWebClient(WebClient.Builder webClientBuilder) {
        return webClientBuilder
                .defaultHeaders(headers -> {
                    headers.add("User-Agent", "CryptoInsight/1.0");
                    headers.add("Accept", "application/json");
                    headers.add("Accept-Encoding", "gzip, deflate");
                    headers.add("Connection", "keep-alive");
                })
                .build();
    }
}
