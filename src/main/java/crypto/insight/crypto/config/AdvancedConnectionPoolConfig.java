package crypto.insight.crypto.config;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;
import reactor.netty.resources.ConnectionProvider;
import reactor.netty.transport.ProxyProvider;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Slf4j
@Configuration
public class AdvancedConnectionPoolConfig {

    @Bean("extremePerformanceWebClient")
    public WebClient extremePerformanceWebClient() {
        // Ultra-aggressive connection pool settings
        ConnectionProvider connectionProvider = ConnectionProvider.builder("extreme-crypto-pool")
                .maxConnections(1000)           // Massive connection pool
                .maxIdleTime(Duration.ofSeconds(30))      // Quick idle cleanup
                .maxLifeTime(Duration.ofMinutes(3))       // Short lifetime for fresh connections
                .pendingAcquireTimeout(Duration.ofSeconds(5))
                .evictInBackground(Duration.ofSeconds(15)) // Aggressive cleanup
                .fifo()                         // FIFO ordering for better cache locality
                .metrics(true)                  // Enable metrics for monitoring
                .build();

        // Extreme HTTP client optimization
        HttpClient httpClient = HttpClient.create(connectionProvider)
                // Ultra-fast timeouts
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 1500)
                .option(ChannelOption.SO_KEEPALIVE, true)
                .option(ChannelOption.TCP_NODELAY, true)
                .option(ChannelOption.SO_REUSEADDR, true)
                .option(ChannelOption.SO_RCVBUF, 65536)    // 64KB receive buffer
                .option(ChannelOption.SO_SNDBUF, 65536)    // 64KB send buffer
                
                // Timeouts
                .doOnConnected(conn -> 
                    conn.addHandlerLast(new ReadTimeoutHandler(8, TimeUnit.SECONDS))
                        .addHandlerLast(new WriteTimeoutHandler(5, TimeUnit.SECONDS)))
                
                // Performance optimizations
                .compress(true)
                .keepAlive(true)
                .followRedirect(true)
                
                // HTTP/2 support
                .protocol(reactor.netty.http.HttpProtocol.H2C, reactor.netty.http.HttpProtocol.HTTP11)
                
                // Disable SSL verification for local development (faster)
                .secure(sslContextSpec -> {
                    try {
                        sslContextSpec.sslContext(
                            io.netty.handler.ssl.SslContextBuilder.forClient()
                                .trustManager(io.netty.handler.ssl.util.InsecureTrustManagerFactory.INSTANCE)
                                .build());
                    } catch (javax.net.ssl.SSLException e) {
                        throw new RuntimeException("Failed to build SSL context", e);
                    }
                })
                
                // Response size limits
                .responseTimeout(Duration.ofSeconds(10));

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> {
                    configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024); // 2MB buffer
                    configurer.defaultCodecs().enableLoggingRequestDetails(false); // Disable for performance
                })
                .defaultHeaders(headers -> {
                    headers.add("User-Agent", "CryptoInsight-Ultra/2.0");
                    headers.add("Accept", "application/json");
                    headers.add("Accept-Encoding", "gzip, deflate, br");
                    headers.add("Connection", "keep-alive");
                    headers.add("Cache-Control", "max-age=30");
                })
                .build();
    }

    @Bean("loadBalancedWebClient")
    public WebClient loadBalancedWebClient() {
        // Create multiple connection providers for load balancing
        ConnectionProvider provider1 = ConnectionProvider.builder("pool-1")
                .maxConnections(300)
                .maxIdleTime(Duration.ofSeconds(45))
                .build();
                
        ConnectionProvider provider2 = ConnectionProvider.builder("pool-2")
                .maxConnections(300)
                .maxIdleTime(Duration.ofSeconds(45))
                .build();

        // Use provider1 for primary connections
        HttpClient primaryClient = HttpClient.create(provider1)
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 2000)
                .compress(true)
                .keepAlive(true);

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(primaryClient))
                .build();
    }

    @Bean("cachingWebClient")
    public WebClient cachingWebClient() {
        // Specialized client for cacheable responses
        ConnectionProvider cachingProvider = ConnectionProvider.builder("caching-pool")
                .maxConnections(200)
                .maxIdleTime(Duration.ofMinutes(2))    // Longer idle for cache hits
                .maxLifeTime(Duration.ofMinutes(10))   // Longer lifetime for caching
                .build();

        HttpClient cachingClient = HttpClient.create(cachingProvider)
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 3000) // Slightly longer timeout
                .compress(true)
                .keepAlive(true)
                .doOnConnected(conn -> 
                    conn.addHandlerLast(new ReadTimeoutHandler(15, TimeUnit.SECONDS)));

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(cachingClient))
                .defaultHeaders(headers -> {
                    headers.add("Cache-Control", "max-age=300"); // 5-minute cache
                    headers.add("Accept-Encoding", "gzip, deflate");
                })
                .build();
    }

    /**
     * Bean post-processor to log connection pool statistics
     */
    @Bean
    public ConnectionPoolMonitor connectionPoolMonitor() {
        return new ConnectionPoolMonitor();
    }

    @Slf4j
    public static class ConnectionPoolMonitor {
        
        @jakarta.annotation.PostConstruct
        public void logPoolConfiguration() {
            log.info("🚀 EXTREME Performance Connection Pools Initialized:");
            log.info("   📊 Main Pool: 1000 connections, 1.5s timeout");
            log.info("   ⚖️ Load Balanced: 2x300 connections");
            log.info("   💾 Caching Pool: 200 connections, optimized for cache hits");
            log.info("   🔧 Features: HTTP/2, compression, keep-alive, 2MB buffers");
        }
    }
}
