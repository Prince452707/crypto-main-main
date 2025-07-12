package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Enhanced Similar Coin Recommendation Service with AI-powered analysis
 */
@Slf4j
@Service
public class EnhancedSimilarCoinService {

    private final AIService aiService;
    private final ApiService apiService;
    private final Map<String, List<Map<String, Object>>> similarCoinCache = new ConcurrentHashMap<>();
    private final Map<String, Long> cacheTimestamps = new ConcurrentHashMap<>();
    
    private static final long CACHE_DURATION_MS = 10 * 60 * 1000; // 10 minutes
    private static final Map<String, List<String>> ENHANCED_SIMILARITY_MAP = initializeSimilarityMap();

    public EnhancedSimilarCoinService(AIService aiService, ApiService apiService) {
        this.aiService = aiService;
        this.apiService = apiService;
    }

    /**
     * Find similar cryptocurrencies with enhanced AI analysis
     */
    public CompletableFuture<Map<String, Object>> findSimilarCryptocurrenciesEnhanced(
            String symbol, 
            int limit, 
            boolean includeAnalysis,
            boolean includeMarketData) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                log.info("Finding enhanced similar cryptocurrencies for: {}", symbol);
                
                // Check cache first
                String cacheKey = generateCacheKey(symbol, limit, includeAnalysis);
                List<Map<String, Object>> cachedSimilar = getCachedSimilar(cacheKey);
                if (cachedSimilar != null) {
                    log.debug("Using cached similar coins for {}", symbol);
                    return createSuccessResponse(symbol, cachedSimilar, includeAnalysis, true);
                }
                
                // Get enhanced similar coins
                List<Map<String, Object>> similarCoins = getEnhancedSimilarCoins(symbol, limit, includeMarketData);
                
                // Cache the result
                cacheSimilarCoins(cacheKey, similarCoins);
                
                // Generate AI analysis if requested
                String aiAnalysis = null;
                if (includeAnalysis) {
                    aiAnalysis = generateSimilarityAnalysis(symbol, similarCoins);
                }
                
