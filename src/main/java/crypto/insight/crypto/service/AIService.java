package crypto.insight.crypto.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;
import java.time.Duration;
import java.util.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import jakarta.annotation.PostConstruct;
import crypto.insight.crypto.model.AnalysisResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.model.Cryptocurrency;

/**
 * Service for generating AI-powered cryptocurrency analysis.
 * Uses Ollama API for generating insights and analysis.
 */
@Slf4j
@Service
public class AIService {
    
    // Constants
    private static final int MAX_PRICE_HISTORY_ITEMS = 10;
    private static final int PRECISION_SCALE = 6;
    private static final int ANNUALIZATION_DAYS = 365;
    private static final String OLLAMA_API_URL = "http://localhost:11434/api/chat";
    private static final int MAX_RETRIES = 3;
    private static final String DEFAULT_VALUE = "N/A";
    private static final int MAX_TOKENS = 800; // Reduced for faster responses
    
    private final WebClient webClient;
    private final String modelName;
    private final ObjectMapper objectMapper;
    private static final Duration TIMEOUT_DURATION = Duration.ofSeconds(120); // Increased timeout

    public AIService(@org.springframework.beans.factory.annotation.Qualifier("ollamaWebClient") WebClient ollamaWebClient, 
                    @Value("${spring.ai.ollama.model}") String modelName,
                    ObjectMapper objectMapper) {
        this.modelName = modelName;
        this.objectMapper = objectMapper;
        this.webClient = ollamaWebClient;
    }

    @PostConstruct
    public void init() {
        log.info("AIService initialized with model: {}", modelName);
        warmupOllama();
    }
    
