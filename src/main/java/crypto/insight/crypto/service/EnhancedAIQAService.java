package crypto.insight.crypto.service;

import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Enhanced AI Q&A Service with intelligent question analysis and perfect AI responses
 */
@Slf4j
@Service
public class EnhancedAIQAService {

    private final WebClient webClient;
    private final String modelName;
    private final AIService aiService;
    private final Map<String, String> responseCache = new ConcurrentHashMap<>();
    private final Map<String, Long> cacheTimestamps = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
    
    private static final long CACHE_DURATION_MS = 5 * 60 * 1000; // 5 minutes
    private static final int MAX_CACHE_SIZE = 1000;

    public EnhancedAIQAService(
            @org.springframework.beans.factory.annotation.Qualifier("ollamaWebClient") WebClient webClient,
            @Value("${spring.ai.ollama.model}") String modelName,
            AIService aiService) {
        this.webClient = webClient;
        this.modelName = modelName;
        this.aiService = aiService;
        initializeCacheCleanup();
    }

    /**
     * Enhanced AI-powered crypto Q&A with intelligent question analysis
     */
    public CompletableFuture<Map<String, Object>> answerCryptoQuestionEnhanced(
            String symbol, 
            String question, 
            Cryptocurrency crypto,
            List<ChartDataPoint> chartData) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Analyze question type for better response
                String questionType = analyzeQuestionType(question);
                log.info("Question type identified: {} for symbol: {}", questionType, symbol);
                
                // Check cache first
                String cacheKey = generateCacheKey(symbol, question, questionType);
                String cachedResponse = getCachedResponse(cacheKey);
                if (cachedResponse != null) {
                    log.debug("Using cached response for {}", symbol);
                    return createSuccessResponse(symbol, question, cachedResponse, questionType, true);
                }
                
                // Build enhanced context based on question type
                String enhancedContext = buildEnhancedContext(crypto, chartData, questionType);
                
                // Generate AI response with specialized prompt
                String aiResponse = generateEnhancedAIResponse(symbol, question, enhancedContext, questionType);
                
                // Cache the response
                cacheResponse(cacheKey, aiResponse);
                
