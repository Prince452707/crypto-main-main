package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Slf4j
@Service
public class PredictiveCacheService {
    
    private final UltraFastApiService ultraFastApiService;
    private final ExecutorService predictiveExecutor;
    
    // Machine Learning-like usage pattern tracking
    private final Map<String, Integer> symbolAccessCount = new ConcurrentHashMap<>();
    private final Map<String, Long> lastAccessTime = new ConcurrentHashMap<>();
    private final Map<Integer, Integer> hourlyPageRequests = new ConcurrentHashMap<>();
    private final Queue<String> recentSearches = new LinkedList<>();
    
    // Predictive settings
    private static final int TOP_SYMBOLS_TO_PRELOAD = 30;
    private static final int SEARCH_PATTERN_WINDOW = 100;
    private static final long PREDICTION_THRESHOLD = 3; // Access 3+ times = preload
    
    public PredictiveCacheService(UltraFastApiService ultraFastApiService) {
        this.ultraFastApiService = ultraFastApiService;
        this.predictiveExecutor = Executors.newCachedThreadPool();
        initializePredictivePatterns();
    }
    
    /**
     * Track user access patterns for machine learning predictions
     */
    public void trackAccess(String symbol) {
        symbolAccessCount.merge(symbol.toLowerCase(), 1, Integer::sum);
        lastAccessTime.put(symbol.toLowerCase(), System.currentTimeMillis());
        
        // Trigger predictive loading if symbol becomes popular
        if (symbolAccessCount.get(symbol.toLowerCase()) >= PREDICTION_THRESHOLD) {
            predictiveLoadRelated(symbol);
        }
    }
    
    /**
     * Track page access patterns
     */
    public void trackPageAccess(int page) {
        int hour = LocalTime.now().getHour();
        hourlyPageRequests.merge(hour, 1, Integer::sum);
        
        // Predictively load next pages during peak hours
        if (isPeakHour(hour) && page <= 3) {
            predictiveLoadNextPages(page);
        }
    }
    
    /**
     * Track search patterns for predictive suggestions
     */
    public void trackSearch(String query) {
        synchronized (recentSearches) {
            recentSearches.offer(query.toLowerCase());
            if (recentSearches.size() > SEARCH_PATTERN_WINDOW) {
                recentSearches.poll();
            }
        }
        
        // Predict related searches
        predictRelatedSearches(query);
    }
    
    /**
     * Predictively load related cryptocurrencies
     */
    @Async
    protected void predictiveLoadRelated(String symbol) {
        CompletableFuture.runAsync(() -> {
            try {
                List<String> relatedSymbols = getRelatedSymbols(symbol);
                for (String related : relatedSymbols) {
                    ultraFastApiService.getCryptocurrencyDetailsUltraFast(related).subscribe();
                }
                log.debug("Predictively loaded {} related symbols for {}", relatedSymbols.size(), symbol);
            } catch (Exception e) {
                log.debug("Predictive loading failed for {}: {}", symbol, e.getMessage());
            }
        }, predictiveExecutor);
    }
    
    /**
     * Predictively load next pages
     */
    @Async
    protected void predictiveLoadNextPages(int currentPage) {
        CompletableFuture.runAsync(() -> {
            try {
                // Load next 2 pages
                for (int nextPage = currentPage + 1; nextPage <= currentPage + 2; nextPage++) {
                    ultraFastApiService.getMarketDataUltraFast(nextPage, 50).subscribe();
                }
                log.debug("Predictively loaded pages {} to {}", currentPage + 1, currentPage + 2);
            } catch (Exception e) {
                log.debug("Predictive page loading failed: {}", e.getMessage());
            }
        }, predictiveExecutor);
    }
    
    /**
     * Predict and preload related searches
     */
    @Async
    protected void predictRelatedSearches(String query) {
        CompletableFuture.runAsync(() -> {
            try {
                List<String> predictions = generateSearchPredictions(query);
                for (String prediction : predictions) {
                    ultraFastApiService.searchCryptocurrenciesUltraFast(prediction, 5).subscribe();
                }
                log.debug("Predictively loaded {} search predictions for '{}'", predictions.size(), query);
            } catch (Exception e) {
                log.debug("Predictive search loading failed: {}", e.getMessage());
            }
        }, predictiveExecutor);
    }
    
    /**
     * Intelligent preloading based on usage patterns
     */
    @Scheduled(fixedRate = 30000) // Every 30 seconds
    @Async
    public void intelligentPreload() {
        try {
            // Preload top accessed symbols
            List<String> topSymbols = getTopAccessedSymbols();
            if (!topSymbols.isEmpty()) {
                ultraFastApiService.batchLoadUltraFast(topSymbols.subList(0, 
                    Math.min(TOP_SYMBOLS_TO_PRELOAD, topSymbols.size()))).subscribe();
            }
            
            // Preload based on time patterns
            predictiveLoadByTimePattern();
            
        } catch (Exception e) {
            log.debug("Intelligent preload failed: {}", e.getMessage());
        }
    }
    
