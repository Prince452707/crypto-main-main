package crypto.insight.crypto.service;

import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import crypto.insight.crypto.service.provider.DataProvider;
import crypto.insight.crypto.service.provider.RateLimitingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Enhanced service for fetching detailed crypto data with aggressive caching,
 * smart rate limiting, and provider prioritization
 */
@Service
@Slf4j
public class FocusedCryptoDetailService {
    
    private final List<DataProvider> dataProviders;
    private final RateLimitingService rateLimitingService;
    private final Cache detailCache;
    private final Cache identityCache;
    private final ScheduledExecutorService scheduler;
    
    // Cache durations
    private static final Duration IDENTITY_CACHE_DURATION = Duration.ofHours(24);
    private static final Duration DETAIL_CACHE_DURATION = Duration.ofMinutes(5);
    private static final Duration PRICE_CACHE_DURATION = Duration.ofMinutes(1);
    
    public FocusedCryptoDetailService(
            List<DataProvider> dataProviders,
            RateLimitingService rateLimitingService,
            @org.springframework.beans.factory.annotation.Qualifier("cacheManager") CacheManager cacheManager) {
        this.dataProviders = dataProviders;
        this.rateLimitingService = rateLimitingService;
        this.detailCache = cacheManager.getCache("detailCache");
        this.identityCache = cacheManager.getCache("identityCache");
        this.scheduler = Executors.newScheduledThreadPool(2);
    }
    
    /**
     * Get comprehensive crypto data with maximum focus on the requested cryptocurrency
     * Uses intelligent provider selection and aggressive caching
     */
    public Mono<CryptoData> getFocusedCryptoData(String query, boolean forceRefresh) {
        String normalizedQuery = query.trim().toLowerCase();
        String cacheKey = "focused_" + normalizedQuery;
        
        log.info("Fetching focused crypto data for: {} (forceRefresh: {})", query, forceRefresh);
        
        if (!forceRefresh) {
            // Check cache first
            CryptoData cachedData = detailCache.get(cacheKey, CryptoData.class);
            if (cachedData != null) {
                log.info("Cache hit for focused data: {}", normalizedQuery);
                return Mono.just(cachedData);
            }
        }
        
        // Get or resolve identity
        return getOrResolveIdentity(normalizedQuery, forceRefresh)
            .flatMap(identity -> {
                log.info("Resolved identity for {}: {} ({})", query, identity.getSymbol(), identity.getName());
                return fetchDataWithSmartProviderSelection(identity, cacheKey);
            })
            .doOnSuccess(data -> {
                // Cache the result
                detailCache.put(cacheKey, data);
                log.info("Cached focused data for: {}", normalizedQuery);
            })
            .doOnError(error -> log.error("Failed to fetch focused data for {}: {}", query, error.getMessage()));
    }
    
    /**
     * Get or resolve crypto identity with caching
     */
    private Mono<CryptoIdentity> getOrResolveIdentity(String query, boolean forceRefresh) {
        String identityCacheKey = "identity_" + query;
        
        if (!forceRefresh) {
            CryptoIdentity cachedIdentity = identityCache.get(identityCacheKey, CryptoIdentity.class);
            if (cachedIdentity != null) {
                log.debug("Identity cache hit for: {}", query);
                return Mono.just(cachedIdentity);
            }
        }
        
        // Resolve from providers with smart ordering
        return getProvidersOrderedByReliability()
            .flatMap(provider -> {
                String providerName = provider.getProviderName();
                
                return rateLimitingService.executeWithRateLimit(providerName, 
                    provider.resolveIdentity(query)
                        .doOnSuccess(identity -> log.info("Provider '{}' resolved '{}' -> {}", 
                            providerName, query, identity.getSymbol()))
                        .onErrorResume(error -> {
                            log.debug("Provider '{}' failed to resolve '{}': {}", 
                                providerName, query, error.getMessage());
                            return Mono.empty();
                        })
                );
            })
            .collectList()
            .flatMap(identities -> {
                if (identities.isEmpty()) {
                    return Mono.error(new RuntimeException("Could not resolve cryptocurrency: " + query));
                }
                
                // Merge all identities
                CryptoIdentity mergedIdentity = identities.get(0);
                for (int i = 1; i < identities.size(); i++) {
                    mergedIdentity.merge(identities.get(i));
                }
                
                // Cache the merged identity
                identityCache.put(identityCacheKey, mergedIdentity);
                log.info("Cached merged identity for '{}': {}", query, mergedIdentity);
                
                return Mono.just(mergedIdentity);
            });
    }
    
