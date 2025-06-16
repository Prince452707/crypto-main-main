package crypto.insight.crypto.config;

import crypto.insight.crypto.filter.RateLimitFilter;
import crypto.insight.crypto.filter.SecurityHeadersFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.server.WebFilter;

@Configuration
public class WebConfig {
    
    @Bean
    public RateLimitFilter rateLimitFilter() {
        return new RateLimitFilter();
    }

    @Bean
    public SecurityHeadersFilter securityHeadersFilter() {
        return new SecurityHeadersFilter();
    }

    @Bean
    public WebFilter slashesNormalizingFilter() {
        return (exchange, chain) -> {
            String path = exchange.getRequest().getURI().getPath();
            if (path != null && path.contains("//")) {
                String newPath = path.replaceAll("/+", "/");
                return chain.filter(exchange.mutate().request(builder -> builder.path(newPath)).build());
            }
            return chain.filter(exchange);
        };
    }

}