    /**
     * Time-based predictive loading
     */
    private void predictiveLoadByTimePattern() {
        int currentHour = LocalTime.now().getHour();
        
        // Peak hours: preload more aggressively
        if (isPeakHour(currentHour)) {
            // Load top 3 pages
            for (int page = 1; page <= 3; page++) {
                ultraFastApiService.getMarketDataUltraFast(page, 50).subscribe();
            }
        }
        
        // Market opening hours: preload trending cryptos
        if (isMarketOpeningHour(currentHour)) {
            List<String> trendingCryptos = getTrendingCryptos();
            ultraFastApiService.batchLoadUltraFast(trendingCryptos).subscribe();
        }
    }
    
    /**
     * Get related symbols using correlation patterns
     */
    private List<String> getRelatedSymbols(String symbol) {
        Map<String, List<String>> correlationMap = Map.of(
            "bitcoin", List.of("ethereum", "litecoin", "bitcoin-cash"),
            "ethereum", List.of("bitcoin", "chainlink", "uniswap", "polygon"),
            "binancecoin", List.of("ethereum", "cardano", "polkadot"),
            "cardano", List.of("ethereum", "polkadot", "solana"),
            "solana", List.of("ethereum", "cardano", "avalanche-2"),
            "ripple", List.of("stellar", "cardano", "tron"),
            "dogecoin", List.of("shiba-inu", "bitcoin", "litecoin")
        );
        
        return correlationMap.getOrDefault(symbol.toLowerCase(), 
            List.of("bitcoin", "ethereum", "binancecoin"));
    }
    
    /**
     * Generate search predictions based on patterns
     */
    private List<String> generateSearchPredictions(String query) {
        String lowerQuery = query.toLowerCase();
        
        // Common search expansions
        Map<String, List<String>> searchExpansions = Map.of(
            "btc", List.of("bitcoin", "bitcoin-cash", "litecoin"),
            "eth", List.of("ethereum", "ethereum-classic", "chainlink"),
            "doge", List.of("dogecoin", "shiba-inu"),
            "ada", List.of("cardano", "polkadot", "solana"),
            "bnb", List.of("binancecoin", "ethereum", "polygon")
        );
        
        if (searchExpansions.containsKey(lowerQuery)) {
            return searchExpansions.get(lowerQuery);
        }
        
        // Fuzzy predictions based on recent searches
        return recentSearches.stream()
            .filter(recent -> recent.contains(lowerQuery) || lowerQuery.contains(recent))
            .limit(3)
            .toList();
    }
    
    /**
     * Get top accessed symbols sorted by frequency and recency
     */
    private List<String> getTopAccessedSymbols() {
        long currentTime = System.currentTimeMillis();
        
        return symbolAccessCount.entrySet().stream()
            .filter(entry -> {
                Long lastAccess = lastAccessTime.get(entry.getKey());
                return lastAccess != null && (currentTime - lastAccess) < 300000; // Last 5 minutes
            })
            .sorted((e1, e2) -> {
                // Sort by access count and recency
                int countCompare = Integer.compare(e2.getValue(), e1.getValue());
                if (countCompare != 0) return countCompare;
                
                Long time1 = lastAccessTime.get(e1.getKey());
                Long time2 = lastAccessTime.get(e2.getKey());
                return Long.compare(time2, time1);
            })
            .map(Map.Entry::getKey)
            .limit(TOP_SYMBOLS_TO_PRELOAD)
            .toList();
    }
    
    /**
     * Check if current hour is peak usage time
     */
    private boolean isPeakHour(int hour) {
        return hourlyPageRequests.getOrDefault(hour, 0) > 10 || 
               (hour >= 9 && hour <= 17) || // Business hours
               (hour >= 19 && hour <= 22);  // Evening hours
    }
    
    /**
     * Check if it's market opening hour
     */
    private boolean isMarketOpeningHour(int hour) {
        return hour == 9 || hour == 14 || hour == 21; // Different market openings
    }
    
    /**
     * Get trending cryptocurrencies for preloading
     */
    private List<String> getTrendingCryptos() {
        return List.of("bitcoin", "ethereum", "binancecoin", "cardano", "solana",
                      "ripple", "polkadot", "dogecoin", "shiba-inu", "chainlink");
    }
    
    /**
     * Initialize predictive patterns with common cryptocurrencies
     */
    private void initializePredictivePatterns() {
        // Initialize with popular cryptos to start prediction engine
        List<String> popular = List.of("bitcoin", "ethereum", "binancecoin", "cardano", "solana");
        for (String symbol : popular) {
            symbolAccessCount.put(symbol, 2); // Start with some base popularity
            lastAccessTime.put(symbol, System.currentTimeMillis());
        }
        
        log.info("🤖 Predictive cache service initialized with ML-like patterns");
    }
    
    /**
     * Get prediction statistics for monitoring
     */
    public Map<String, Object> getPredictionStats() {
        return Map.of(
            "trackedSymbols", symbolAccessCount.size(),
            "recentSearches", recentSearches.size(),
            "hourlyPatterns", hourlyPageRequests.size(),
            "topSymbols", getTopAccessedSymbols(),
            "peakHour", isPeakHour(LocalTime.now().getHour())
        );
    }
}
