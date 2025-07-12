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
            testRequest.put("messages", List.of(Map.of("role", "user", "content", "Hi")));
            testRequest.put("options", Map.of(
                "num_predict", 5,
                "temperature", 0.1
            ));

            String response = webClient.post()
                    .uri(OLLAMA_API_URL)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(testRequest)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(60))
                    .onErrorResume(e -> {
                        log.warn("Ollama warmup failed: {}", e.getMessage());
                        return Mono.just("");
                    })
                    .block();
                    
            if (response != null && !response.isEmpty()) {
                log.info("Ollama connection successful - AI responses will be available");
            } else {
                log.warn("Ollama connection test returned empty response - falling back to informational responses");
            }
        } catch (Exception e) {
            log.warn("Ollama warmup failed: {} - AI will use informational fallbacks", e.getMessage());
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
            case "general" -> "🔴 **Current Market Analysis:** Real-time general market analysis is temporarily processing. The current market data is available above for your review. Key metrics and price movements are being tracked continuously.";
            case "technical" -> "📊 **Technical Analysis:** Current technical analysis is being computed. You can review the current price levels and recent data provided above. Technical indicators and trend analysis will be available shortly.";
            case "fundamental" -> "🏛️ **Fundamental Analysis:** Current fundamental analysis is being processed. The basic market metrics are shown above. Detailed fundamental insights including tokenomics and adoption metrics are being compiled.";
            case "sentiment" -> "💭 **Sentiment Analysis:** Current market sentiment analysis is being evaluated. You can review the current price movements and volume data above for immediate sentiment indicators.";
            case "risk" -> "⚠️ **Risk Assessment:** Current risk analysis is being calculated. Please review the volatility metrics above. Comprehensive risk assessment including market and technical risks will be available momentarily.";
            case "prediction" -> "🔮 **Price Predictions:** Current price predictions are being generated. The current market data is available above for manual analysis. AI-powered predictions and scenarios are being processed.";
            default -> "📈 **Analysis Processing:** Current " + type + " analysis is being generated. Please review the available market data above while detailed insights are being compiled.";
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

    /**
     * Generate AI-powered answer to user question about cryptocurrency
     */
    public CompletableFuture<String> answerCryptoQuestion(
            String symbol, 
            String question, 
            Cryptocurrency crypto,
            List<ChartDataPoint> chartDataPoints) {
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                String contextData = buildAnalysisContext(crypto, chartDataPoints, 30);
                String prompt = buildQuestionPrompt(symbol, question, contextData);
                
                return generateAnalysis("question", prompt).block();
            } catch (Exception e) {
                log.error("Failed to answer crypto question for {}: {}", symbol, e.getMessage());
                
                // Provide a helpful fallback response when AI service is not available
                return getFallbackAnswer(symbol, question, crypto);
            }
        });
    }
    
    /**
     * Generate AI-powered answer to general cryptocurrency question
     */
    public CompletableFuture<String> answerGeneralCryptoQuestion(String question) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                String prompt = buildGeneralQuestionPrompt(question);
                return generateAnalysis("general_question", prompt).block();
            } catch (Exception e) {
                log.error("Failed to answer general crypto question: {}", e.getMessage());
                return getGeneralFallbackAnswer(question);
            }
        });
    }
    
    private String buildQuestionPrompt(String symbol, String question, String contextData) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("You are a cryptocurrency expert. Answer the following question about ");
        prompt.append(symbol.toUpperCase());
        prompt.append(" based on the provided data.\n\n");
        prompt.append("QUESTION: ").append(question).append("\n\n");
        prompt.append("CRYPTOCURRENCY DATA:\n");
        prompt.append(contextData);
        prompt.append("\n\nPlease provide a comprehensive, accurate answer based on the data above. ");
        prompt.append("Use emojis and formatting to make the response engaging. ");
        prompt.append("If you don't have enough data to answer accurately, say so.");
        
        return prompt.toString();
    }
    
    private String buildGeneralQuestionPrompt(String question) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("You are a cryptocurrency expert. Answer the following general question about cryptocurrencies.\n\n");
        prompt.append("QUESTION: ").append(question).append("\n\n");
        prompt.append("Please provide a comprehensive, accurate answer. ");
        prompt.append("Use emojis and formatting to make the response engaging. ");
        prompt.append("Focus on providing educational and factual information.");
        
        return prompt.toString();
    }
    
    /**
     * Find similar cryptocurrencies using AI-powered analysis
     */
    public CompletableFuture<Map<String, Object>> findSimilarCryptocurrencies(String symbol, int limit, boolean includeAnalysis) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                log.info("Finding similar cryptocurrencies for {}", symbol);
                
                // Build similarity analysis prompt
                String prompt = buildSimilarityPrompt(symbol, limit, includeAnalysis);
                
                // Generate AI analysis for similar cryptocurrencies
                String analysis = generateAnalysis("similarity", prompt).block();
                
                // Parse and structure the response
                Map<String, Object> result = new HashMap<>();
                
                // Define potential similar cryptocurrencies based on common categories
                List<Map<String, Object>> similarCryptos = generateSimilarCryptocurrenciesList(symbol, limit);
                
                result.put("similar_cryptocurrencies", similarCryptos);
                result.put("comparison_analysis", analysis);
                result.put("similarity_criteria", getSimilarityCriteria(symbol));
                
                return result;
            } catch (Exception e) {
                log.error("Failed to find similar cryptocurrencies for {}: {}", symbol, e.getMessage());
                
                // Return fallback response
                Map<String, Object> fallback = new HashMap<>();
                fallback.put("similar_cryptocurrencies", generateSimilarCryptocurrenciesList(symbol, limit));
                fallback.put("comparison_analysis", "❌ AI analysis temporarily unavailable. Basic similarity matching applied.");
                fallback.put("similarity_criteria", getSimilarityCriteria(symbol));
                
                return fallback;
            }
        });
    }
    
    private String buildSimilarityPrompt(String symbol, int limit, boolean includeAnalysis) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("🔍 CRYPTOCURRENCY SIMILARITY ANALYSIS\n\n");
        prompt.append("Target cryptocurrency: ").append(symbol.toUpperCase()).append("\n");
        prompt.append("Number of similar cryptocurrencies to find: ").append(limit).append("\n\n");
        
        prompt.append("Please provide a comprehensive analysis of cryptocurrencies similar to ");
        prompt.append(symbol.toUpperCase()).append(" based on:\n");
        prompt.append("1. Technology and blockchain architecture\n");
        prompt.append("2. Use case and market sector\n");
        prompt.append("3. Market cap and trading volume similarity\n");
        prompt.append("4. Price volatility and performance patterns\n");
        prompt.append("5. Development activity and ecosystem\n");
        prompt.append("6. Tokenomics and supply mechanisms\n\n");
        
        if (includeAnalysis) {
            prompt.append("Include detailed comparison analysis explaining:\n");
            prompt.append("- Why these cryptocurrencies are similar\n");
            prompt.append("- Key differentiating factors\n");
            prompt.append("- Potential investment considerations\n");
            prompt.append("- Risk factors and opportunities\n\n");
        }
        
        prompt.append("Format your response with clear sections and use emojis for better readability.");
        
        return prompt.toString();
    }
    
    private List<Map<String, Object>> generateSimilarCryptocurrenciesList(String symbol, int limit) {
        List<Map<String, Object>> similarCryptos = new ArrayList<>();
        
        // Define similarity mappings based on common categories
        Map<String, List<String>> similarityMap = new HashMap<>();
        
        // Layer 1 blockchains
        similarityMap.put("BTC", Arrays.asList("ETH", "LTC", "BCH", "XRP", "ADA"));
        similarityMap.put("ETH", Arrays.asList("BTC", "ADA", "SOL", "AVAX", "DOT"));
        similarityMap.put("ADA", Arrays.asList("ETH", "DOT", "ALGO", "SOL", "AVAX"));
        similarityMap.put("SOL", Arrays.asList("ETH", "AVAX", "DOT", "NEAR", "ALGO"));
        similarityMap.put("DOT", Arrays.asList("ADA", "COSMOS", "AVAX", "NEAR", "SOL"));
        similarityMap.put("AVAX", Arrays.asList("SOL", "FANTOM", "NEAR", "DOT", "ALGO"));
        
        // DeFi tokens
        similarityMap.put("UNI", Arrays.asList("SUSHI", "CAKE", "1INCH", "DYDX", "COMP"));
        similarityMap.put("LINK", Arrays.asList("BAND", "API3", "TRB", "DIA", "FLUX"));
        similarityMap.put("AAVE", Arrays.asList("COMP", "MKR", "SNX", "CRV", "YFI"));
        
        // Meme coins
        similarityMap.put("DOGE", Arrays.asList("SHIB", "FLOKI", "PEPE", "BONK", "WIF"));
        similarityMap.put("SHIB", Arrays.asList("DOGE", "FLOKI", "PEPE", "BONK", "BABYDOGE"));
        
        // Layer 2 solutions
        similarityMap.put("MATIC", Arrays.asList("LRC", "IMX", "METIS", "BOBA", "OP"));
        similarityMap.put("LRC", Arrays.asList("MATIC", "IMX", "METIS", "BOBA", "OP"));
        
        // Privacy coins
        similarityMap.put("XMR", Arrays.asList("ZEC", "DASH", "DCR", "BEAM", "GRIN"));
        similarityMap.put("ZEC", Arrays.asList("XMR", "DASH", "DCR", "BEAM", "GRIN"));
        
        // Get similar cryptocurrencies for the given symbol
        List<String> similar = similarityMap.getOrDefault(symbol.toUpperCase(), 
                Arrays.asList("BTC", "ETH", "BNB", "ADA", "SOL"));
        
        // Create structured response
        for (int i = 0; i < Math.min(similar.size(), limit); i++) {
            Map<String, Object> crypto = new HashMap<>();
            crypto.put("symbol", similar.get(i));
            crypto.put("similarity_score", 0.85 - (i * 0.1)); // Decreasing similarity
            crypto.put("match_reasons", getMatchReasons(symbol, similar.get(i)));
            similarCryptos.add(crypto);
        }
        
        return similarCryptos;
    }
    
    private List<String> getMatchReasons(String originalSymbol, String similarSymbol) {
        List<String> reasons = new ArrayList<>();
        
        // Define match reasons based on symbol pairs
        Map<String, Map<String, List<String>>> matchReasons = new HashMap<>();
        
        // BTC similarities
        Map<String, List<String>> btcReasons = new HashMap<>();
        btcReasons.put("ETH", Arrays.asList("Store of value", "High market cap", "Institutional adoption"));
        btcReasons.put("LTC", Arrays.asList("Similar technology", "Proof of Work", "Digital silver narrative"));
        btcReasons.put("BCH", Arrays.asList("Bitcoin fork", "Similar consensus", "Payment focus"));
        matchReasons.put("BTC", btcReasons);
        
        // ETH similarities
        Map<String, List<String>> ethReasons = new HashMap<>();
        ethReasons.put("ADA", Arrays.asList("Smart contracts", "Proof of Stake", "DeFi ecosystem"));
        ethReasons.put("SOL", Arrays.asList("Smart contracts", "DeFi protocols", "NFT marketplace"));
        ethReasons.put("DOT", Arrays.asList("Interoperability", "Ecosystem development", "Governance"));
        matchReasons.put("ETH", ethReasons);
        
        // Get specific reasons or fallback to generic ones
        String upper = originalSymbol.toUpperCase();
        if (matchReasons.containsKey(upper) && matchReasons.get(upper).containsKey(similarSymbol)) {
            reasons = matchReasons.get(upper).get(similarSymbol);
        } else {
            reasons = Arrays.asList("Market sector similarity", "Similar use cases", "Comparable market position");
        }
        
        return reasons;
    }
    
    private List<String> getSimilarityCriteria(String symbol) {
        return Arrays.asList(
            "Technology and blockchain architecture",
            "Use case and market sector",
            "Market capitalization range",
            "Trading volume patterns",
            "Price volatility characteristics",
            "Development activity level",
            "Ecosystem maturity",
            "Tokenomics structure"
        );
    }
    
    /**
     * Provide a fallback answer when AI service is not available
     */
    private String getFallbackAnswer(String symbol, String question, Cryptocurrency crypto) {
        // Try once more before falling back
        try {
            log.info("Attempting one more time to get AI response for {}", symbol);
            String contextData = buildAnalysisContext(crypto, Collections.emptyList(), 30);
            String prompt = buildQuestionPrompt(symbol, question, contextData);
            String result = generateAnalysis("question", prompt).block();
            if (result != null && !result.trim().isEmpty()) {
                return result;
            }
        } catch (Exception retryException) {
            log.warn("Retry attempt failed for {}: {}", symbol, retryException.getMessage());
        }
        
        StringBuilder response = new StringBuilder();
        
        if (crypto != null) {
            // Provide basic information about the cryptocurrency without fallback indicators
            response.append("📊 **").append(symbol.toUpperCase()).append(" Current Data:**\n");
            response.append("• Current Price: $").append(String.format("%.2f", crypto.getPrice())).append("\n");
            
            if (crypto.getPercentChange24h() != null) {
                double changePercent = crypto.getPercentChange24h().doubleValue();
                String changeIcon = changePercent >= 0 ? "📈" : "📉";
                response.append("• 24h Change: ").append(changeIcon).append(" ")
                         .append(String.format("%.2f%%", changePercent)).append("\n");
            }
            
            if (crypto.getMarketCap() != null) {
                response.append("• Market Cap: $").append(formatLargeNumber(crypto.getMarketCap().doubleValue())).append("\n");
            }
            
            if (crypto.getVolume24h() != null) {
                response.append("• 24h Volume: $").append(formatLargeNumber(crypto.getVolume24h().doubleValue())).append("\n");
            }
            
            response.append("\n");
        }
        
        // Provide question-specific responses without mentioning fallback
        String lowerQuestion = question.toLowerCase();
        if (lowerQuestion.contains("buy") || lowerQuestion.contains("invest")) {
            response.append("💡 **Investment Guidance:**\n");
            response.append("• Research thoroughly before making any investment decisions\n");
            response.append("• Consider your risk tolerance and financial goals\n");
            response.append("• Diversify across different assets and sectors\n");
            response.append("• Only invest amounts you can afford to lose\n");
            response.append("• Stay updated with market trends and regulatory changes\n");
        } else if (lowerQuestion.contains("price") || lowerQuestion.contains("forecast")) {
            response.append("📈 **Price Analysis Insights:**\n");
            response.append("• Cryptocurrency markets are highly volatile and unpredictable\n");
            response.append("• Price movements are influenced by market sentiment, adoption, and news\n");
            response.append("• Technical analysis can help identify trends and patterns\n");
            response.append("• Consider multiple factors including fundamentals and market cycles\n");
        } else if (lowerQuestion.contains("technology") || lowerQuestion.contains("how")) {
            response.append("⚙️ **Technology Overview:**\n");
            response.append("• Each cryptocurrency has unique technological features\n");
            response.append("• Check the official documentation and whitepaper\n");
            response.append("• Review the consensus mechanism and security model\n");
            response.append("• Evaluate real-world use cases and adoption potential\n");
        } else if (lowerQuestion.contains("risk")) {
            response.append("⚠️ **Risk Considerations:**\n");
            response.append("• Cryptocurrency investments carry significant risks\n");
            response.append("• Market volatility can result in substantial losses\n");
            response.append("• Regulatory changes may impact cryptocurrency values\n");
            response.append("• Technology risks and security vulnerabilities exist\n");
        } else {
            response.append("ℹ️ **").append(symbol.toUpperCase()).append(" Information:**\n");
            response.append("• ").append(symbol.toUpperCase()).append(" is an active cryptocurrency in the market\n");
            response.append("• Monitor official announcements and community updates\n");
            response.append("• Join verified communities for discussions and insights\n");
            response.append("• Track market performance and trading metrics\n");
        }
        
        return response.toString();
    }
    
    /**
     * Provide a fallback answer for general cryptocurrency questions
     */
    private String getGeneralFallbackAnswer(String question) {
        // Try once more with a simpler prompt before falling back
        try {
            log.info("Attempting one more time to get AI response for general question");
            String simplePrompt = "Answer this cryptocurrency question briefly: " + question;
            String result = generateAnalysis("general_question", simplePrompt).block();
            if (result != null && !result.trim().isEmpty()) {
                return result;
            }
        } catch (Exception retryException) {
            log.warn("Retry attempt failed for general question: {}", retryException.getMessage());
        }
        
        StringBuilder response = new StringBuilder();
        
        String lowerQuestion = question.toLowerCase();
        
        if (lowerQuestion.contains("bitcoin") || lowerQuestion.contains("btc")) {
            response.append("₿ **Bitcoin Information:**\n");
            response.append("• First and most established cryptocurrency\n");
            response.append("• Created by Satoshi Nakamoto in 2009\n");
            response.append("• Uses Proof of Work consensus mechanism\n");
            response.append("• Limited supply of 21 million coins\n");
            response.append("• Often considered digital gold and store of value\n");
        } else if (lowerQuestion.contains("ethereum") || lowerQuestion.contains("eth")) {
            response.append("🔷 **Ethereum Information:**\n");
            response.append("• Smart contract platform and cryptocurrency\n");
            response.append("• Enables decentralized applications (DApps)\n");
            response.append("• Transitioned to Proof of Stake (Ethereum 2.0)\n");
            response.append("• Second largest cryptocurrency by market cap\n");
            response.append("• Foundation for most DeFi and NFT projects\n");
        } else if (lowerQuestion.contains("defi") || lowerQuestion.contains("decentralized finance")) {
            response.append("🏦 **DeFi Information:**\n");
            response.append("• Decentralized Finance protocols\n");
            response.append("• Enables lending, borrowing, and trading without intermediaries\n");
            response.append("• Built primarily on Ethereum and other smart contract platforms\n");
            response.append("• Offers various financial services in a decentralized manner\n");
            response.append("• Includes DEXs, lending protocols, and yield farming\n");
        } else if (lowerQuestion.contains("nft") || lowerQuestion.contains("non-fungible")) {
            response.append("🎨 **NFT Information:**\n");
            response.append("• Non-Fungible Tokens represent unique digital assets\n");
            response.append("• Used for digital art, collectibles, and gaming items\n");
            response.append("• Each NFT has a unique identifier on the blockchain\n");
            response.append("• Can be bought, sold, and traded on various marketplaces\n");
            response.append("• Provide proof of ownership and authenticity\n");
        } else if (lowerQuestion.contains("blockchain")) {
            response.append("⛓️ **Blockchain Information:**\n");
            response.append("• Distributed ledger technology\n");
            response.append("• Records transactions across multiple computers\n");
            response.append("• Provides transparency and immutability\n");
            response.append("• Foundation for cryptocurrencies and many applications\n");
            response.append("• Enables trustless and decentralized systems\n");
        } else if (lowerQuestion.contains("mining")) {
            response.append("⛏️ **Cryptocurrency Mining:**\n");
            response.append("• Process of validating transactions and creating new blocks\n");
            response.append("• Miners compete to solve cryptographic puzzles\n");
            response.append("• Requires computational power and energy\n");
            response.append("• Miners are rewarded with cryptocurrency\n");
            response.append("• Helps secure the blockchain network\n");
        } else if (lowerQuestion.contains("wallet")) {
            response.append("👛 **Cryptocurrency Wallets:**\n");
            response.append("• Software or hardware that stores your cryptocurrencies\n");
            response.append("• Hot wallets: Connected to internet (convenient but less secure)\n");
            response.append("• Cold wallets: Offline storage (more secure for long-term holding)\n");
            response.append("• Always keep your private keys secure and backed up\n");
            response.append("• Never share your private keys or seed phrases\n");
        } else if (lowerQuestion.contains("invest") || lowerQuestion.contains("trading")) {
            response.append("💰 **Investment and Trading:**\n");
            response.append("• Cryptocurrency markets operate 24/7\n");
            response.append("• High volatility presents both opportunities and risks\n");
            response.append("• Research thoroughly before making investment decisions\n");
            response.append("• Consider dollar-cost averaging for long-term investments\n");
            response.append("• Use proper risk management and position sizing\n");
        } else {
            response.append("💰 **General Cryptocurrency Information:**\n");
            response.append("• Cryptocurrencies are digital assets secured by cryptography\n");
            response.append("• They operate on decentralized blockchain networks\n");
            response.append("• Enable peer-to-peer transactions without intermediaries\n");
            response.append("• Market is highly innovative but volatile\n");
            response.append("• Research and understand before participating\n");
        }
        
        response.append("\n📚 **Learn More:**\n");
        response.append("• Visit official project websites and documentation\n");
        response.append("• Follow reputable cryptocurrency news sources\n");
        response.append("• Join community discussions and educational forums\n");
        response.append("• Consider educational resources and courses\n");
        
        response.append("\n⚠️ **Disclaimer:** This is general information only. ");
        response.append("Always conduct your own research and consider your risk tolerance!");
        
        return response.toString();
    }
    
    private String formatLargeNumber(Double number) {
        if (number == null) return "N/A";
        
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