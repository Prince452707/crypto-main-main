package crypto.insight.crypto.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
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
import lombok.RequiredArgsConstructor;
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
@RequiredArgsConstructor
public class AIService {
    
    // Constants
    private static final int MAX_PRICE_HISTORY_ITEMS = 10;
    private static final int PRECISION_SCALE = 6;
    private static final int ANNUALIZATION_DAYS = 365;
    private static final String OLLAMA_API_URL = "http://localhost:11434/api/chat";
    private static final int MAX_RETRIES = 2;
    private static final String DEFAULT_VALUE = "N/A";
    private static final int MAX_TOKENS = 2000; // Increased token limit for more complete responses
    
    private final WebClient webClient;
    private final String modelName;
    private final ObjectMapper objectMapper;
    private static final Duration TIMEOUT_DURATION = Duration.ofSeconds(180);

    @Autowired
    public AIService(WebClient.Builder webClientBuilder, 
                    @Value("${spring.ai.ollama.model}") String modelName,
                    ObjectMapper objectMapper) {
        this.modelName = modelName;
        this.objectMapper = objectMapper;
        this.webClient = webClientBuilder
                .baseUrl("http://localhost:11434")
                .build();
    }

    @PostConstruct
    public void init() {
        log.info("AIService initialized with model: {}", modelName);
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
                
                // Generate different types of analysis
                analysis.put("general", generateAnalysis("general", contextData).block());
                analysis.put("technical", generateAnalysis("technical", contextData).block());
                analysis.put("fundamental", generateAnalysis("fundamental", contextData).block());
                analysis.put("news", generateAnalysis("news", contextData).block());
                analysis.put("sentiment", generateAnalysis("sentiment", contextData).block());
                analysis.put("risk", generateAnalysis("risk", contextData).block());
                analysis.put("prediction", generateAnalysis("prediction", contextData).block());
                
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
        return "Provide a comprehensive general market analysis (at least 3 paragraphs) for the following cryptocurrency data. " +
               "Focus on overall market trends, position in the market, and key highlights. " +
               "Structure your response with clear sections and ensure it's complete. " +
               "If any data is missing, acknowledge it and provide analysis based on available information.\n\n" +
               contextData +
               "\n\nIMPORTANT: Your response must be complete and well-structured. " +
               "Do not end mid-sentence or thought. Ensure all sections are properly closed.";
    }

    private String buildTechnicalPrompt(String contextData) {
        return "Perform a detailed technical analysis (at least 3 paragraphs) including:\n" +
               "1. Price patterns and trends\n" +
               "2. Key support/resistance levels\n" +
               "3. Moving averages and indicators\n" +
               "4. Volume analysis\n" +
               "5. Trading signals and potential entry/exit points\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: Provide concrete price levels and specific technical observations. " +
               "If any data is missing, state what's missing but still provide the most complete analysis possible. " +
               "Ensure your response is complete and well-structured.";
    }

    private String buildFundamentalPrompt(String contextData) {
        return "Provide a thorough fundamental analysis (at least 3 paragraphs) covering:\n" +
               "1. Market cap analysis and position\n" +
               "2. Tokenomics and supply metrics\n" +
               "3. Adoption and network activity\n" +
               "4. Team and development activity\n" +
               "5. Competitive landscape\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: Include specific metrics and comparisons where possible. " +
               "Acknowledge any missing data but still provide the most complete analysis possible. " +
               "Ensure your response is comprehensive and well-structured.";
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
        return "Evaluate the current market sentiment and investor behavior (at least 3 paragraphs). Analyze:\n" +
               "1. Price action and volume trends\n" +
               "2. Social media and community sentiment\n" +
               "3. On-chain metrics (if available)\n" +
               "4. Market psychology and positioning\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: Provide specific observations about market sentiment. " +
               "If certain data points are missing, focus on the available information. " +
               "Ensure your response is complete and well-structured.";
    }

    private String buildRiskPrompt(String contextData) {
        return "Provide a comprehensive risk assessment (at least 3 paragraphs) covering:\n" +
               "1. Volatility and price risks\n" +
               "2. Market and liquidity risks\n" +
               "3. Regulatory and compliance risks\n" +
               "4. Protocol and smart contract risks\n" +
               "5. Competitive risks\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: Be specific about potential risk factors and their likelihood/impact. " +
               "Acknowledge any data limitations but still provide a complete analysis. " +
               "Ensure your response is thorough and well-structured.";
    }

    private String buildPredictionPrompt(String contextData) {
        return "Generate informed price predictions and scenarios (at least 3 paragraphs). Include:\n" +
               "1. Short-term outlook (1-2 weeks)\n" +
               "2. Medium-term outlook (1-6 months)\n" +
               "3. Key price levels to watch\n" +
               "4. Potential upside and downside scenarios\n\n" +
               "For: " + contextData + "\n\n" +
               "IMPORTANT: Provide specific price targets and confidence levels. " +
               "Acknowledge the limitations of predictions but still offer concrete analysis. " +
               "Ensure your response is complete and well-structured.";
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
            return "No price history available";
        }
        
        return priceData.stream()
                .limit(MAX_PRICE_HISTORY_ITEMS)
                .map(point -> String.format("%s: $%.2f",
                        Instant.ofEpochMilli(point.getTimestamp())
                                .atZone(ZoneId.systemDefault())
                                .format(DateTimeFormatter.ofPattern("yyyy-MM-dd")),
                        point.getPrice()))
                .collect(Collectors.joining("\n"));
    }

    private String formatContextData(
            Cryptocurrency crypto,
            List<ChartDataPoint> priceData,
            Map<String, Double> metrics,
            int days) {
        
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        String currentDate = LocalDateTime.now().format(formatter);

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
                ANALYSIS CONTEXT for %s (%s) - %s

                CURRENT MARKET DATA:
                - Current Price: $%.2f
                - Market Cap: $%.2f
                - Rank: %s
                - 24h Volume: $%.2f
                - 24h Change: %.2f%%
                - 7d Average Price: $%.2f
                - 30d Average Price: $%.2f
                - Volatility (%d days): %.2f%%
                - Circulating Supply: %s
                - Price Change (Period): %.2f%%
                - High/Low Ratio: %.2f

                PRICE HISTORY (%d data points over %d days):
                %s

                ADDITIONAL METRICS:
                - Data Quality: %s
                - Analysis Timestamp: %s
                """,
                name,
                symbol,
                currentDate,
                price.doubleValue(),
                marketCap.doubleValue(),
                rank,
                volume24h.doubleValue(),
                percentChange24h.doubleValue(),
                metrics.getOrDefault("sevenDayAvg", 0.0),
                metrics.getOrDefault("thirtyDayAvg", 0.0),
                days,
                metrics.getOrDefault("volatility", 0.0),
                formatSupply(circulatingSupply),
                metrics.getOrDefault("priceChange", 0.0),
                metrics.getOrDefault("highLowRatio", 1.0),
                priceData != null ? priceData.size() : 0,
                days,
                formatPriceHistory(priceData),
                priceData != null && !priceData.isEmpty() ? "Good" : "Limited",
                currentDate
        );
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