                return createSuccessResponse(symbol, question, aiResponse, questionType, false);
                
            } catch (Exception e) {
                log.error("Enhanced Q&A failed for {}: {}", symbol, e.getMessage());
                return createErrorResponse(symbol, question, e.getMessage());
            }
        });
    }

    /**
     * Enhanced general crypto Q&A with intelligent categorization
     */
    public CompletableFuture<Map<String, Object>> answerGeneralQuestionEnhanced(String question) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                String questionType = analyzeQuestionType(question);
                log.info("General question type identified: {}", questionType);
                
                String cacheKey = generateCacheKey("GENERAL", question, questionType);
                String cachedResponse = getCachedResponse(cacheKey);
                if (cachedResponse != null) {
                    return createGeneralSuccessResponse(question, cachedResponse, questionType, true);
                }
                
                String aiResponse = generateGeneralAIResponse(question, questionType);
                cacheResponse(cacheKey, aiResponse);
                
                return createGeneralSuccessResponse(question, aiResponse, questionType, false);
                
            } catch (Exception e) {
                log.error("Enhanced general Q&A failed: {}", e.getMessage());
                return createGeneralErrorResponse(question, e.getMessage());
            }
        });
    }

    /**
     * Analyze question type to provide better responses
     */
    private String analyzeQuestionType(String question) {
        String lowerQuestion = question.toLowerCase();
        
        // Investment and trading questions
        if (lowerQuestion.contains("buy") || lowerQuestion.contains("invest") || 
            lowerQuestion.contains("should i") || lowerQuestion.contains("worth")) {
            return "INVESTMENT";
        }
        
        // Price and prediction questions
        if (lowerQuestion.contains("price") || lowerQuestion.contains("predict") || 
            lowerQuestion.contains("forecast") || lowerQuestion.contains("will")) {
            return "PRICE_PREDICTION";
        }
        
        // Technical analysis questions
        if (lowerQuestion.contains("technical") || lowerQuestion.contains("chart") || 
            lowerQuestion.contains("support") || lowerQuestion.contains("resistance")) {
            return "TECHNICAL_ANALYSIS";
        }
        
        // Fundamental analysis questions
        if (lowerQuestion.contains("technology") || lowerQuestion.contains("team") || 
            lowerQuestion.contains("roadmap") || lowerQuestion.contains("use case")) {
            return "FUNDAMENTAL_ANALYSIS";
        }
        
        // Market comparison questions
        if (lowerQuestion.contains("compare") || lowerQuestion.contains("better") || 
            lowerQuestion.contains("vs") || lowerQuestion.contains("versus")) {
            return "COMPARISON";
        }
        
        // Risk assessment questions
        if (lowerQuestion.contains("risk") || lowerQuestion.contains("safe") || 
            lowerQuestion.contains("dangerous") || lowerQuestion.contains("volatile")) {
            return "RISK_ASSESSMENT";
        }
        
        // Educational questions
        if (lowerQuestion.contains("what is") || lowerQuestion.contains("how does") || 
            lowerQuestion.contains("explain") || lowerQuestion.contains("learn")) {
            return "EDUCATIONAL";
        }
        
        return "GENERAL";
    }

    /**
     * Build enhanced context based on question type
     */
    private String buildEnhancedContext(Cryptocurrency crypto, List<ChartDataPoint> chartData, String questionType) {
        StringBuilder context = new StringBuilder();
        
        // Base cryptocurrency information
        context.append("🪙 **CRYPTOCURRENCY PROFILE**\n");
        context.append("Name: ").append(crypto.getName()).append("\n");
        context.append("Symbol: ").append(crypto.getSymbol()).append("\n");
        context.append("Current Price: $").append(String.format("%.2f", crypto.getPrice())).append("\n");
        
        if (crypto.getMarketCap() != null) {
            context.append("Market Cap: $").append(formatLargeNumber(crypto.getMarketCap().doubleValue())).append("\n");
        }
        
        if (crypto.getPercentChange24h() != null) {
            context.append("24h Change: ").append(String.format("%.2f%%", crypto.getPercentChange24h())).append("\n");
        }
        
        // Add context specific to question type
        switch (questionType) {
            case "INVESTMENT":
                context.append("\n💰 **INVESTMENT CONTEXT**\n");
                context.append("- Market Cap Ranking: ").append(crypto.getRank() != null ? "#" + crypto.getRank() : "N/A").append("\n");
                context.append("- 24h Trading Volume: $").append(crypto.getVolume24h() != null ? formatLargeNumber(crypto.getVolume24h().doubleValue()) : "N/A").append("\n");
                addRiskMetrics(context, crypto, chartData);
                break;
                
            case "PRICE_PREDICTION":
                context.append("\n📈 **PRICE ANALYSIS CONTEXT**\n");
                addPriceAnalysis(context, crypto, chartData);
                break;
                
            case "TECHNICAL_ANALYSIS":
                context.append("\n📊 **TECHNICAL ANALYSIS CONTEXT**\n");
                addTechnicalIndicators(context, crypto, chartData);
                break;
                
            case "FUNDAMENTAL_ANALYSIS":
                context.append("\n🏗️ **FUNDAMENTAL ANALYSIS CONTEXT**\n");
                addFundamentalMetrics(context, crypto);
                break;
                
            case "RISK_ASSESSMENT":
                context.append("\n⚠️ **RISK ASSESSMENT CONTEXT**\n");
                addRiskMetrics(context, crypto, chartData);
                break;
        }
        
        return context.toString();
    }

    /**
     * Generate enhanced AI response with specialized prompts
     */
    private String generateEnhancedAIResponse(String symbol, String question, String context, String questionType) {
        String prompt = buildEnhancedPrompt(symbol, question, context, questionType);
        
        try {
            return aiService.generateAnalysisWithFallback("enhanced_qa", prompt);
        } catch (Exception e) {
            log.warn("AI generation failed, using fallback for {}: {}", symbol, e.getMessage());
            return generateFallbackResponse(symbol, question, questionType);
        }
    }

    /**
     * Build specialized prompts based on question type
     */
    private String buildEnhancedPrompt(String symbol, String question, String context, String questionType) {
        StringBuilder prompt = new StringBuilder();
        
        // Add question type specific instructions
        switch (questionType) {
            case "INVESTMENT":
                prompt.append("🎯 **INVESTMENT ADVISORY PROMPT**\n");
                prompt.append("You are a professional cryptocurrency investment advisor. ");
                prompt.append("Provide balanced, educational investment guidance. ");
                prompt.append("ALWAYS include risk disclaimers and encourage personal research.\n\n");
                break;
                
            case "PRICE_PREDICTION":
                prompt.append("📊 **PRICE ANALYSIS PROMPT**\n");
                prompt.append("You are a cryptocurrency market analyst. ");
                prompt.append("Provide data-driven price analysis based on current market conditions. ");
                prompt.append("Focus on technical and fundamental factors. AVOID guarantees about future prices.\n\n");
                break;
                
            case "TECHNICAL_ANALYSIS":
                prompt.append("📈 **TECHNICAL ANALYSIS PROMPT**\n");
                prompt.append("You are a cryptocurrency technical analyst. ");
                prompt.append("Provide detailed technical analysis based on price action, volume, and market indicators. ");
                prompt.append("Use professional trading terminology and concepts.\n\n");
                break;
                
            case "FUNDAMENTAL_ANALYSIS":
                prompt.append("🏛️ **FUNDAMENTAL ANALYSIS PROMPT**\n");
                prompt.append("You are a cryptocurrency fundamental analyst. ");
                prompt.append("Focus on technology, team, use cases, adoption, and long-term value proposition. ");
                prompt.append("Provide educational insights about the project's fundamentals.\n\n");
                break;
                
            case "RISK_ASSESSMENT":
                prompt.append("⚠️ **RISK ASSESSMENT PROMPT**\n");
                prompt.append("You are a cryptocurrency risk analyst. ");
                prompt.append("Provide comprehensive risk analysis including market, technical, and regulatory risks. ");
                prompt.append("Be thorough and educational about potential risks.\n\n");
                break;
                
            default:
                prompt.append("🤖 **GENERAL CRYPTO EXPERT PROMPT**\n");
                prompt.append("You are a knowledgeable cryptocurrency expert. ");
                prompt.append("Provide accurate, educational, and helpful information. ");
                prompt.append("Be informative while encouraging users to do their own research.\n\n");
        }
        
        prompt.append("**QUESTION:** ").append(question).append("\n\n");
        prompt.append("**CONTEXT DATA:**\n").append(context).append("\n\n");
        
        prompt.append("**RESPONSE REQUIREMENTS:**\n");
        prompt.append("1. Provide a comprehensive, well-structured answer\n");
        prompt.append("2. Use emojis and formatting for better readability\n");
        prompt.append("3. Reference specific data from the context when relevant\n");
        prompt.append("4. Include appropriate disclaimers for financial advice\n");
        prompt.append("5. Encourage further research and learning\n");
        prompt.append("6. Keep the tone professional yet accessible\n\n");
        
        return prompt.toString();
    }

    /**
     * Generate enhanced general AI response
     */
    private String generateGeneralAIResponse(String question, String questionType) {
        String prompt = buildGeneralEnhancedPrompt(question, questionType);
        
        try {
            return aiService.generateAnalysisWithFallback("enhanced_general_qa", prompt);
        } catch (Exception e) {
            log.warn("General AI generation failed, using fallback: {}", e.getMessage());
            return generateGeneralFallbackResponse(question, questionType);
        }
    }

    /**
     * Build enhanced prompts for general questions
     */
    private String buildGeneralEnhancedPrompt(String question, String questionType) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append("🎓 **CRYPTOCURRENCY EDUCATION EXPERT**\n");
        prompt.append("You are a professional cryptocurrency educator and expert. ");
        prompt.append("Provide educational, accurate, and comprehensive information about cryptocurrencies.\n\n");
        
        prompt.append("**QUESTION TYPE:** ").append(questionType).append("\n");
        prompt.append("**QUESTION:** ").append(question).append("\n\n");
        
        prompt.append("**RESPONSE GUIDELINES:**\n");
        prompt.append("1. Provide comprehensive, educational content\n");
        prompt.append("2. Use clear explanations suitable for various knowledge levels\n");
        prompt.append("3. Include practical examples when helpful\n");
        prompt.append("4. Use emojis and formatting for better readability\n");
        prompt.append("5. Include relevant warnings and disclaimers\n");
        prompt.append("6. Encourage further learning and research\n");
        prompt.append("7. Focus on factual, unbiased information\n\n");
        
        return prompt.toString();
    }

    // Helper methods for context building
    private void addRiskMetrics(StringBuilder context, Cryptocurrency crypto, List<ChartDataPoint> chartData) {
        context.append("- Volatility Level: ").append(calculateVolatilityLevel(crypto, chartData)).append("\n");
        context.append("- Market Cap Risk: ").append(assessMarketCapRisk(crypto)).append("\n");
        context.append("- Liquidity Assessment: ").append(assessLiquidity(crypto)).append("\n");
    }

    private void addPriceAnalysis(StringBuilder context, Cryptocurrency crypto, List<ChartDataPoint> chartData) {
        if (chartData != null && !chartData.isEmpty()) {
            context.append("- Recent Price Trend: ").append(analyzePriceTrend(chartData)).append("\n");
            context.append("- Key Price Levels: ").append(identifyKeyLevels(chartData)).append("\n");
        }
        context.append("- Price Momentum: ").append(assessPriceMomentum(crypto)).append("\n");
    }

    private void addTechnicalIndicators(StringBuilder context, Cryptocurrency crypto, List<ChartDataPoint> chartData) {
        if (chartData != null && !chartData.isEmpty()) {
            context.append("- Chart Pattern: ").append(identifyChartPattern(chartData)).append("\n");
            context.append("- Volume Analysis: ").append(analyzeVolume(crypto)).append("\n");
            context.append("- Support/Resistance: ").append(identifyKeyLevels(chartData)).append("\n");
        }
    }

    private void addFundamentalMetrics(StringBuilder context, Cryptocurrency crypto) {
        context.append("- Market Position: ").append(assessMarketPosition(crypto)).append("\n");
        context.append("- Adoption Metrics: ").append(assessAdoption(crypto)).append("\n");
        context.append("- Development Activity: ").append(assessDevelopment(crypto)).append("\n");
    }

    // Analysis helper methods
    private String calculateVolatilityLevel(Cryptocurrency crypto, List<ChartDataPoint> chartData) {
        if (crypto.getPercentChange24h() == null) return "Unknown";
        
        double change24h = Math.abs(crypto.getPercentChange24h().doubleValue());
        if (change24h < 2) return "Low";
        if (change24h < 5) return "Moderate";
        if (change24h < 10) return "High";
        return "Very High";
    }

    private String assessMarketCapRisk(Cryptocurrency crypto) {
        if (crypto.getMarketCap() == null) return "Unknown";
        
        double marketCap = crypto.getMarketCap().doubleValue();
        if (marketCap > 10_000_000_000L) return "Low (Large Cap)";
        if (marketCap > 1_000_000_000L) return "Medium (Mid Cap)";
        if (marketCap > 100_000_000L) return "High (Small Cap)";
        return "Very High (Micro Cap)";
    }

    private String assessLiquidity(Cryptocurrency crypto) {
        if (crypto.getVolume24h() == null) return "Unknown";
        
        double volume24h = crypto.getVolume24h().doubleValue();
        if (volume24h > 100_000_000) return "High";
        if (volume24h > 10_000_000) return "Medium";
        if (volume24h > 1_000_000) return "Low";
        return "Very Low";
    }

    private String analyzePriceTrend(List<ChartDataPoint> chartData) {
        if (chartData.size() < 2) return "Insufficient data";
        
        double firstPrice = chartData.get(0).getPrice();
        double lastPrice = chartData.get(chartData.size() - 1).getPrice();
        double change = ((lastPrice - firstPrice) / firstPrice) * 100;
        
        if (change > 5) return "Strong Uptrend";
        if (change > 2) return "Moderate Uptrend";
        if (change > -2) return "Sideways";
        if (change > -5) return "Moderate Downtrend";
        return "Strong Downtrend";
    }

    private String identifyKeyLevels(List<ChartDataPoint> chartData) {
        if (chartData.isEmpty()) return "No data available";
        
        double high = chartData.stream().mapToDouble(ChartDataPoint::getPrice).max().orElse(0);
        double low = chartData.stream().mapToDouble(ChartDataPoint::getPrice).min().orElse(0);
        
        return String.format("Support: $%.2f, Resistance: $%.2f", low, high);
    }

    private String assessPriceMomentum(Cryptocurrency crypto) {
        if (crypto.getPercentChange24h() == null) return "Unknown";
        
        double change24h = crypto.getPercentChange24h().doubleValue();
        if (change24h > 10) return "Strong Bullish";
        if (change24h > 5) return "Bullish";
        if (change24h > -5) return "Neutral";
        if (change24h > -10) return "Bearish";
        return "Strong Bearish";
    }

    private String identifyChartPattern(List<ChartDataPoint> chartData) {
        // Simplified pattern recognition
        if (chartData.size() < 10) return "Insufficient data for pattern analysis";
        
        List<Double> prices = chartData.stream()
                .map(ChartDataPoint::getPrice)
                .collect(java.util.stream.Collectors.toList());
        
        // Check for ascending/descending patterns
        boolean ascending = true, descending = true;
        for (int i = 1; i < Math.min(prices.size(), 10); i++) {
            if (prices.get(i) <= prices.get(i-1)) ascending = false;
            if (prices.get(i) >= prices.get(i-1)) descending = false;
        }
        
        if (ascending) return "Ascending Pattern";
        if (descending) return "Descending Pattern";
        return "Consolidation Pattern";
    }

    private String analyzeVolume(Cryptocurrency crypto) {
        if (crypto.getVolume24h() == null || crypto.getMarketCap() == null) return "Unknown";
        
        double volumeToMarketCap = crypto.getVolume24h().doubleValue() / crypto.getMarketCap().doubleValue();
        if (volumeToMarketCap > 0.1) return "High Volume Activity";
        if (volumeToMarketCap > 0.05) return "Moderate Volume Activity";
        return "Low Volume Activity";
    }

    private String assessMarketPosition(Cryptocurrency crypto) {
        if (crypto.getRank() == null) return "Unranked";
        
        int rank = crypto.getRank();
        if (rank <= 10) return "Top 10 Cryptocurrency";
        if (rank <= 50) return "Top 50 Cryptocurrency";
        if (rank <= 100) return "Top 100 Cryptocurrency";
        return "Lower Ranked Cryptocurrency";
    }

    private String assessAdoption(Cryptocurrency crypto) {
        // Simplified adoption assessment based on market metrics
        if (crypto.getMarketCap() == null) return "Unknown";
        
        double marketCap = crypto.getMarketCap().doubleValue();
        if (marketCap > 50_000_000_000L) return "High Adoption";
        if (marketCap > 10_000_000_000L) return "Moderate Adoption";
        if (marketCap > 1_000_000_000L) return "Growing Adoption";
        return "Early Adoption";
    }

    private String assessDevelopment(Cryptocurrency crypto) {
        // Simplified development assessment
        return "Active Development (Based on market presence)";
    }

    // Cache management methods
    private String generateCacheKey(String symbol, String question, String questionType) {
        return symbol + ":" + questionType + ":" + question.hashCode();
    }

    private String getCachedResponse(String cacheKey) {
        Long timestamp = cacheTimestamps.get(cacheKey);
        if (timestamp != null && System.currentTimeMillis() - timestamp < CACHE_DURATION_MS) {
            return responseCache.get(cacheKey);
        }
        return null;
    }

    private void cacheResponse(String cacheKey, String response) {
        if (responseCache.size() >= MAX_CACHE_SIZE) {
            // Remove oldest entries
            String oldestKey = cacheTimestamps.entrySet().stream()
                    .min(Map.Entry.comparingByValue())
                    .map(Map.Entry::getKey)
                    .orElse(null);
            if (oldestKey != null) {
                responseCache.remove(oldestKey);
                cacheTimestamps.remove(oldestKey);
            }
        }
        
        responseCache.put(cacheKey, response);
        cacheTimestamps.put(cacheKey, System.currentTimeMillis());
    }

    private void initializeCacheCleanup() {
        scheduler.scheduleAtFixedRate(() -> {
            long currentTime = System.currentTimeMillis();
            List<String> expiredKeys = new ArrayList<>();
            
            cacheTimestamps.entrySet().stream()
                    .filter(entry -> currentTime - entry.getValue() > CACHE_DURATION_MS)
                    .forEach(entry -> expiredKeys.add(entry.getKey()));
            
            expiredKeys.forEach(key -> {
                responseCache.remove(key);
                cacheTimestamps.remove(key);
            });
            
            if (!expiredKeys.isEmpty()) {
                log.debug("Cleaned up {} expired cache entries", expiredKeys.size());
            }
        }, 1, 1, TimeUnit.MINUTES);
    }

    // Response building methods
    private Map<String, Object> createSuccessResponse(String symbol, String question, String answer, String questionType, boolean cached) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("symbol", symbol);
        response.put("question", question);
        response.put("answer", answer);
        response.put("questionType", questionType);
        response.put("cached", cached);
        response.put("timestamp", System.currentTimeMillis());
        response.put("aiEnhanced", true);
        return response;
    }

    private Map<String, Object> createGeneralSuccessResponse(String question, String answer, String questionType, boolean cached) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("question", question);
        response.put("answer", answer);
        response.put("questionType", questionType);
        response.put("cached", cached);
        response.put("timestamp", System.currentTimeMillis());
        response.put("aiEnhanced", true);
        return response;
    }

    private Map<String, Object> createErrorResponse(String symbol, String question, String error) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("symbol", symbol);
        response.put("question", question);
        response.put("error", error);
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }

    private Map<String, Object> createGeneralErrorResponse(String question, String error) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("question", question);
        response.put("error", error);
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }

    // Fallback response methods
    private String generateFallbackResponse(String symbol, String question, String questionType) {
        return String.format("I understand you're asking about %s regarding %s. While I'm currently unable to provide a detailed AI response, I'd recommend checking the latest market data and official project documentation for accurate information. Please try again in a moment as our AI service may be temporarily busy.", symbol, questionType.toLowerCase());
    }

    private String generateGeneralFallbackResponse(String question, String questionType) {
        return String.format("I understand your question about %s. While I'm currently unable to provide a detailed AI response, I'd recommend consulting reputable cryptocurrency educational resources. Please try again in a moment as our AI service may be temporarily busy.", questionType.toLowerCase());
    }

    // Utility methods
    private String formatLargeNumber(double number) {
        if (number >= 1_000_000_000) {
            return String.format("%.2fB", number / 1_000_000_000);
        } else if (number >= 1_000_000) {
            return String.format("%.2fM", number / 1_000_000);
        } else if (number >= 1_000) {
            return String.format("%.2fK", number / 1_000);
        } else {
            return String.format("%.2f", number);
        }
    }
}
