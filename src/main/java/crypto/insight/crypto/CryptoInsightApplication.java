package crypto.insight.crypto;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

import crypto.insight.crypto.config.properties.*;
import crypto.insight.crypto.config.ApiProperties;

@SpringBootApplication
@EnableCaching
@EnableScheduling

@EnableAspectJAutoProxy
@EnableConfigurationProperties({
    ApiProperties.class,
    CryptoCompareProperties.class,
    CoinGeckoProperties.class,
    CoinPaprikaProperties.class,
    MobulaProperties.class
})
public class CryptoInsightApplication {
    public static void main(String[] args) {
        SpringApplication.run(CryptoInsightApplication.class, args);
    }
}