                return createSuccessResponse(symbol, similarCoins, aiAnalysis, includeAnalysis, false);
                
            } catch (Exception e) {
                log.error("Enhanced similar coin search failed for {}: {}", symbol, e.getMessage());
                return createErrorResponse(symbol, e.getMessage());
            }
        });
    }

    /**
     * Get similar coins with enhanced scoring and market data
     */
    private List<Map<String, Object>> getEnhancedSimilarCoins(String symbol, int limit, boolean includeMarketData) {
        List<Map<String, Object>> similarCoins = new ArrayList<>();
        
        // Get base similar coins from enhanced mapping
        List<String> similarSymbols = getEnhancedSimilarSymbols(symbol, limit * 2); // Get more for filtering
        
        // Score and rank similar coins
        List<ScoredCoin> scoredCoins = new ArrayList<>();
        for (String similarSymbol : similarSymbols) {
            if (!similarSymbol.equalsIgnoreCase(symbol)) {
                double score = calculateSimilarityScore(symbol, similarSymbol);
                scoredCoins.add(new ScoredCoin(similarSymbol, score));
            }
        }
        
        // Sort by score and take top results
        scoredCoins.sort((a, b) -> Double.compare(b.getScore(), a.getScore()));
        
        for (int i = 0; i < Math.min(limit, scoredCoins.size()); i++) {
            ScoredCoin scoredCoin = scoredCoins.get(i);
            Map<String, Object> coinData = createSimilarCoinData(
                symbol, 
                scoredCoin.getSymbol(), 
                scoredCoin.getScore(), 
                includeMarketData
            );
            similarCoins.add(coinData);
        }
        
        return similarCoins;
    }

    /**
     * Get enhanced similar symbols with multiple criteria
     */
    private List<String> getEnhancedSimilarSymbols(String symbol, int limit) {
        Set<String> allSimilar = new HashSet<>();
        
        // Add from enhanced mapping
        List<String> directSimilar = ENHANCED_SIMILARITY_MAP.getOrDefault(symbol.toUpperCase(), new ArrayList<>());
        allSimilar.addAll(directSimilar);
        
        // Add category-based similarities
        String category = identifyCategory(symbol);
        List<String> categorySimilar = getCategoryCoins(category);
        allSimilar.addAll(categorySimilar);
        
        // Add market cap based similarities
        List<String> marketCapSimilar = getMarketCapSimilar(symbol);
        allSimilar.addAll(marketCapSimilar);
        
        // Remove the original symbol
        allSimilar.remove(symbol.toUpperCase());
        
        return new ArrayList<>(allSimilar);
    }

    /**
     * Calculate enhanced similarity score
     */
    private double calculateSimilarityScore(String originalSymbol, String compareSymbol) {
        double score = 0.0;
        
        // Category similarity (40% weight)
        if (identifyCategory(originalSymbol).equals(identifyCategory(compareSymbol))) {
            score += 0.4;
        }
        
        // Market cap similarity (30% weight)
        score += calculateMarketCapSimilarity(originalSymbol, compareSymbol) * 0.3;
        
        // Direct mapping bonus (20% weight)
        if (isDirectMapping(originalSymbol, compareSymbol)) {
            score += 0.2;
        }
        
        // Use case similarity (10% weight)
        score += calculateUseCaseSimilarity(originalSymbol, compareSymbol) * 0.1;
        
        return Math.min(1.0, score);
    }

    /**
     * Create detailed similar coin data
     */
    private Map<String, Object> createSimilarCoinData(
            String originalSymbol, 
            String similarSymbol, 
            double score, 
            boolean includeMarketData) {
        
        Map<String, Object> coinData = new HashMap<>();
        coinData.put("symbol", similarSymbol);
        coinData.put("similarity_score", Math.round(score * 100.0) / 100.0);
        coinData.put("match_reasons", getEnhancedMatchReasons(originalSymbol, similarSymbol));
        coinData.put("category", identifyCategory(similarSymbol));
        coinData.put("risk_level", assessRiskLevel(similarSymbol));
        coinData.put("investment_type", getInvestmentType(similarSymbol));
        
        if (includeMarketData) {
            // Try to get market data - this would require async handling in real implementation
            coinData.put("market_data", getBasicMarketData(similarSymbol));
        }
        
        return coinData;
    }

    /**
     * Generate AI-powered similarity analysis
     */
    private String generateSimilarityAnalysis(String symbol, List<Map<String, Object>> similarCoins) {
        try {
            String prompt = buildSimilarityAnalysisPrompt(symbol, similarCoins);
            return aiService.generateAnalysisWithFallback("similarity_analysis", prompt);
        } catch (Exception e) {
            log.warn("AI similarity analysis failed for {}: {}", symbol, e.getMessage());
            return generateFallbackAnalysis(symbol, similarCoins);
        }
    }

    /**
     * Build detailed similarity analysis prompt
     */
    private String buildSimilarityAnalysisPrompt(String symbol, List<Map<String, Object>> similarCoins) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append("🔍 **CRYPTOCURRENCY SIMILARITY ANALYSIS EXPERT**\n");
        prompt.append("You are a professional cryptocurrency analyst specializing in comparative analysis.\n\n");
        
        prompt.append("**TARGET CRYPTOCURRENCY:** ").append(symbol.toUpperCase()).append("\n\n");
        
        prompt.append("**SIMILAR CRYPTOCURRENCIES IDENTIFIED:**\n");
        for (Map<String, Object> coin : similarCoins) {
            prompt.append("• ").append(coin.get("symbol")).append(" (Score: ").append(coin.get("similarity_score")).append(")\n");
            prompt.append("  - Category: ").append(coin.get("category")).append("\n");
            prompt.append("  - Risk Level: ").append(coin.get("risk_level")).append("\n");
            prompt.append("  - Match Reasons: ").append(coin.get("match_reasons")).append("\n\n");
        }
        
        prompt.append("**ANALYSIS REQUIREMENTS:**\n");
        prompt.append("1. Provide a comprehensive comparative analysis\n");
        prompt.append("2. Explain why these cryptocurrencies are similar to ").append(symbol.toUpperCase()).append("\n");
        prompt.append("3. Highlight key differentiating factors\n");
        prompt.append("4. Discuss investment considerations and risk factors\n");
        prompt.append("5. Provide educational insights about each category\n");
        prompt.append("6. Use emojis and formatting for better readability\n");
        prompt.append("7. Include appropriate disclaimers about investment risks\n\n");
        
        return prompt.toString();
    }

    /**
     * Enhanced similarity mapping initialization
     */
    private static Map<String, List<String>> initializeSimilarityMap() {
        Map<String, List<String>> map = new HashMap<>();
        
        // Major Layer 1 Blockchains
        map.put("BTC", Arrays.asList("ETH", "LTC", "BCH", "BSV", "DOGE", "XRP", "ADA", "SOL", "DOT", "AVAX"));
        map.put("ETH", Arrays.asList("BTC", "ADA", "SOL", "DOT", "AVAX", "MATIC", "BNB", "NEAR", "ALGO", "ATOM"));
        map.put("ADA", Arrays.asList("ETH", "DOT", "ALGO", "SOL", "AVAX", "NEAR", "ATOM", "FLOW", "TEZOS", "HEDERA"));
        map.put("SOL", Arrays.asList("ETH", "AVAX", "NEAR", "ALGO", "DOT", "FANTOM", "HARMONY", "TERRA", "APTOS", "SUI"));
        map.put("DOT", Arrays.asList("ADA", "ATOM", "KUSAMA", "AVAX", "NEAR", "ALGO", "TERRA", "OSMOSIS", "KAVA", "ACALA"));
        map.put("AVAX", Arrays.asList("SOL", "FANTOM", "NEAR", "HARMONY", "CELO", "MOONBEAM", "CRONOS", "AURORA", "EVMOS", "KAVA"));
        
        // Smart Contract Platforms
        map.put("BNB", Arrays.asList("ETH", "MATIC", "AVAX", "FANTOM", "CRONOS", "MOONBEAM", "HARMONY", "CELO", "KAVA", "EVMOS"));
        map.put("MATIC", Arrays.asList("BNB", "AVAX", "FANTOM", "HARMONY", "CRONOS", "MOONBEAM", "CELO", "AURORA", "EVMOS", "KAVA"));
        map.put("FANTOM", Arrays.asList("AVAX", "MATIC", "HARMONY", "CRONOS", "MOONBEAM", "CELO", "AURORA", "EVMOS", "KAVA", "OSMOSIS"));
        
        // DeFi Tokens
        map.put("UNI", Arrays.asList("SUSHI", "CAKE", "1INCH", "DYDX", "COMP", "AAVE", "MKR", "SNX", "CRV", "BAL"));
        map.put("AAVE", Arrays.asList("COMP", "MKR", "SNX", "CRV", "YFI", "UNI", "SUSHI", "BAL", "ALPHA", "CREAM"));
        map.put("LINK", Arrays.asList("BAND", "API3", "TRB", "DIA", "FLUX", "RAZOR", "UMBRELLA", "WITNET", "PYTH", "CHAINLINK"));
        map.put("MKR", Arrays.asList("AAVE", "COMP", "SNX", "YFI", "CRV", "BAL", "ALPHA", "CREAM", "INST", "HEGIC"));
        
        // Layer 2 Solutions
        map.put("LRC", Arrays.asList("MATIC", "IMX", "METIS", "BOBA", "OP", "ARB", "STRK", "MANTA", "BLAST", "LINEA"));
        map.put("IMX", Arrays.asList("LRC", "MATIC", "METIS", "BOBA", "OP", "ARB", "STRK", "MANTA", "BLAST", "LINEA"));
        
        // Meme Coins
        map.put("DOGE", Arrays.asList("SHIB", "FLOKI", "PEPE", "BONK", "WIF", "MEME", "BABYDOGE", "DOGELON", "HOKK", "SAFEMOON"));
        map.put("SHIB", Arrays.asList("DOGE", "FLOKI", "PEPE", "BONK", "WIF", "MEME", "BABYDOGE", "DOGELON", "HOKK", "SAFEMOON"));
        
        // Privacy Coins
        map.put("XMR", Arrays.asList("ZEC", "DASH", "DCR", "BEAM", "GRIN", "FIRO", "HAVEN", "PIRATE", "DERO", "TURTLE"));
        map.put("ZEC", Arrays.asList("XMR", "DASH", "DCR", "BEAM", "GRIN", "FIRO", "HAVEN", "PIRATE", "DERO", "TURTLE"));
        
        // Enterprise/Corporate
        map.put("XRP", Arrays.asList("XLM", "ALGO", "HEDERA", "CELO", "FLOW", "TEZOS", "IOTA", "VET", "THETA", "HELIUM"));
        map.put("XLM", Arrays.asList("XRP", "ALGO", "HEDERA", "CELO", "FLOW", "TEZOS", "IOTA", "VET", "THETA", "HELIUM"));
        
        // Gaming & NFT
        map.put("AXS", Arrays.asList("SAND", "MANA", "ENJ", "GALA", "ILV", "ALICE", "TLM", "SLP", "GODS", "IMX"));
        map.put("SAND", Arrays.asList("AXS", "MANA", "ENJ", "GALA", "ILV", "ALICE", "TLM", "SLP", "GODS", "IMX"));
        map.put("MANA", Arrays.asList("AXS", "SAND", "ENJ", "GALA", "ILV", "ALICE", "TLM", "SLP", "GODS", "IMX"));
        
        // AI & Data
        map.put("FET", Arrays.asList("AGIX", "OCEAN", "RLC", "NMR", "LPT", "GRT", "RNDR", "THETA", "AKASH", "BOBA"));
        map.put("AGIX", Arrays.asList("FET", "OCEAN", "RLC", "NMR", "LPT", "GRT", "RNDR", "THETA", "AKASH", "BOBA"));
        
        return map;
    }

    /**
     * Identify cryptocurrency category
     */
    private String identifyCategory(String symbol) {
        String upperSymbol = symbol.toUpperCase();
        
        // Layer 1 Blockchains
        if (Arrays.asList("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "ALGO", "NEAR", "ATOM", "LUNA", "FANTOM").contains(upperSymbol)) {
            return "Layer 1 Blockchain";
        }
        
        // DeFi Tokens
        if (Arrays.asList("UNI", "SUSHI", "AAVE", "COMP", "MKR", "SNX", "CRV", "YFI", "BAL", "ALPHA", "1INCH").contains(upperSymbol)) {
            return "DeFi Protocol";
        }
        
        // Layer 2 Solutions
        if (Arrays.asList("MATIC", "LRC", "IMX", "METIS", "BOBA", "OP", "ARB").contains(upperSymbol)) {
            return "Layer 2 Solution";
        }
        
        // Meme Coins
        if (Arrays.asList("DOGE", "SHIB", "FLOKI", "PEPE", "BONK", "WIF", "MEME").contains(upperSymbol)) {
            return "Meme Coin";
        }
        
        // Privacy Coins
        if (Arrays.asList("XMR", "ZEC", "DASH", "DCR", "BEAM", "GRIN", "FIRO").contains(upperSymbol)) {
            return "Privacy Coin";
        }
        
        // Enterprise/Corporate
        if (Arrays.asList("XRP", "XLM", "HEDERA", "CELO", "FLOW", "TEZOS", "IOTA", "VET").contains(upperSymbol)) {
            return "Enterprise Solution";
        }
        
        // Gaming & NFT
        if (Arrays.asList("AXS", "SAND", "MANA", "ENJ", "GALA", "ILV", "ALICE", "TLM").contains(upperSymbol)) {
            return "Gaming & NFT";
        }
        
        // AI & Data
        if (Arrays.asList("FET", "AGIX", "OCEAN", "RLC", "NMR", "LPT", "GRT", "RNDR").contains(upperSymbol)) {
            return "AI & Data";
        }
        
        return "Other";
    }

    /**
     * Get coins from the same category
     */
    private List<String> getCategoryCoins(String category) {
        Map<String, List<String>> categoryMap = new HashMap<>();
        
        categoryMap.put("Layer 1 Blockchain", Arrays.asList("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "ALGO", "NEAR", "ATOM", "LUNA"));
        categoryMap.put("DeFi Protocol", Arrays.asList("UNI", "SUSHI", "AAVE", "COMP", "MKR", "SNX", "CRV", "YFI", "BAL", "ALPHA"));
        categoryMap.put("Layer 2 Solution", Arrays.asList("MATIC", "LRC", "IMX", "METIS", "BOBA", "OP", "ARB"));
        categoryMap.put("Meme Coin", Arrays.asList("DOGE", "SHIB", "FLOKI", "PEPE", "BONK", "WIF", "MEME"));
        categoryMap.put("Privacy Coin", Arrays.asList("XMR", "ZEC", "DASH", "DCR", "BEAM", "GRIN", "FIRO"));
        categoryMap.put("Enterprise Solution", Arrays.asList("XRP", "XLM", "HEDERA", "CELO", "FLOW", "TEZOS", "IOTA", "VET"));
        categoryMap.put("Gaming & NFT", Arrays.asList("AXS", "SAND", "MANA", "ENJ", "GALA", "ILV", "ALICE", "TLM"));
        categoryMap.put("AI & Data", Arrays.asList("FET", "AGIX", "OCEAN", "RLC", "NMR", "LPT", "GRT", "RNDR"));
        
        return categoryMap.getOrDefault(category, Arrays.asList("BTC", "ETH", "ADA", "SOL", "DOT"));
    }

    /**
     * Get market cap similar coins (simplified)
     */
    private List<String> getMarketCapSimilar(String symbol) {
        // This would require actual market data lookup
        // For now, return some defaults based on common market cap ranges
        return Arrays.asList("BTC", "ETH", "BNB", "ADA", "SOL", "XRP", "DOT", "AVAX", "MATIC", "LINK");
    }

    /**
     * Calculate market cap similarity (simplified)
     */
    private double calculateMarketCapSimilarity(String symbol1, String symbol2) {
        // This would require actual market data comparison
        // For now, return a base similarity score
        return 0.5;
    }

    /**
     * Check if there's a direct mapping between symbols
     */
    private boolean isDirectMapping(String symbol1, String symbol2) {
        List<String> similar = ENHANCED_SIMILARITY_MAP.get(symbol1.toUpperCase());
        return similar != null && similar.contains(symbol2.toUpperCase());
    }

    /**
     * Calculate use case similarity
     */
    private double calculateUseCaseSimilarity(String symbol1, String symbol2) {
        String category1 = identifyCategory(symbol1);
        String category2 = identifyCategory(symbol2);
        
        if (category1.equals(category2)) {
            return 1.0;
        }
        
        // Some categories have partial similarity
        if ((category1.equals("Layer 1 Blockchain") && category2.equals("Enterprise Solution")) ||
            (category1.equals("DeFi Protocol") && category2.equals("Layer 2 Solution"))) {
            return 0.5;
        }
        
        return 0.0;
    }

    /**
     * Get enhanced match reasons
     */
    private List<String> getEnhancedMatchReasons(String originalSymbol, String similarSymbol) {
        List<String> reasons = new ArrayList<>();
        
        String originalCategory = identifyCategory(originalSymbol);
        String similarCategory = identifyCategory(similarSymbol);
        
        if (originalCategory.equals(similarCategory)) {
            reasons.add("Same category: " + originalCategory);
        }
        
        if (isDirectMapping(originalSymbol, similarSymbol)) {
            reasons.add("Direct similarity mapping");
        }
        
        // Add specific reasons based on categories
        switch (originalCategory) {
            case "Layer 1 Blockchain":
                reasons.add("Smart contract capability");
                reasons.add("Decentralized network");
                reasons.add("Native token utility");
                break;
            case "DeFi Protocol":
                reasons.add("Decentralized finance features");
                reasons.add("Yield generation potential");
                reasons.add("Liquidity provision");
                break;
            case "Layer 2 Solution":
                reasons.add("Scalability improvement");
                reasons.add("Lower transaction fees");
                reasons.add("Ethereum compatibility");
                break;
            case "Meme Coin":
                reasons.add("Community-driven");
                reasons.add("Social media popularity");
                reasons.add("Speculative trading");
                break;
            case "Privacy Coin":
                reasons.add("Privacy-focused features");
                reasons.add("Anonymous transactions");
                reasons.add("Regulatory considerations");
                break;
            default:
                reasons.add("Similar market positioning");
                reasons.add("Comparable use cases");
        }
        
        return reasons;
    }

    /**
     * Assess risk level for a cryptocurrency
     */
    private String assessRiskLevel(String symbol) {
        String category = identifyCategory(symbol);
        
        switch (category) {
            case "Layer 1 Blockchain":
                return Arrays.asList("BTC", "ETH").contains(symbol.toUpperCase()) ? "Low" : "Medium";
            case "DeFi Protocol":
                return "Medium-High";
            case "Layer 2 Solution":
                return "Medium";
            case "Meme Coin":
                return "Very High";
            case "Privacy Coin":
                return "High";
            case "Enterprise Solution":
                return "Medium";
            case "Gaming & NFT":
                return "High";
            case "AI & Data":
                return "Medium-High";
            default:
                return "High";
        }
    }

    /**
     * Get investment type classification
     */
    private String getInvestmentType(String symbol) {
        String category = identifyCategory(symbol);
        
        switch (category) {
            case "Layer 1 Blockchain":
                return Arrays.asList("BTC", "ETH").contains(symbol.toUpperCase()) ? "Store of Value" : "Growth";
            case "DeFi Protocol":
                return "Yield";
            case "Layer 2 Solution":
                return "Utility";
            case "Meme Coin":
                return "Speculative";
            case "Privacy Coin":
                return "Alternative";
            case "Enterprise Solution":
                return "Utility";
            case "Gaming & NFT":
                return "Speculative Growth";
            case "AI & Data":
                return "Thematic Growth";
            default:
                return "Speculative";
        }
    }

    /**
     * Get basic market data (placeholder)
     */
    private Map<String, Object> getBasicMarketData(String symbol) {
        Map<String, Object> marketData = new HashMap<>();
        marketData.put("symbol", symbol);
        marketData.put("data_available", false);
        marketData.put("note", "Market data would be fetched from live APIs");
        return marketData;
    }

    /**
     * Generate fallback analysis when AI is not available
     */
    private String generateFallbackAnalysis(String symbol, List<Map<String, Object>> similarCoins) {
        StringBuilder analysis = new StringBuilder();
        
        analysis.append("🔍 **Similar Cryptocurrencies Analysis for ").append(symbol.toUpperCase()).append("**\n\n");
        
        analysis.append("**📊 Summary:**\n");
        analysis.append("Found ").append(similarCoins.size()).append(" similar cryptocurrencies based on:\n");
        analysis.append("• Category and use case similarity\n");
        analysis.append("• Market positioning\n");
        analysis.append("• Technical architecture\n");
        analysis.append("• Investment characteristics\n\n");
        
        analysis.append("**💡 Key Similarities:**\n");
        for (Map<String, Object> coin : similarCoins) {
            analysis.append("• **").append(coin.get("symbol")).append("** - ");
            analysis.append("Category: ").append(coin.get("category")).append(", ");
            analysis.append("Risk Level: ").append(coin.get("risk_level")).append("\n");
        }
        
        analysis.append("\n**⚠️ Investment Considerations:**\n");
        analysis.append("• Each cryptocurrency has unique characteristics and risks\n");
        analysis.append("• Similar coins may have different market dynamics\n");
        analysis.append("• Always conduct thorough research before investing\n");
        analysis.append("• Consider your risk tolerance and investment goals\n\n");
        
        analysis.append("**📚 Recommendation:**\n");
        analysis.append("Research each similar cryptocurrency's whitepaper, team, and recent developments ");
        analysis.append("to understand their unique value propositions and potential risks.");
        
        return analysis.toString();
    }

    // Cache management methods
    private String generateCacheKey(String symbol, int limit, boolean includeAnalysis) {
        return symbol + ":" + limit + ":" + includeAnalysis;
    }

    private List<Map<String, Object>> getCachedSimilar(String cacheKey) {
        Long timestamp = cacheTimestamps.get(cacheKey);
        if (timestamp != null && System.currentTimeMillis() - timestamp < CACHE_DURATION_MS) {
            return similarCoinCache.get(cacheKey);
        }
        return null;
    }

    private void cacheSimilarCoins(String cacheKey, List<Map<String, Object>> similarCoins) {
        similarCoinCache.put(cacheKey, similarCoins);
        cacheTimestamps.put(cacheKey, System.currentTimeMillis());
    }

    // Response creation methods
    private Map<String, Object> createSuccessResponse(
            String symbol, 
            List<Map<String, Object>> similarCoins, 
            boolean includeAnalysis, 
            boolean cached) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("symbol", symbol);
        response.put("similar_cryptocurrencies", similarCoins);
        response.put("count", similarCoins.size());
        response.put("cached", cached);
        response.put("enhanced", true);
        response.put("timestamp", System.currentTimeMillis());
        
        if (includeAnalysis) {
            response.put("analysis_available", false);
            response.put("note", "Analysis generation in progress");
        }
        
        return response;
    }

    private Map<String, Object> createSuccessResponse(
            String symbol, 
            List<Map<String, Object>> similarCoins, 
            String analysis,
            boolean includeAnalysis, 
            boolean cached) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("symbol", symbol);
        response.put("similar_cryptocurrencies", similarCoins);
        response.put("count", similarCoins.size());
        response.put("cached", cached);
        response.put("enhanced", true);
        response.put("timestamp", System.currentTimeMillis());
        
        if (includeAnalysis && analysis != null) {
            response.put("comparison_analysis", analysis);
        }
        
        return response;
    }

    private Map<String, Object> createErrorResponse(String symbol, String error) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("symbol", symbol);
        response.put("error", error);
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }

    // Helper class for scored coins
    private static class ScoredCoin {
        private final String symbol;
        private final double score;

        public ScoredCoin(String symbol, double score) {
            this.symbol = symbol;
            this.score = score;
        }

        public String getSymbol() {
            return symbol;
        }

        public double getScore() {
            return score;
        }
    }
}