    /**
     * Get providers ordered by current reliability (failures, circuit breaker state)
     */
    private Flux<DataProvider> getProvidersOrderedByReliability() {
        return Flux.fromIterable(dataProviders)
            .sort(Comparator.comparingInt(provider -> 
                rateLimitingService.getProviderPriority(provider.getProviderName())
            ));
    }
    
    /**
     * Fetch data with intelligent provider selection and parallel processing
     */
    private Mono<CryptoData> fetchDataWithSmartProviderSelection(CryptoIdentity identity, String cacheKey) {
        log.info("Fetching data for identity: {} from all available providers", identity.getSymbol());
        
        // Start with the merged identity
        CryptoData aggregatedData = new CryptoData(identity);
        
        // Fetch from all providers in parallel, but with rate limiting
        return getProvidersOrderedByReliability()
            .flatMap(provider -> {
                String providerName = provider.getProviderName();
                
                return rateLimitingService.executeWithRateLimit(providerName,
                    provider.fetchData(identity)
                        .doOnSuccess(data -> log.info("Successfully fetched data from {}", providerName))
                        .doOnError(error -> log.warn("Provider {} failed: {}", providerName, error.getMessage()))
                        .onErrorResume(error -> {
                            log.debug("Skipping provider {} due to error: {}", providerName, error.getMessage());
                            return Mono.empty();
                        })
                );
            })
            .collectList()
            .map(dataList -> {
                // Merge all data into the aggregated result
                for (CryptoData data : dataList) {
                    aggregatedData.mergeWith(data);
                }
                
                log.info("Aggregated data from {} providers for {}", dataList.size(), identity.getSymbol());
                return aggregatedData;
            });
    }
    
    /**
     * Preload data for popular cryptocurrencies to improve response times
     */
    public void preloadPopularCryptos() {
        String[] popularCryptos = {
            "bitcoin", "ethereum", "binancecoin", "ripple", "cardano", 
            "solana", "avalanche", "polkadot", "dogecoin", "chainlink"
        };
        
        log.info("Preloading data for {} popular cryptocurrencies", popularCryptos.length);
        
        for (String crypto : popularCryptos) {
            scheduler.schedule(() -> {
                getFocusedCryptoData(crypto, false)
                    .subscribe(
                        data -> log.debug("Preloaded data for {}", crypto),
                        error -> log.debug("Failed to preload {}: {}", crypto, error.getMessage())
                    );
            }, (long) (Math.random() * 10), TimeUnit.SECONDS); // Spread requests over 10 seconds
        }
    }
    
    /**
     * Get current rate limiting status
     */
    public String getRateLimitStatus() {
        return rateLimitingService.getRateLimitStatus();
    }
    
    /**
     * Clear cache for specific cryptocurrency
     */
    public void clearCache(String query) {
        String normalizedQuery = query.trim().toLowerCase();
        detailCache.evict("focused_" + normalizedQuery);
        identityCache.evict("identity_" + normalizedQuery);
        log.info("Cleared cache for: {}", normalizedQuery);
    }
    
    /**
     * Refresh data for specific cryptocurrency with priority
     */
    public Mono<CryptoData> refreshCryptoData(String query) {
        log.info("Force refreshing data for: {}", query);
        clearCache(query);
        return getFocusedCryptoData(query, true);
    }
}
