package crypto.insight.crypto;

import crypto.insight.crypto.service.UltraFastApiService;
import crypto.insight.crypto.service.RealTimeStreamingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.scheduling.annotation.EnableScheduling;

import crypto.insight.crypto.config.properties.*;
import crypto.insight.crypto.config.ApiProperties;

@Slf4j
@SpringBootApplication
@EnableCaching
@EnableScheduling
@EnableAspectJAutoProxy
@EnableConfigurationProperties({
    ApiProperties.class,
    CryptoCompareProperties.class,
    CoinGeckoProperties.class,
    CoinPaprikaProperties.class,
    MobulaProperties.class,
    RateLimitingProperties.class
})
public class CryptoInsightApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(CryptoInsightApplication.class, args);
    }
    
   
    @Bean
    CommandLineRunner preloadCriticalData(UltraFastApiService ultraFastApiService, RealTimeStreamingService realTimeStreamingService) {
        return args -> {
            log.info("🚀 Starting critical data preload for ultra-fast performance...");
            ultraFastApiService.preloadCriticalDataAsync()
                    .thenRun(() -> log.info("✅ Critical data preload completed - ready for ultra-fast responses!"))
                    .exceptionally(ex -> {
                        log.warn("⚠️ Critical data preload failed: {}", ex.getMessage());
                        return null;
                    });
            
           
            log.info("🔄 Starting real-time streaming service...");
            realTimeStreamingService.startRealTimeStreaming();
            log.info("✅ Real-time streaming service started!");
        };
    }
}
