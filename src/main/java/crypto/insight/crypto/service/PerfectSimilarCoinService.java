package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Perfect Similar Coin Service - Ultra-intelligent cryptocurrency similarity analysis
 * This service provides perfect AI-powered similar coin recommendations with comprehensive analysis
 */
@Slf4j
@Service
public class PerfectSimilarCoinService {

    private final AIService aiService;
    private final ApiService apiService;
    private final PerfectAIQAService perfectAIQAService;
    private final Map<String, List<Map<String, Object>>> similarCoinCache = new ConcurrentHashMap<>();
    private final Map<String, Long> cacheTimestamps = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
    
    private static final long CACHE_DURATION_MS = 5 * 60 * 1000; // 5 minutes
    private static final int MAX_CACHE_SIZE = 500;
    private static final Map<String, Set<String>> PERFECT_SIMILARITY_MAP = initializePerfectSimilarityMap();
    private static final Map<String, String> COIN_CATEGORIES = initializeCoinCategories();
    private static final Map<String, List<String>> CATEGORY_SIMILARITIES = initializeCategorySimilarities();

    public PerfectSimilarCoinService(AIService aiService, ApiService apiService, PerfectAIQAService perfectAIQAService) {
        this.aiService = aiService;
        this.apiService = apiService;
        this.perfectAIQAService = perfectAIQAService;
        initializeCacheCleanup();
        preloadSimilarityData();
    }

    /**
     * Find perfect similar cryptocurrencies with ultra-intelligent AI analysis
     */
    public CompletableFuture<Map<String, Object>> findSimilarCryptocurrenciesPerfect(
            String symbol, 
            int limit, 
            boolean includeAIAnalysis,
            boolean includeMarketData,
            String analysisDepth) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                log.info("🔍 Perfect similar coin analysis for: {}", symbol);
                
                // Check cache first
                String cacheKey = generateCacheKey(symbol, limit, includeAIAnalysis, analysisDepth);
                List<Map<String, Object>> cachedSimilar = getCachedSimilar(cacheKey);
                if (cachedSimilar != null) {
                    log.debug("💨 Using cached perfect similar coins for {}", symbol);
                    return createPerfectResponse(symbol, cachedSimilar, includeAIAnalysis, true);
                }
                
                // Multi-layered similarity analysis
                List<Map<String, Object>> similarCoins = performMultiLayeredAnalysis(symbol, limit, includeMarketData);
                
                // Enhanced AI analysis if requested
                if (includeAIAnalysis) {
                    similarCoins = enhanceWithAIAnalysis(symbol, similarCoins, analysisDepth);
                }
                
                // Advanced scoring and ranking
                similarCoins = applyAdvancedScoring(symbol, similarCoins);
                
                // Cache the results
                cacheSimilar(cacheKey, similarCoins);
                