    private void warmupOllama() {
        try {
            log.info("Testing Ollama connection...");
            Map<String, Object> testRequest = new HashMap<>();
            testRequest.put("model", modelName);
            testRequest.put("stream", false);
            testRequest.put("messages", List.of(Map.of("role", "user", "content", "Hello")));
            testRequest.put("options", Map.of("num_predict", 10));

            String response = webClient.post()
                    .uri(OLLAMA_API_URL)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(testRequest)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(30))
                    .block();
                    
            if (response != null && !response.isEmpty()) {
                log.info("Ollama connection successful");
            } else {
                log.warn("Ollama connection test returned empty response");
            }
        } catch (Exception e) {
            log.error("Ollama connection test failed: {}. AI analysis may not work properly.", e.getMessage());
        }
    }

    public CompletableFuture<AnalysisResponse> generateComprehensiveAnalysis(
            Cryptocurrency crypto,
            List<ChartDataPoint> chartDataPoints,
            int days) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                validateInputs(crypto, chartDataPoints, days);
                
                Map<String, String> analysis = new HashMap<>();
                String contextData = buildAnalysisContext(crypto, chartDataPoints, days);
                
                // Generate different types of analysis SEQUENTIALLY to avoid overwhelming Ollama
                log.info("Starting sequential analysis generation for {}", crypto.getSymbol());
                
                analysis.put("general", generateAnalysisWithFallback("general", contextData));
                analysis.put("technical", generateAnalysisWithFallback("technical", contextData));
                analysis.put("fundamental", generateAnalysisWithFallback("fundamental", contextData));
                analysis.put("risk", generateAnalysisWithFallback("risk", contextData));
                
                // Only generate additional analysis if the first few succeed
                if (analysis.values().stream().noneMatch(v -> v.contains("could not be generated"))) {
                    analysis.put("sentiment", generateAnalysisWithFallback("sentiment", contextData));
                    analysis.put("prediction", generateAnalysisWithFallback("prediction", contextData));
                }
                
                log.info("Completed analysis generation for {}", crypto.getSymbol());
                
                return AnalysisResponse.builder()
                    .analysis(analysis)
                    .chartData(chartDataPoints)
                    .build();
            } catch (Exception e) {
                log.error("Error generating analysis for {}: {}", 
                         crypto != null ? crypto.getSymbol() : "null", e.getMessage(), e);
                throw new RuntimeException("Failed to generate analysis", e);
            }
        });
    }
    
    public String generateAnalysisWithFallback(String type, String contextData) {
        try {
            return generateAnalysis(type, contextData).block();
        } catch (Exception e) {
            log.warn("Failed to generate {} analysis: {}", type, e.getMessage());
            return getDefaultAnalysis(type);
        }
    }
    
    private String getDefaultAnalysis(String type) {
        return switch (type) {
            case "general" -> "🔴 CURRENT MARKET ANALYSIS UNAVAILABLE: Real-time general market analysis could not be generated due to AI service limitations. The current market data is available above, but AI-powered insights are temporarily unavailable. Please try again in a few moments.";
            case "technical" -> "📊 TECHNICAL ANALYSIS UNAVAILABLE: Current technical analysis could not be generated due to AI service limitations. You can still review the current price levels and recent data provided above. Please try again for AI-powered technical insights.";
            case "fundamental" -> "🏛️ FUNDAMENTAL ANALYSIS UNAVAILABLE: Current fundamental analysis could not be generated due to AI service limitations. The basic market metrics are shown above, but detailed fundamental insights are temporarily unavailable.";
            case "sentiment" -> "💭 SENTIMENT ANALYSIS UNAVAILABLE: Current market sentiment analysis could not be generated due to AI service limitations. You can review the current price movements and volume data above for basic sentiment indicators.";
            case "risk" -> "⚠️ RISK ASSESSMENT UNAVAILABLE: Current risk analysis could not be generated due to AI service limitations. Please review the volatility metrics above and try again for detailed risk assessment.";
            case "prediction" -> "🔮 PRICE PREDICTIONS UNAVAILABLE: Current price predictions could not be generated due to AI service limitations. The current market data is available above for manual analysis. Please try again for AI-powered predictions.";
            default -> "❌ ANALYSIS UNAVAILABLE: Current market analysis could not be generated due to AI service limitations. Please try again in a few moments.";
        };
    }

    private void validateInputs(Cryptocurrency crypto, List<ChartDataPoint> chartDataPoints, int days) {
        if (crypto == null) {
            throw new IllegalArgumentException("Cryptocurrency data cannot be null");
        }
        if (crypto.getSymbol() == null || crypto.getSymbol().trim().isEmpty()) {
            throw new IllegalArgumentException("Cryptocurrency symbol cannot be null or empty");
        }
        if (days <= 0 || days > 365) {
            throw new IllegalArgumentException("Days must be between 1 and 365");
        }
        if (chartDataPoints == null) {
            log.warn("Chart data points are null for {}", crypto.getSymbol());
        }
    }

    private Mono<String> generateAnalysis(String type, String contextData) {
        String prompt = buildPrompt(type, contextData);
        log.debug("Generated prompt for {} analysis: {}", type, prompt);
        
        Map<String, Object> request = new HashMap<>();
        request.put("model", modelName);
        request.put("stream", false);
        request.put("messages", List.of(Map.of("role", "user", "content", prompt)));
        request.put("options", Map.of(
            "temperature", 0.7, 
            "num_predict", MAX_TOKENS,
            "repeat_penalty", 1.1,
            "top_k", 40,
            "top_p", 0.9
        ));

        log.debug("Sending request to Ollama with prompt of length: {}", prompt.length());

        return webClient.post()
                .uri(OLLAMA_API_URL)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(String.class)
                .timeout(TIMEOUT_DURATION)
                .retryWhen(Retry.backoff(MAX_RETRIES, Duration.ofSeconds(2))
                    .filter(throwable -> {
                        log.warn("Retryable error: {}", throwable.getMessage());
                        return true;
                    })
                    .onRetryExhaustedThrow((retryBackoffSpec, retrySignal) -> {
                        log.error("Failed after max retries: {}", retrySignal.failure().getMessage());
                        return new RuntimeException("Failed to get response from AI after " + MAX_RETRIES + " attempts", retrySignal.failure());
                    }))
                .map(this::extractContentFromResponse)
                .onErrorResume(e -> {
                    log.error("Error generating analysis: {}", e.getMessage());
                    return Mono.just("Analysis could not be generated due to: " + e.getMessage());
                });
    }

    private String extractContentFromResponse(String jsonResponse) {
        try {
            if (jsonResponse == null || jsonResponse.isBlank()) {
                throw new IllegalArgumentException("Empty response from AI service");
            }
            
            com.fasterxml.jackson.databind.JsonNode jsonNode = objectMapper.readTree(jsonResponse);
            String content = jsonNode.path("message").path("content").asText();
            
            if (content == null || content.isBlank()) {
                log.warn("Empty content in AI response. Full response: {}", jsonResponse);
                throw new IllegalStateException("Received empty content from AI service");
            }
            
            log.debug("Successfully extracted AI response of length: {}", content.length());
            return content.trim();
            
        } catch (Exception e) {
            log.error("Error parsing AI response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse AI response", e);
        }
    }

    private String buildPrompt(String type, String contextData) {
        return switch (type) {
            case "general" -> buildGeneralPrompt(contextData);
            case "technical" -> buildTechnicalPrompt(contextData);
            case "fundamental" -> buildFundamentalPrompt(contextData);
            case "news" -> buildNewsPrompt(contextData);
            case "sentiment" -> buildSentimentPrompt(contextData);
            case "risk" -> buildRiskPrompt(contextData);
            case "prediction" -> buildPredictionPrompt(contextData);
            default -> throw new IllegalArgumentException("Unknown analysis type: " + type);
        };
    }

    private String buildGeneralPrompt(String contextData) {
        return "🔴 LIVE CRYPTO ANALYSIS REQUEST - Provide a comprehensive real-time market analysis (minimum 3 paragraphs) for the following current cryptocurrency data. " +
               "Focus on TODAY'S market trends, current position in the market, and recent highlights. " +
               "Structure your response with clear sections and ensure it's complete. " +
               "Reference the actual current data provided and mention specific current price levels and recent changes. " +
               "If any real-time data is missing, acknowledge it but provide the most current analysis possible based on available information.\n\n" +
               contextData +
               "\n\n⚠️ CRITICAL: Your analysis must reflect the CURRENT market state as of the timestamp provided. " +
               "Use present tense when discussing the data. Do not make it sound historical unless specifically noting past trends. " +
               "Include specific current price points and recent percentage changes in your analysis.";
    }

    private String buildTechnicalPrompt(String contextData) {
        return "📊 REAL-TIME TECHNICAL ANALYSIS - Perform a detailed current technical analysis (minimum 3 paragraphs) including:\n" +
               "1. Current price action and immediate trends\n" +
               "2. Present support/resistance levels based on recent data\n" +
               "3. Current moving averages and technical indicators\n" +
               "4. Recent volume analysis and market activity\n" +
               "5. Immediate trading signals and potential entry/exit points\n\n" +
               "📈 CURRENT MARKET DATA:\n" + contextData + "\n\n" +
               "🎯 REQUIREMENTS: Reference specific CURRENT price levels and recent movements. " +
               "Use the actual data provided to identify present market conditions. " +
               "If certain technical data is missing, focus on available current information. " +
               "Ensure your analysis reflects the live market state as of the timestamp provided.";
    }

    private String buildFundamentalPrompt(String contextData) {
        return "🏛️ CURRENT FUNDAMENTAL ANALYSIS - Provide a thorough fundamental analysis based on current market data (minimum 3 paragraphs) covering:\n" +
               "1. Current market cap position and ranking\n" +
               "2. Present tokenomics and supply metrics\n" +
               "3. Current adoption trends and network activity\n" +
               "4. Recent development activity and updates\n" +
               "5. Present competitive landscape position\n\n" +
               "📊 LIVE MARKET FUNDAMENTALS:\n" + contextData + "\n\n" +
               "🎯 FUNDAMENTAL FOCUS: Analyze the fundamentals based on CURRENT market data provided. " +
               "Reference the actual current market cap, ranking, and supply metrics. " +
               "Consider the present market position and recent changes in fundamental metrics. " +
               "If specific fundamental data isn't available, focus on the current market metrics provided and acknowledge limitations.";
    }

    private String buildNewsPrompt(String contextData) {
        return "Analyze the potential impact of recent market news and developments (at least 3 paragraphs). Cover:\n" +
               "1. Recent news and announcements\n" +
               "2. Regulatory developments\n" +
               "3. Partnerships and ecosystem growth\n" +
               "4. Market sentiment indicators\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: If specific news data isn't available, analyze the general market context. " +
               "Provide a complete analysis even with limited information. " +
               "Ensure your response is thorough and well-structured.";
    }

    private String buildSentimentPrompt(String contextData) {
        return "💭 LIVE SENTIMENT ANALYSIS - Evaluate the current market sentiment and investor behavior based on real-time data (minimum 3 paragraphs). Analyze:\n" +
               "1. Current price action and recent volume trends\n" +
               "2. Present market psychology indicators\n" +
               "3. Recent trading patterns and market activity\n" +
               "4. Current market positioning based on available data\n\n" +
               "📊 CURRENT MARKET CONDITIONS:\n" + contextData + "\n\n" +
               "🎯 SENTIMENT FOCUS: Base your sentiment analysis on the CURRENT market data and recent price movements provided. " +
               "Reference specific current trading volumes and price changes to gauge market sentiment. " +
               "Consider the data freshness and current market status when evaluating investor behavior. " +
               "If certain sentiment indicators aren't available, focus on the current price and volume data provided.";
    }

    private String buildRiskPrompt(String contextData) {
        return "⚠️ CURRENT RISK ASSESSMENT - Provide a comprehensive risk assessment based on current market conditions (minimum 3 paragraphs) covering:\n" +
               "1. Current volatility and immediate price risks\n" +
               "2. Present market and liquidity conditions\n" +
               "3. Current regulatory environment and compliance risks\n" +
               "4. Recent protocol and smart contract developments\n" +
               "5. Immediate competitive landscape risks\n\n" +
               "📊 LIVE MARKET DATA:\n" + contextData + "\n\n" +
               "🎯 ANALYSIS FOCUS: Assess risks based on the CURRENT market conditions and data provided. " +
               "Reference actual current volatility levels and recent price movements. " +
               "Consider the present market status and data freshness when evaluating risks. " +
               "Acknowledge any data limitations but provide the most current risk assessment possible.";
    }

    private String buildPredictionPrompt(String contextData) {
        return "🔮 LIVE MARKET PREDICTIONS - Generate informed price predictions and scenarios based on current market data (minimum 3 paragraphs). Include:\n" +
               "1. Short-term outlook (next 1-2 weeks) based on current trends\n" +
               "2. Medium-term outlook (1-6 months) considering present market conditions\n" +
               "3. Key current price levels to watch immediately\n" +
               "4. Potential upside and downside scenarios from current levels\n\n" +
               "📊 CURRENT MARKET CONDITIONS:\n" + contextData + "\n\n" +
               "⚡ REQUIREMENTS: Base predictions on the CURRENT price and market data provided. " +
               "Reference the actual current price levels and recent percentage changes. " +
               "Acknowledge that these are projections based on present market conditions and data freshness. " +
               "Use the specific current price as the baseline for all predictions and scenarios.";
    }

    public String buildAnalysisContext(
            Cryptocurrency crypto,
            List<ChartDataPoint> chartDataPoints,
            int days) {
        
        if (crypto == null) {
            log.warn("Cryptocurrency is null in buildAnalysisContext");
            return "No cryptocurrency data available";
        }
        
        Map<String, Double> metrics = calculateMetrics(chartDataPoints);
        return formatContextData(crypto, chartDataPoints, metrics, days);
    }

    private Map<String, Double> calculateMetrics(List<ChartDataPoint> priceData) {
        Map<String, Double> metrics = new HashMap<>();
        
        if (priceData == null || priceData.isEmpty()) {
            log.warn("Price data is null or empty, returning default metrics");
            return getDefaultMetrics();
        }
        
        try {
            BigDecimal volatility = calculateVolatility(priceData);
            BigDecimal sevenDayAvg = calculateAverage(priceData, 7);
            BigDecimal thirtyDayAvg = calculateAverage(priceData, 30);
            
            metrics.put("volatility", volatility.doubleValue());
            metrics.put("sevenDayAvg", sevenDayAvg.doubleValue());
            metrics.put("thirtyDayAvg", thirtyDayAvg.doubleValue());
            
            // Additional metrics
            metrics.put("priceChange", calculatePriceChange(priceData));
            metrics.put("highLowRatio", calculateHighLowRatio(priceData));
            
        } catch (Exception e) {
            log.error("Error calculating metrics: {}", e.getMessage(), e);
            return getDefaultMetrics();
        }
        
        return metrics;
    }

    private Map<String, Double> getDefaultMetrics() {
        Map<String, Double> defaults = new HashMap<>();
        defaults.put("volatility", 0.0);
        defaults.put("sevenDayAvg", 0.0);
        defaults.put("thirtyDayAvg", 0.0);
        defaults.put("priceChange", 0.0);
        defaults.put("highLowRatio", 1.0);
        return defaults;
    }

    private double calculatePriceChange(List<ChartDataPoint> priceData) {
        if (priceData.size() < 2) return 0.0;
        
        double firstPrice = priceData.get(0).getPrice();
        double lastPrice = priceData.get(priceData.size() - 1).getPrice();
        
        return firstPrice != 0 ? ((lastPrice - firstPrice) / firstPrice) * 100 : 0.0;
    }

    private double calculateHighLowRatio(List<ChartDataPoint> priceData) {
        if (priceData.isEmpty()) return 1.0;
        
        double high = priceData.stream().mapToDouble(ChartDataPoint::getPrice).max().orElse(0.0);
        double low = priceData.stream().mapToDouble(ChartDataPoint::getPrice).min().orElse(0.0);
        
        return low != 0 ? high / low : 1.0;
    }

    private BigDecimal calculateVolatility(List<ChartDataPoint> priceData) {
        if (priceData == null || priceData.size() < 2) {
            return BigDecimal.ZERO;
        }
        
        List<BigDecimal> returns = new ArrayList<>();
        for (int i = 1; i < priceData.size(); i++) {
            BigDecimal current = BigDecimal.valueOf(priceData.get(i).getPrice());
            BigDecimal previous = BigDecimal.valueOf(priceData.get(i - 1).getPrice());
            
            if (previous.compareTo(BigDecimal.ZERO) != 0) {
                BigDecimal dailyReturn = current.subtract(previous)
                        .divide(previous, PRECISION_SCALE, RoundingMode.HALF_UP);
                returns.add(dailyReturn);
            }
        }
        
        return calculateStandardDeviation(returns)
                .multiply(BigDecimal.valueOf(100))
                .multiply(BigDecimal.valueOf(Math.sqrt(ANNUALIZATION_DAYS))); // Annualized volatility
    }

    private BigDecimal calculateStandardDeviation(List<BigDecimal> values) {
        if (values.isEmpty()) {
            return BigDecimal.ZERO;
        }
        
        // Calculate mean
        BigDecimal mean = values.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .divide(BigDecimal.valueOf(values.size()), PRECISION_SCALE, RoundingMode.HALF_UP);
        
        // Calculate variance
        BigDecimal variance = values.stream()
                .map(value -> value.subtract(mean).pow(2))
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .divide(BigDecimal.valueOf(values.size()), PRECISION_SCALE, RoundingMode.HALF_UP);
        
        return BigDecimal.valueOf(Math.sqrt(variance.doubleValue()));
    }

    private BigDecimal calculateAverage(List<ChartDataPoint> priceData, int days) {
        if (priceData == null || priceData.isEmpty()) {
            return BigDecimal.ZERO;
        }
        
        int start = Math.max(0, priceData.size() - days);
        List<ChartDataPoint> subList = priceData.subList(start, priceData.size());
        
        BigDecimal sum = subList.stream()
                .map(row -> BigDecimal.valueOf(row.getPrice()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        return sum.divide(BigDecimal.valueOf(subList.size()), PRECISION_SCALE, RoundingMode.HALF_UP);
    }

    private String formatPriceHistory(List<ChartDataPoint> priceData) {
        if (priceData == null || priceData.isEmpty()) {
            return "⚠️ No recent price history available - Analysis based on current snapshot only";
        }
        
        // Sort by timestamp to get most recent data first
        List<ChartDataPoint> sortedData = priceData.stream()
                .sorted((a, b) -> Long.compare(b.getTimestamp(), a.getTimestamp()))
                .limit(MAX_PRICE_HISTORY_ITEMS)
                .collect(Collectors.toList());
        
        StringBuilder history = new StringBuilder("📈 RECENT PRICE MOVEMENTS:\n");
        
        for (int i = 0; i < sortedData.size(); i++) {
            ChartDataPoint point = sortedData.get(i);
            LocalDateTime dateTime = Instant.ofEpochMilli(point.getTimestamp())
                    .atZone(ZoneId.systemDefault())
                    .toLocalDateTime();
            
            String timeAgo = getTimeAgo(point.getTimestamp());
            String indicator = i == 0 ? "🔴 LATEST" : (i < 3 ? "🟡 RECENT" : "🟢 EARLIER");
            
            history.append(String.format("%s: %s - $%.4f (%s)\n", 
                    indicator,
                    dateTime.format(DateTimeFormatter.ofPattern("MMM dd, HH:mm")), 
                    point.getPrice(),
                    timeAgo));
        }
        
        return history.toString();
    }
    
    private String getTimeAgo(long timestamp) {
        long now = System.currentTimeMillis();
        long diff = now - timestamp;
        
        if (diff < 60 * 1000) {
            return "Just now";
        } else if (diff < 60 * 60 * 1000) {
            return (diff / (60 * 1000)) + " min ago";
        } else if (diff < 24 * 60 * 60 * 1000) {
            return (diff / (60 * 60 * 1000)) + " hrs ago";
        } else {
            return (diff / (24 * 60 * 60 * 1000)) + " days ago";
        }
    }

    private String formatContextData(
            Cryptocurrency crypto,
            List<ChartDataPoint> priceData,
            Map<String, Double> metrics,
            int days) {
        
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        String currentDate = LocalDateTime.now().format(formatter);
        
        // Determine data freshness
        String dataFreshness = getDataFreshness(priceData);
        String marketStatus = getCurrentMarketStatus();

        // Safe access to crypto fields
        String name = safeString(crypto.getName());
        String symbol = safeString(crypto.getSymbol());
        BigDecimal price = safeBigDecimal(crypto.getPrice());
        BigDecimal marketCap = safeBigDecimal(crypto.getMarketCap());
        BigDecimal volume24h = safeBigDecimal(crypto.getVolume24h());
        BigDecimal percentChange24h = safeBigDecimal(crypto.getPercentChange24h());
        String rank = safeString(crypto.getRank());
        BigDecimal circulatingSupply = safeBigDecimal(crypto.getCirculatingSupply());

        return String.format("""
                ⏰ LIVE CRYPTO ANALYSIS CONTEXT for %s (%s) - %s
                
                🔴 REAL-TIME MARKET STATUS: %s
                📊 DATA FRESHNESS: %s
                
                💰 CURRENT MARKET DATA (Live):
                - Current Price: $%.2f
                - Market Cap: $%.2f
                - Market Rank: #%s
                - 24h Trading Volume: $%.2f
                - 24h Price Change: %.2f%%
                - 7-Day Average: $%.2f
                - 30-Day Average: $%.2f
                - Volatility Index: %.2f%%
                - Circulating Supply: %s
                - Period Price Change: %.2f%%
                - High/Low Ratio: %.2f

                📈 PRICE HISTORY ANALYSIS (%d data points over %d days):
                %s

                🎯 ANALYSIS PARAMETERS:
                - Data Quality: %s
                - Analysis Generated: %s
                - Market Context: %s Trading Day
                - Timezone: %s
                
                ⚠️ IMPORTANT: This analysis is based on the most recent available data as of %s. 
                Market conditions change rapidly in cryptocurrency markets.
                """,
                name,
                symbol,
                currentDate,
                marketStatus,
                dataFreshness,
                price.doubleValue(),
                marketCap.doubleValue(),
                rank,
                volume24h.doubleValue(),
                percentChange24h.doubleValue(),
                metrics.getOrDefault("sevenDayAvg", 0.0),
                metrics.getOrDefault("thirtyDayAvg", 0.0),
                metrics.getOrDefault("volatility", 0.0),
                formatSupply(circulatingSupply),
                metrics.getOrDefault("priceChange", 0.0),
                metrics.getOrDefault("highLowRatio", 1.0),
                priceData != null ? priceData.size() : 0,
                days,
                formatPriceHistory(priceData),
                priceData != null && !priceData.isEmpty() ? "Real-time" : "Limited/Historical",
                currentDate,
                getDayOfWeek(),
                ZoneId.systemDefault().toString(),
                currentDate
        );
    }
    
    private String getDataFreshness(List<ChartDataPoint> priceData) {
        if (priceData == null || priceData.isEmpty()) {
            return "⚠️ Limited - No recent price data available";
        }
        
        // Check if we have recent data (within last 24 hours)
        long currentTime = System.currentTimeMillis();
        long oneDayAgo = currentTime - (24 * 60 * 60 * 1000);
        
        boolean hasRecentData = priceData.stream()
                .anyMatch(point -> point.getTimestamp() > oneDayAgo);
                
        if (hasRecentData) {
            return "🟢 FRESH - Data updated within 24 hours";
        } else {
            return "🟡 HISTORICAL - Data may be older than 24 hours";
        }
    }
    
    private String getCurrentMarketStatus() {
        LocalDateTime now = LocalDateTime.now();
        int hour = now.getHour();
        
        // Crypto markets are 24/7, but we can indicate peak trading hours
        if (hour >= 8 && hour <= 17) {
            return "🌅 PEAK TRADING HOURS (Business Hours)";
        } else if (hour >= 18 && hour <= 23) {
            return "🌃 EVENING TRADING (High Activity)";
        } else {
            return "🌙 OVERNIGHT TRADING (Lower Volume)";
        }
    }
    
    private String getDayOfWeek() {
        LocalDateTime now = LocalDateTime.now();
        String dayOfWeek = now.getDayOfWeek().toString();
        return dayOfWeek.charAt(0) + dayOfWeek.substring(1).toLowerCase();
    }

    private String formatSupply(BigDecimal supply) {
        if (supply == null || supply.compareTo(BigDecimal.ZERO) == 0) {
            return "N/A";
        }
        
        // Format large numbers with appropriate suffixes
        double value = supply.doubleValue();
        if (value >= 1_000_000_000) {
            return String.format("%.2fB", value / 1_000_000_000);
        } else if (value >= 1_000_000) {
            return String.format("%.2fM", value / 1_000_000);
        } else if (value >= 1_000) {
            return String.format("%.2fK", value / 1_000);
        } else {
            return String.format("%.2f", value);
        }
    }

    private String safeString(Object obj) {
        return obj != null ? obj.toString() : DEFAULT_VALUE;
    }

    private BigDecimal safeBigDecimal(Object obj) {
        if (obj == null) {
            return BigDecimal.ZERO;
        }
        
        try {
            if (obj instanceof BigDecimal) {
                return (BigDecimal) obj;
            }
            return new BigDecimal(obj.toString());
        } catch (NumberFormatException e) {
            log.warn("Failed to parse BigDecimal: {}", obj);
            return BigDecimal.ZERO;
        }
    }
}