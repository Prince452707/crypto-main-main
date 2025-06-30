package crypto.insight.crypto.config;

import org.springframework.web.reactive.config.WebFluxConfigurer;

// Disabled to avoid conflicts with GlobalCorsConfig
// @Configuration
// @EnableWebFlux
public class CorsGlobalConfiguration implements WebFluxConfigurer {

    // Disabled to avoid conflicts with GlobalCorsConfig
    /*
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins(
                    "http://localhost:8088",     // Original configuration
                    "http://localhost:3000",     // React development server
                    "http://localhost:8080",     // Alternative Flutter web port
                    "http://localhost:5000",     // Flutter web debug port
                    "http://127.0.0.1:3000",     // Alternative localhost format
                    "http://127.0.0.1:8080",     // Alternative localhost format
                    "http://127.0.0.1:5000"      // Alternative localhost format
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
    */
}