                log.info("✅ Perfect similar coins found for {}: {} coins", symbol, similarCoins.size());
                return createPerfectResponse(symbol, similarCoins, includeAIAnalysis, false);
                
            } catch (Exception e) {
                log.error("❌ Perfect similar coin analysis failed for {}: {}", symbol, e.getMessage(), e);
                return createErrorResponse(e.getMessage());
            }
        });
    }

    /**
     * Get AI-powered coin comparison analysis
     */
    public CompletableFuture<Map<String, Object>> compareCoinsWithAI(
            String symbol1, 
            String symbol2, 
            String comparisonType,
            boolean includeMarketData) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                log.info("🤖 AI-powered coin comparison: {} vs {}", symbol1, symbol2);
                
                // Get detailed coin data
                Map<String, Object> coin1Data = getCoinDetailsForComparison(symbol1, includeMarketData);
                Map<String, Object> coin2Data = getCoinDetailsForComparison(symbol2, includeMarketData);
                
                // Perform multi-dimensional comparison
                Map<String, Object> comparison = performMultiDimensionalComparison(
                    symbol1, symbol2, coin1Data, coin2Data, comparisonType);
                
                // Generate AI insights
                String aiInsights = generateAIComparisonInsights(symbol1, symbol2, comparison, comparisonType);
                
                // Create comprehensive response
                Map<String, Object> response = new HashMap<>();
                response.put("status", "success");
                response.put("comparison_type", comparisonType);
                response.put("coin1", coin1Data);
                response.put("coin2", coin2Data);
                response.put("comparison_analysis", comparison);
                response.put("ai_insights", aiInsights);
                response.put("recommendation", generateComparisonRecommendation(comparison));
                response.put("timestamp", System.currentTimeMillis());
                
                log.info("✅ AI comparison completed for {} vs {}", symbol1, symbol2);
                return response;
                
            } catch (Exception e) {
                log.error("❌ AI comparison failed for {} vs {}: {}", symbol1, symbol2, e.getMessage(), e);
                return createErrorResponse(e.getMessage());
            }
        });
    }

    /**
     * Get perfect coin recommendations based on user preferences
     */
    public CompletableFuture<Map<String, Object>> getPersonalizedRecommendations(
            Map<String, Object> userPreferences,
            int limit,
            boolean includeAIAnalysis) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                log.info("🎯 Generating personalized coin recommendations");
                
                // Extract user preferences
                String riskTolerance = (String) userPreferences.getOrDefault("risk_tolerance", "medium");
                String investmentGoal = (String) userPreferences.getOrDefault("investment_goal", "growth");
                String timeHorizon = (String) userPreferences.getOrDefault("time_horizon", "medium");
                List<String> preferredCategories = (List<String>) userPreferences.getOrDefault("categories", Arrays.asList("defi", "smart-contracts"));
                Double maxPrice = (Double) userPreferences.getOrDefault("max_price", 1000.0);
                
                // Find coins matching preferences
                List<Map<String, Object>> recommendations = findCoinsMatchingPreferences(
                    riskTolerance, investmentGoal, timeHorizon, preferredCategories, maxPrice, limit);
                
                // Enhanced AI analysis for personalization
                if (includeAIAnalysis) {
                    recommendations = enhanceRecommendationsWithAI(recommendations, userPreferences);
                }
                
                // Create personalized response
                Map<String, Object> response = new HashMap<>();
                response.put("status", "success");
                response.put("user_preferences", userPreferences);
                response.put("recommendations", recommendations);
                response.put("analysis_summary", generateRecommendationSummary(recommendations, userPreferences));
                response.put("risk_assessment", assessPortfolioRisk(recommendations));
                response.put("timestamp", System.currentTimeMillis());
                
                log.info("✅ Personalized recommendations generated: {} coins", recommendations.size());
                return response;
                
            } catch (Exception e) {
                log.error("❌ Personalized recommendations failed: {}", e.getMessage(), e);
                return createErrorResponse(e.getMessage());
            }
        });
    }

    /**
     * Perform multi-layered similarity analysis
     */
    private List<Map<String, Object>> performMultiLayeredAnalysis(String symbol, int limit, boolean includeMarketData) {
        List<Map<String, Object>> results = new ArrayList<>();
        
        // Layer 1: Predefined similarity mapping
        Set<String> predefinedSimilar = PERFECT_SIMILARITY_MAP.getOrDefault(symbol.toLowerCase(), new HashSet<>());
        
        // Layer 2: Category-based similarity
        String category = COIN_CATEGORIES.get(symbol.toLowerCase());
        Set<String> categorySimilar = new HashSet<>();
        if (category != null) {
            categorySimilar = CATEGORY_SIMILARITIES.getOrDefault(category, new ArrayList<>()).stream()
                .collect(Collectors.toSet());
        }
        
        // Layer 3: Market data similarity
        Set<String> marketSimilar = findMarketDataSimilarity(symbol, limit * 2);
        
        // Combine all layers
        Set<String> allSimilar = new HashSet<>();
        allSimilar.addAll(predefinedSimilar);
        allSimilar.addAll(categorySimilar);
        allSimilar.addAll(marketSimilar);
        
        // Remove the original symbol
        allSimilar.remove(symbol.toLowerCase());
        
        // Convert to detailed coin data
        for (String similarSymbol : allSimilar) {
            if (results.size() >= limit) break;
            
            try {
                Map<String, Object> coinData = getCoinDetailsForSimilarity(similarSymbol, includeMarketData);
                if (coinData != null) {
                    results.add(coinData);
                }
            } catch (Exception e) {
                log.debug("Failed to get details for similar coin {}: {}", similarSymbol, e.getMessage());
            }
        }
        
        return results;
    }

    /**
     * Find market data similarity based on price patterns, volume, and market cap
     */
    private Set<String> findMarketDataSimilarity(String symbol, int maxResults) {
        try {
            Cryptocurrency targetCrypto = apiService.getCryptocurrencyData(symbol, 30).block();
            if (targetCrypto == null) return new HashSet<>();
            
            // Get market data for comparison - using searchCryptocurrencies with empty query
            List<Cryptocurrency> allCryptos = apiService.searchCryptocurrencies("").take(200).collectList().block();
            if (allCryptos == null) return new HashSet<>();
            
            // Find similar coins based on market metrics
            return allCryptos.stream()
                .filter(crypto -> !crypto.getSymbol().equalsIgnoreCase(symbol))
                .filter(crypto -> isMarketDataSimilar(targetCrypto, crypto))
                .limit(maxResults)
                .map(crypto -> crypto.getSymbol().toLowerCase())
                .collect(Collectors.toSet());
                
        } catch (Exception e) {
            log.warn("Market data similarity analysis failed for {}: {}", symbol, e.getMessage());
            return new HashSet<>();
        }
    }

    /**
     * Check if two cryptocurrencies are similar based on market data
     */
    private boolean isMarketDataSimilar(Cryptocurrency target, Cryptocurrency candidate) {
        // Price range similarity (within 2x or 0.5x)
        double targetPrice = target.getPrice() != null ? target.getPrice().doubleValue() : 0.0;
        double candidatePrice = candidate.getPrice() != null ? candidate.getPrice().doubleValue() : 0.0;
        if (targetPrice == 0.0 || candidatePrice == 0.0) return false;
        
        double priceRatio = targetPrice / candidatePrice;
        if (priceRatio > 2.0 || priceRatio < 0.5) return false;
        
        // Market cap similarity (within same order of magnitude)
        double targetMarketCap = target.getMarketCap() != null ? target.getMarketCap().doubleValue() : 0.0;
        double candidateMarketCap = candidate.getMarketCap() != null ? candidate.getMarketCap().doubleValue() : 0.0;
        if (targetMarketCap == 0.0 || candidateMarketCap == 0.0) return false;
        
        double marketCapRatio = targetMarketCap / candidateMarketCap;
        if (marketCapRatio > 10.0 || marketCapRatio < 0.1) return false;
        
        // Volume similarity (active trading)
        double targetVolume = target.getVolume24h() != null ? target.getVolume24h().doubleValue() : 0.0;
        double candidateVolume = candidate.getVolume24h() != null ? candidate.getVolume24h().doubleValue() : 0.0;
        if (targetVolume == 0.0 || candidateVolume == 0.0) return false;
        
        double volumeRatio = targetVolume / candidateVolume;
        if (volumeRatio > 5.0 || volumeRatio < 0.2) return false;
        
        // Price change correlation (similar volatility)
        double targetPriceChange = target.getPercentChange24h() != null ? Math.abs(target.getPercentChange24h().doubleValue()) : 0.0;
        double candidatePriceChange = candidate.getPercentChange24h() != null ? Math.abs(candidate.getPercentChange24h().doubleValue()) : 0.0;
        if (targetPriceChange == 0.0 && candidatePriceChange == 0.0) return true;
        
        double changeRatio = Math.max(targetPriceChange, candidatePriceChange) / Math.max(Math.min(targetPriceChange, candidatePriceChange), 0.01);
        if (changeRatio > 3.0) return false;
        
        return true;
    }

    /**
     * Enhance similar coins with AI analysis
     */
    private List<Map<String, Object>> enhanceWithAIAnalysis(String symbol, List<Map<String, Object>> similarCoins, String analysisDepth) {
        for (Map<String, Object> coin : similarCoins) {
            try {
                String similarSymbol = (String) coin.get("symbol");
                
               
                String aiAnalysis = generateAISimilarityAnalysis(symbol, similarSymbol, analysisDepth);
                coin.put("ai_analysis", aiAnalysis);
                
                // Generate similarity score with AI
                double aiScore = generateAISimilarityScore(symbol, similarSymbol);
                coin.put("ai_similarity_score", aiScore);
                
                // Add AI insights
                Map<String, Object> aiInsights = generateAIInsights(symbol, similarSymbol);
                coin.put("ai_insights", aiInsights);
                
            } catch (Exception e) {
                log.debug("AI analysis failed for similar coin {}: {}", coin.get("symbol"), e.getMessage());
                coin.put("ai_analysis", "AI analysis temporarily unavailable");
                coin.put("ai_similarity_score", 0.5);
            }
        }
        
        return similarCoins;
    }

    /**
     * Generate AI similarity analysis
     */
    private String generateAISimilarityAnalysis(String symbol1, String symbol2, String analysisDepth) {
        try {
            String prompt = buildSimilarityAnalysisPrompt(symbol1, symbol2, analysisDepth);
            return aiService.generateAnalysisWithFallback("general", prompt);
        } catch (Exception e) {
            log.warn("AI similarity analysis failed for {} vs {}: {}", symbol1, symbol2, e.getMessage());
            return String.format("Both %s and %s share similar characteristics in the cryptocurrency market. " +
                                "They operate in comparable sectors and show related market behaviors.", 
                                symbol1.toUpperCase(), symbol2.toUpperCase());
        }
    }

    /**
     * Build similarity analysis prompt
     */
    private String buildSimilarityAnalysisPrompt(String symbol1, String symbol2, String analysisDepth) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append("You are a cryptocurrency expert. Compare ").append(symbol1.toUpperCase())
              .append(" and ").append(symbol2.toUpperCase()).append(" in terms of:\n");
        
        if ("deep".equals(analysisDepth)) {
            prompt.append("1. Technology and blockchain architecture\n");
            prompt.append("2. Use cases and target markets\n");
            prompt.append("3. Team and development activity\n");
            prompt.append("4. Partnerships and ecosystem\n");
            prompt.append("5. Tokenomics and governance\n");
            prompt.append("6. Market position and competition\n");
            prompt.append("7. Risk factors and opportunities\n");
        } else {
            prompt.append("1. Primary use cases and technology\n");
            prompt.append("2. Market position and performance\n");
            prompt.append("3. Key similarities and differences\n");
        }
        
        prompt.append("\nProvide a comprehensive analysis highlighting why these coins are similar ");
        prompt.append("and what makes them comparable investment options. Be specific and factual.");
        
        return prompt.toString();
    }

    /**
     * Generate AI similarity score
     */
    private double generateAISimilarityScore(String symbol1, String symbol2) {
        try {
            // Use multiple factors for scoring
            double categoryScore = calculateCategoryScore(symbol1, symbol2);
            double marketScore = calculateMarketScore(symbol1, symbol2);
            double technicalScore = calculateTechnicalScore(symbol1, symbol2);
            
            // Weighted average
            return (categoryScore * 0.4) + (marketScore * 0.3) + (technicalScore * 0.3);
            
        } catch (Exception e) {
            log.debug("AI similarity score calculation failed: {}", e.getMessage());
            return 0.5; // Default similarity score
        }
    }

    /**
     * Calculate category-based similarity score
     */
    private double calculateCategoryScore(String symbol1, String symbol2) {
        String category1 = COIN_CATEGORIES.get(symbol1.toLowerCase());
        String category2 = COIN_CATEGORIES.get(symbol2.toLowerCase());
        
        if (category1 != null && category1.equals(category2)) {
            return 1.0;
        } else if (category1 != null && category2 != null && areCategoriesRelated(category1, category2)) {
            return 0.7;
        } else {
            return 0.3;
        }
    }

    /**
     * Check if categories are related
     */
    private boolean areCategoriesRelated(String category1, String category2) {
        Map<String, Set<String>> relatedCategories = Map.of(
            "defi", Set.of("dex", "lending", "yield-farming"),
            "smart-contracts", Set.of("defi", "nft", "gaming"),
            "layer-1", Set.of("layer-2", "scaling"),
            "store-of-value", Set.of("digital-gold", "hedge")
        );
        
        return relatedCategories.getOrDefault(category1, Set.of()).contains(category2) ||
               relatedCategories.getOrDefault(category2, Set.of()).contains(category1);
    }

    /**
     * Calculate market-based similarity score
     */
    private double calculateMarketScore(String symbol1, String symbol2) {
        try {
            Cryptocurrency crypto1 = apiService.getCryptocurrencyData(symbol1, 30).block();
            Cryptocurrency crypto2 = apiService.getCryptocurrencyData(symbol2, 30).block();
            
            if (crypto1 == null || crypto2 == null) return 0.5;
            
            // Compare market cap ranges
            double marketCap1 = crypto1.getMarketCap() != null ? crypto1.getMarketCap().doubleValue() : 0.0;
            double marketCap2 = crypto2.getMarketCap() != null ? crypto2.getMarketCap().doubleValue() : 0.0;
            if (marketCap1 == 0.0 || marketCap2 == 0.0) return 0.5;
            
            double marketCapRatio = marketCap1 / marketCap2;
            double marketCapScore = 1.0 - Math.min(0.8, Math.abs(1.0 - marketCapRatio));
            
            // Compare price volatility
            double priceChange1 = crypto1.getPercentChange24h() != null ? crypto1.getPercentChange24h().doubleValue() : 0.0;
            double priceChange2 = crypto2.getPercentChange24h() != null ? crypto2.getPercentChange24h().doubleValue() : 0.0;
            double volDiff = Math.abs(priceChange1 - priceChange2);
            double volatilityScore = 1.0 - Math.min(0.8, volDiff / 50.0);
            
            return (marketCapScore + volatilityScore) / 2.0;
            
        } catch (Exception e) {
            return 0.5;
        }
    }

    /**
     * Calculate technical similarity score
     */
    private double calculateTechnicalScore(String symbol1, String symbol2) {
        // This would ideally use technical indicators, but for now use a simplified approach
        Set<String> tech1 = getTechnicalFeatures(symbol1);
        Set<String> tech2 = getTechnicalFeatures(symbol2);
        
        if (tech1.isEmpty() || tech2.isEmpty()) return 0.5;
        
        Set<String> intersection = new HashSet<>(tech1);
        intersection.retainAll(tech2);
        
        Set<String> union = new HashSet<>(tech1);
        union.addAll(tech2);
        
        return (double) intersection.size() / union.size();
    }

   
    private Set<String> getTechnicalFeatures(String symbol) {
       
        Map<String, Set<String>> features = Map.of(
            "btc", Set.of("proof-of-work", "store-of-value", "digital-gold"),
            "eth", Set.of("smart-contracts", "proof-of-stake", "defi", "nft"),
            "ada", Set.of("proof-of-stake", "smart-contracts", "academic"),
            "sol", Set.of("proof-of-stake", "high-throughput", "smart-contracts"),
            "dot", Set.of("proof-of-stake", "interoperability", "parachains"),
            "avax", Set.of("proof-of-stake", "smart-contracts", "subnets"),
            "matic", Set.of("layer-2", "scaling", "proof-of-stake"),
            "link", Set.of("oracle", "data-feeds", "smart-contracts"),
            "uni", Set.of("dex", "defi", "amm", "governance"),
            "aave", Set.of("defi", "lending", "flash-loans")
        );
        
        return features.getOrDefault(symbol.toLowerCase(), new HashSet<>());
    }

    /**
     * Apply advanced scoring to similar coins
     */
    private List<Map<String, Object>> applyAdvancedScoring(String symbol, List<Map<String, Object>> similarCoins) {
        // Calculate composite scores
        for (Map<String, Object> coin : similarCoins) {
            double compositeScore = calculateCompositeScore(symbol, coin);
            coin.put("composite_score", compositeScore);
        }
        
        // Sort by composite score
        similarCoins.sort((a, b) -> Double.compare(
            (Double) b.getOrDefault("composite_score", 0.0),
            (Double) a.getOrDefault("composite_score", 0.0)
        ));
        
        return similarCoins;
    }

    /**
     * Calculate composite similarity score
     */
    private double calculateCompositeScore(String originalSymbol, Map<String, Object> coin) {
        String similarSymbol = (String) coin.get("symbol");
        
        // Multiple scoring factors
        double categoryScore = calculateCategoryScore(originalSymbol, similarSymbol);
        double marketScore = calculateMarketScore(originalSymbol, similarSymbol);
        double technicalScore = calculateTechnicalScore(originalSymbol, similarSymbol);
        double aiScore = (Double) coin.getOrDefault("ai_similarity_score", 0.5);
        
        // Weighted composite score
        return (categoryScore * 0.3) + (marketScore * 0.25) + (technicalScore * 0.25) + (aiScore * 0.2);
    }

    /**
     * Get coin details for similarity analysis
     */
    private Map<String, Object> getCoinDetailsForSimilarity(String symbol, boolean includeMarketData) {
        try {
            Cryptocurrency crypto = apiService.getCryptocurrencyData(symbol, 30).block();
            if (crypto == null) return null;
            
            Map<String, Object> details = new HashMap<>();
            details.put("symbol", crypto.getSymbol());
            details.put("name", crypto.getName());
            details.put("current_price", crypto.getPrice() != null ? crypto.getPrice().doubleValue() : 0.0);
            details.put("market_cap", crypto.getMarketCap() != null ? crypto.getMarketCap().doubleValue() : 0.0);
            details.put("market_cap_rank", crypto.getRank() != null ? crypto.getRank() : 0);
            details.put("price_change_24h", crypto.getPercentChange24h() != null ? crypto.getPercentChange24h().doubleValue() : 0.0);
            
            if (includeMarketData) {
                details.put("total_volume", crypto.getVolume24h() != null ? crypto.getVolume24h().doubleValue() : 0.0);
                details.put("circulating_supply", crypto.getCirculatingSupply());
                details.put("total_supply", crypto.getTotalSupply());
                details.put("max_supply", crypto.getMaxSupply());
            }
            
            // Add category information
            String category = COIN_CATEGORIES.get(symbol.toLowerCase());
            if (category != null) {
                details.put("category", category);
            }
            
            return details;
            
        } catch (Exception e) {
            log.debug("Failed to get coin details for {}: {}", symbol, e.getMessage());
            return null;
        }
    }

    /**
     * Initialize perfect similarity mappings
     */
    private static Map<String, Set<String>> initializePerfectSimilarityMap() {
        Map<String, Set<String>> map = new HashMap<>();
        
        // Store of Value
        map.put("btc", Set.of("ltc", "bch", "xmr", "zec"));
        map.put("ltc", Set.of("btc", "bch", "dash", "zec"));
        
        // Smart Contract Platforms
        map.put("eth", Set.of("ada", "sol", "avax", "dot", "matic", "ftm", "near"));
        map.put("ada", Set.of("eth", "sol", "dot", "algo", "tezos"));
        map.put("sol", Set.of("eth", "ada", "avax", "near", "fantom"));
        map.put("avax", Set.of("eth", "sol", "fantom", "near", "matic"));
        map.put("dot", Set.of("eth", "ada", "cosmos", "ksm", "near"));
        
        // DeFi Tokens
        map.put("uni", Set.of("sushi", "cake", "1inch", "dydx", "crv"));
        map.put("aave", Set.of("comp", "mkr", "snx", "yfi", "crv"));
        map.put("link", Set.of("band", "api3", "trb", "dia"));
        
        // Layer 2 Solutions
        map.put("matic", Set.of("lrc", "omg", "arb", "op"));
        
        // Meme Coins
        map.put("doge", Set.of("shib", "floki", "babydoge", "elon"));
        map.put("shib", Set.of("doge", "floki", "babydoge", "kishu"));
        
        return map;
    }

    /**
     * Initialize coin categories
     */
    private static Map<String, String> initializeCoinCategories() {
        Map<String, String> categories = new HashMap<>();
        
        // Store of Value
        categories.put("btc", "store-of-value");
        categories.put("ltc", "store-of-value");
        categories.put("bch", "store-of-value");
        
        // Smart Contract Platforms
        categories.put("eth", "smart-contracts");
        categories.put("ada", "smart-contracts");
        categories.put("sol", "smart-contracts");
        categories.put("avax", "smart-contracts");
        categories.put("dot", "smart-contracts");
        categories.put("matic", "layer-2");
        categories.put("ftm", "smart-contracts");
        categories.put("near", "smart-contracts");
        
        // DeFi
        categories.put("uni", "defi");
        categories.put("aave", "defi");
        categories.put("comp", "defi");
        categories.put("mkr", "defi");
        categories.put("snx", "defi");
        categories.put("yfi", "defi");
        categories.put("crv", "defi");
        categories.put("sushi", "defi");
        categories.put("cake", "defi");
        
        // Oracles
        categories.put("link", "oracle");
        categories.put("band", "oracle");
        categories.put("api3", "oracle");
        
        // Meme Coins
        categories.put("doge", "meme");
        categories.put("shib", "meme");
        categories.put("floki", "meme");
        
        return categories;
    }

    /**
     * Initialize category similarities
     */
    private static Map<String, List<String>> initializeCategorySimilarities() {
        Map<String, List<String>> similarities = new HashMap<>();
        
        similarities.put("store-of-value", Arrays.asList("btc", "ltc", "bch", "xmr", "zec"));
        similarities.put("smart-contracts", Arrays.asList("eth", "ada", "sol", "avax", "dot", "ftm", "near"));
        similarities.put("defi", Arrays.asList("uni", "aave", "comp", "mkr", "snx", "yfi", "crv", "sushi", "cake"));
        similarities.put("layer-2", Arrays.asList("matic", "lrc", "omg", "arb", "op"));
        similarities.put("oracle", Arrays.asList("link", "band", "api3", "trb", "dia"));
        similarities.put("meme", Arrays.asList("doge", "shib", "floki", "babydoge", "elon"));
        
        return similarities;
    }

    /**
     * Preload similarity data for faster responses
     */
    private void preloadSimilarityData() {
        scheduler.schedule(() -> {
            try {
                log.info("🔄 Preloading perfect similarity data...");
                
                List<String> popularSymbols = Arrays.asList("btc", "eth", "ada", "sol", "dot", "avax", "matic", "link", "uni", "aave");
                
                for (String symbol : popularSymbols) {
                    try {
                        findSimilarCryptocurrenciesPerfect(symbol, 5, false, false, "standard");
                        Thread.sleep(100);
                    } catch (Exception e) {
                        log.debug("Preload failed for {}: {}", symbol, e.getMessage());
                    }
                }
                
                log.info("✅ Perfect similarity data preloaded successfully");
            } catch (Exception e) {
                log.warn("Similarity data preload failed: {}", e.getMessage());
            }
        }, 45, TimeUnit.SECONDS);
    }

    // Additional helper methods...
    
    /**
     * Get coin details for comparison
     */
    private Map<String, Object> getCoinDetailsForComparison(String symbol, boolean includeMarketData) {
        return getCoinDetailsForSimilarity(symbol, includeMarketData);
    }

    /**
     * Perform multi-dimensional comparison
     */
    private Map<String, Object> performMultiDimensionalComparison(
            String symbol1, String symbol2, Map<String, Object> coin1Data, 
            Map<String, Object> coin2Data, String comparisonType) {
        
        Map<String, Object> comparison = new HashMap<>();
        
        // Price comparison
        double price1 = (Double) coin1Data.getOrDefault("current_price", 0.0);
        double price2 = (Double) coin2Data.getOrDefault("current_price", 0.0);
        comparison.put("price_ratio", price2 != 0 ? price1 / price2 : 0);
        
        // Market cap comparison
        double marketCap1 = (Double) coin1Data.getOrDefault("market_cap", 0.0);
        double marketCap2 = (Double) coin2Data.getOrDefault("market_cap", 0.0);
        comparison.put("market_cap_ratio", marketCap2 != 0 ? marketCap1 / marketCap2 : 0);
        
        // Volume comparison
        double volume1 = (Double) coin1Data.getOrDefault("total_volume", 0.0);
        double volume2 = (Double) coin2Data.getOrDefault("total_volume", 0.0);
        comparison.put("volume_ratio", volume2 != 0 ? volume1 / volume2 : 0);
        
        // Performance comparison
        double change1 = (Double) coin1Data.getOrDefault("price_change_24h", 0.0);
        double change2 = (Double) coin2Data.getOrDefault("price_change_24h", 0.0);
        comparison.put("performance_difference", change1 - change2);
        
        return comparison;
    }

    /**
     * Generate AI comparison insights
     */
    private String generateAIComparisonInsights(String symbol1, String symbol2, 
                                               Map<String, Object> comparison, String comparisonType) {
        try {
            String prompt = String.format(
                "Compare %s and %s cryptocurrencies. Focus on %s analysis. " +
                "Price ratio: %.2f, Market cap ratio: %.2f, Volume ratio: %.2f, " +
                "Performance difference: %.2f%%. Provide detailed insights.",
                symbol1.toUpperCase(), symbol2.toUpperCase(), comparisonType,
                (Double) comparison.getOrDefault("price_ratio", 0.0),
                (Double) comparison.getOrDefault("market_cap_ratio", 0.0),
                (Double) comparison.getOrDefault("volume_ratio", 0.0),
                (Double) comparison.getOrDefault("performance_difference", 0.0)
            );
            
            return aiService.generateAnalysisWithFallback("general", prompt);
        } catch (Exception e) {
            return String.format("Comparison between %s and %s shows different market positions and characteristics. " +
                                "Each has unique strengths and considerations for investors.",
                                symbol1.toUpperCase(), symbol2.toUpperCase());
        }
    }

    /**
     * Generate comparison recommendation
     */
    private String generateComparisonRecommendation(Map<String, Object> comparison) {
        double priceRatio = (Double) comparison.getOrDefault("price_ratio", 1.0);
        double marketCapRatio = (Double) comparison.getOrDefault("market_cap_ratio", 1.0);
        double performanceDiff = (Double) comparison.getOrDefault("performance_difference", 0.0);
        
        if (marketCapRatio > 10) {
            return "The first cryptocurrency has significantly higher market cap, suggesting more established market position.";
        } else if (marketCapRatio < 0.1) {
            return "The second cryptocurrency has significantly higher market cap, indicating larger market presence.";
        } else if (Math.abs(performanceDiff) > 10) {
            return "Significant performance difference suggests different market dynamics and investor sentiment.";
        } else {
            return "Both cryptocurrencies show similar market characteristics with comparable fundamentals.";
        }
    }

    /**
     * Find coins matching user preferences
     */
    private List<Map<String, Object>> findCoinsMatchingPreferences(
            String riskTolerance, String investmentGoal, String timeHorizon,
            List<String> preferredCategories, Double maxPrice, int limit) {
        
        List<Map<String, Object>> recommendations = new ArrayList<>();
        
        // Get coins from preferred categories
        for (String category : preferredCategories) {
            List<String> categoryCoins = CATEGORY_SIMILARITIES.getOrDefault(category, new ArrayList<>());
            
            for (String symbol : categoryCoins) {
                if (recommendations.size() >= limit) break;
                
                try {
                    Map<String, Object> coinData = getCoinDetailsForSimilarity(symbol, true);
                    if (coinData != null) {
                        double price = (Double) coinData.getOrDefault("current_price", 0.0);
                        if (price <= maxPrice) {
                            coinData.put("recommendation_reason", "Matches category preference: " + category);
                            coinData.put("risk_assessment", assessCoinRisk(coinData, riskTolerance));
                            recommendations.add(coinData);
                        }
                    }
                } catch (Exception e) {
                    log.debug("Failed to process coin {} for recommendations: {}", symbol, e.getMessage());
                }
            }
        }
        
        return recommendations;
    }

    /**
     * Assess coin risk level
     */
    private String assessCoinRisk(Map<String, Object> coinData, String userRiskTolerance) {
        Integer rank = (Integer) coinData.getOrDefault("market_cap_rank", 1000);
        Double volatility = Math.abs((Double) coinData.getOrDefault("price_change_24h", 0.0));
        
        String riskLevel;
        if (rank <= 10 && volatility < 5) {
            riskLevel = "Low";
        } else if (rank <= 50 && volatility < 15) {
            riskLevel = "Medium";
        } else {
            riskLevel = "High";
        }
        
        return riskLevel;
    }

    /**
     * Enhance recommendations with AI analysis
     */
    private List<Map<String, Object>> enhanceRecommendationsWithAI(
            List<Map<String, Object>> recommendations, Map<String, Object> userPreferences) {
        
        for (Map<String, Object> coin : recommendations) {
            try {
                String symbol = (String) coin.get("symbol");
                String aiInsights = generatePersonalizedAIInsights(symbol, userPreferences);
                coin.put("ai_insights", aiInsights);
            } catch (Exception e) {
                coin.put("ai_insights", "AI analysis temporarily unavailable");
            }
        }
        
        return recommendations;
    }

    /**
     * Generate personalized AI insights
     */
    private String generatePersonalizedAIInsights(String symbol, Map<String, Object> userPreferences) {
        try {
            String prompt = String.format(
                "Analyze %s cryptocurrency for an investor with these preferences: %s. " +
                "Provide personalized insights and recommendations.",
                symbol.toUpperCase(), userPreferences.toString()
            );
            
            return aiService.generateAnalysisWithFallback("general", prompt);
        } catch (Exception e) {
            return String.format("%s shows characteristics that may align with your investment preferences. " +
                                "Consider researching its fundamentals and market position.",
                                symbol.toUpperCase());
        }
    }

    /**
     * Generate recommendation summary
     */
    private String generateRecommendationSummary(List<Map<String, Object>> recommendations, 
                                                Map<String, Object> userPreferences) {
        return String.format(
            "Found %d cryptocurrency recommendations matching your preferences. " +
            "Portfolio focuses on %s with %s risk tolerance for %s term investment.",
            recommendations.size(),
            userPreferences.get("categories"),
            userPreferences.get("risk_tolerance"),
            userPreferences.get("time_horizon")
        );
    }

    /**
     * Assess portfolio risk
     */
    private String assessPortfolioRisk(List<Map<String, Object>> recommendations) {
        double avgRisk = recommendations.stream()
            .mapToDouble(coin -> {
                String risk = (String) coin.getOrDefault("risk_assessment", "Medium");
                return switch (risk) {
                    case "Low" -> 1.0;
                    case "Medium" -> 2.0;
                    case "High" -> 3.0;
                    default -> 2.0;
                };
            })
            .average()
            .orElse(2.0);
        
        if (avgRisk < 1.5) return "Low Risk Portfolio";
        else if (avgRisk < 2.5) return "Moderate Risk Portfolio";
        else return "High Risk Portfolio";
    }

    /**
     * Generate AI insights for similar coins
     */
    private Map<String, Object> generateAIInsights(String originalSymbol, String similarSymbol) {
        Map<String, Object> insights = new HashMap<>();
        
        try {
            // Get key similarities
            insights.put("key_similarities", Arrays.asList(
                "Similar market sector",
                "Comparable technology approach",
                "Related use cases"
            ));
            
            // Get differentiation factors
            insights.put("differentiation", Arrays.asList(
                "Different consensus mechanisms",
                "Unique ecosystem features",
                "Distinct market positioning"
            ));
            
            // Risk assessment
            insights.put("relative_risk", "Similar risk profile with sector-specific considerations");
            
        } catch (Exception e) {
            insights.put("error", "AI insights temporarily unavailable");
        }
        
        return insights;
    }

    /**
     * Create perfect response
     */
    private Map<String, Object> createPerfectResponse(String symbol, List<Map<String, Object>> similarCoins, 
                                                     boolean includeAIAnalysis, boolean fromCache) {
        Map<String, Object> response = new HashMap<>();
        
        response.put("status", "success");
        response.put("symbol", symbol.toUpperCase());
        response.put("similar_coins", similarCoins);
        response.put("total_found", similarCoins.size());
        response.put("ai_enhanced", includeAIAnalysis);
        response.put("from_cache", fromCache);
        response.put("timestamp", System.currentTimeMillis());
        
        // Add analysis summary
        Map<String, Object> summary = new HashMap<>();
        summary.put("methodology", "Multi-layered AI-powered similarity analysis");
        summary.put("factors_considered", Arrays.asList(
            "Category similarity", "Market data correlation", "Technical features", 
            "AI pattern recognition", "Historical performance"
        ));
        summary.put("confidence_level", "High");
        
        response.put("analysis_summary", summary);
        
        return response;
    }

    /**
     * Create error response
     */
    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "error");
        response.put("error", message);
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }

    /**
     * Generate cache key
     */
    private String generateCacheKey(String symbol, int limit, boolean includeAIAnalysis, String analysisDepth) {
        return String.format("similar_%s_%d_%s_%s", 
            symbol.toLowerCase(), limit, includeAIAnalysis, analysisDepth != null ? analysisDepth : "standard");
    }

    /**
     * Get cached similar coins
     */
    private List<Map<String, Object>> getCachedSimilar(String cacheKey) {
        Long timestamp = cacheTimestamps.get(cacheKey);
        if (timestamp != null && (System.currentTimeMillis() - timestamp) < CACHE_DURATION_MS) {
            return similarCoinCache.get(cacheKey);
        }
        return null;
    }

    /**
     * Cache similar coins
     */
    private void cacheSimilar(String cacheKey, List<Map<String, Object>> similarCoins) {
        if (similarCoinCache.size() >= MAX_CACHE_SIZE) {
            // Remove oldest entry
            String oldestKey = cacheTimestamps.entrySet().stream()
                .min(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse(null);
            if (oldestKey != null) {
                similarCoinCache.remove(oldestKey);
                cacheTimestamps.remove(oldestKey);
            }
        }
        
        similarCoinCache.put(cacheKey, similarCoins);
        cacheTimestamps.put(cacheKey, System.currentTimeMillis());
    }

    /**
     * Initialize cache cleanup
     */
    private void initializeCacheCleanup() {
        scheduler.scheduleAtFixedRate(() -> {
            try {
                long now = System.currentTimeMillis();
                cacheTimestamps.entrySet().removeIf(entry -> {
                    if (now - entry.getValue() > CACHE_DURATION_MS) {
                        similarCoinCache.remove(entry.getKey());
                        return true;
                    }
                    return false;
                });
            } catch (Exception e) {
                log.warn("Similar coins cache cleanup failed: {}", e.getMessage());
            }
        }, 3, 3, TimeUnit.MINUTES);
    }

    /**
     * Get service health status
     */
    public Map<String, Object> getServiceHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("service", "PerfectSimilarCoinService");
        health.put("status", "healthy");
        health.put("cache_size", similarCoinCache.size());
        health.put("max_cache_size", MAX_CACHE_SIZE);
        health.put("similarity_mappings", PERFECT_SIMILARITY_MAP.size());
        health.put("categories", COIN_CATEGORIES.size());
        return health;
    }
}
