package crypto.insight.crypto.controller;

import crypto.insight.crypto.model.ApiResponse;
import crypto.insight.crypto.model.ChartDataPoint;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.EnhancedAIQAService;
import crypto.insight.crypto.service.EnhancedSimilarCoinService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Enhanced AI Controller with perfect AI Q&A and similar coin recommendations
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/ai")
@CrossOrigin(originPatterns = "*", allowCredentials = "true")
public class EnhancedAIController {

    private final EnhancedAIQAService enhancedAIQAService;
    private final EnhancedSimilarCoinService enhancedSimilarCoinService;
    private final ApiService apiService;

    public EnhancedAIController(
            EnhancedAIQAService enhancedAIQAService,
            EnhancedSimilarCoinService enhancedSimilarCoinService,
            ApiService apiService) {
        this.enhancedAIQAService = enhancedAIQAService;
        this.enhancedSimilarCoinService = enhancedSimilarCoinService;
        this.apiService = apiService;
    }

    /**
     * Enhanced AI Q&A for specific cryptocurrency
     */
    @PostMapping("/crypto/question/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> askCryptoQuestionEnhanced(
            @PathVariable String symbol,
            @RequestBody Map<String, String> request) {
        
        log.info("Enhanced AI Q&A request for symbol: {}", symbol);
        
        String question = request.get("question");
        if (question == null || question.trim().isEmpty()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Question is required")));
        }
        
        return apiService.getCryptocurrencyData(symbol, 30, false)
                .flatMap(crypto -> {
                    // Get chart data
                    Mono<List<ChartDataPoint>> chartDataMono = apiService.getMarketChart(symbol, 30, false)
                            .map(chartData -> {
                                Object pricesObj = chartData.get("prices");
                                if (pricesObj instanceof List) {
                                    return ((List<?>) pricesObj).stream()
                                            .filter(List.class::isInstance)
                                            .map(point -> (List<?>) point)
                                            .filter(point -> point.size() >= 2)
                                            .map(point -> new ChartDataPoint(
                                                    ((Number) point.get(0)).longValue(),
                                                    ((Number) point.get(1)).doubleValue()
                                            ))
                                            .collect(Collectors.toList());
                                }
                                return Collections.<ChartDataPoint>emptyList();
                            })
                            .onErrorResume(e -> {
                                log.warn("Chart data not available for {}: {}", symbol, e.getMessage());
                                return Mono.just(Collections.emptyList());
                            });
                    
                    return chartDataMono.flatMap(chartData -> {
                        return Mono.fromFuture(enhancedAIQAService.answerCryptoQuestionEnhanced(
                                symbol, question, crypto, chartData))
                                .map(response -> {
                                    return ResponseEntity.ok(ApiResponse.success(response, "Enhanced AI answer generated successfully"));
                                });
                    });
                })
                .onErrorResume(e -> {
                    log.error("Enhanced AI Q&A failed for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Enhanced AI Q&A failed: " + e.getMessage())));
                });
    }

    /**
     * Enhanced AI Q&A for general cryptocurrency questions
     */
    @PostMapping("/crypto/question")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> askGeneralCryptoQuestionEnhanced(
            @RequestBody Map<String, String> request) {
        
        log.info("Enhanced general AI Q&A request");
        
        String question = request.get("question");
        if (question == null || question.trim().isEmpty()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Question is required")));
        }
        
        return Mono.fromFuture(enhancedAIQAService.answerGeneralQuestionEnhanced(question))
                .map(response -> {
                    return ResponseEntity.ok(ApiResponse.success(response, "Enhanced general AI answer generated successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Enhanced general AI Q&A failed: {}", e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Enhanced general AI Q&A failed: " + e.getMessage())));
                });
    }

    /**
     * Enhanced similar cryptocurrency recommendations
     */
    @GetMapping("/crypto/similar/{symbol}")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> findSimilarCryptocurrenciesEnhanced(
            @PathVariable String symbol,
            @RequestParam(defaultValue = "5") int limit,
            @RequestParam(defaultValue = "true") boolean includeAnalysis,
            @RequestParam(defaultValue = "false") boolean includeMarketData) {
        
        log.info("Enhanced similar cryptocurrencies request for: {}, limit: {}, analysis: {}, market data: {}", 
                symbol, limit, includeAnalysis, includeMarketData);
        
        if (limit < 1 || limit > 20) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Limit must be between 1 and 20")));
        }
        
        return Mono.fromFuture(enhancedSimilarCoinService.findSimilarCryptocurrenciesEnhanced(
                symbol, limit, includeAnalysis, includeMarketData))
                .map(response -> {
                    return ResponseEntity.ok(ApiResponse.success(response, "Enhanced similar cryptocurrencies found successfully"));
                })
                .onErrorResume(e -> {
                    log.error("Enhanced similar cryptocurrencies search failed for {}: {}", symbol, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponse.error("Enhanced similar cryptocurrencies search failed: " + e.getMessage())));
                });
    }

    /**
     * AI-powered cryptocurrency comparison
     */
    @PostMapping("/crypto/compare")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> compareCryptocurrencies(
            @RequestBody Map<String, Object> request) {
        
        log.info("AI cryptocurrency comparison request");
        
        @SuppressWarnings("unchecked")
        List<String> symbols = (List<String>) request.get("symbols");
        if (symbols == null || symbols.size() < 2 || symbols.size() > 5) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Please provide between 2 and 5 cryptocurrency symbols for comparison")));
        }
        
        return Mono.fromFuture(java.util.concurrent.CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> comparison = new HashMap<>();
                comparison.put("symbols", symbols);
                comparison.put("comparison_type", "AI-Powered Analysis");
                comparison.put("timestamp", System.currentTimeMillis());
                
                // Generate comparison analysis
                String comparisonAnalysis = generateComparisonAnalysis(symbols);
                comparison.put("analysis", comparisonAnalysis);
                
                // Get similarity scores between all pairs
                List<Map<String, Object>> similarityMatrix = generateSimilarityMatrix(symbols);
                comparison.put("similarity_matrix", similarityMatrix);
                
                // Provide investment insights
                Map<String, Object> insights = generateInvestmentInsights(symbols);
                comparison.put("insights", insights);
                
                return comparison;
            } catch (Exception e) {
                log.error("Cryptocurrency comparison failed: {}", e.getMessage());
                throw new RuntimeException("Comparison analysis failed", e);
            }
        }))
        .map(response -> {
            return ResponseEntity.ok(ApiResponse.success(response, "Cryptocurrency comparison completed successfully"));
        })
        .onErrorResume(e -> {
            log.error("AI cryptocurrency comparison failed: {}", e.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("AI cryptocurrency comparison failed: " + e.getMessage())));
        });
    }

    /**
     * AI-powered investment recommendation
     */
    @PostMapping("/crypto/recommend")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getInvestmentRecommendations(
            @RequestBody Map<String, Object> request) {
        
        log.info("AI investment recommendation request");
        
        String riskTolerance = (String) request.get("risk_tolerance");
        String investmentType = (String) request.get("investment_type");
        Double budgetRange = (Double) request.get("budget_range");
        
        if (riskTolerance == null || investmentType == null) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("Risk tolerance and investment type are required")));
        }
        
        return Mono.fromFuture(java.util.concurrent.CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> recommendations = new HashMap<>();
                recommendations.put("risk_tolerance", riskTolerance);
                recommendations.put("investment_type", investmentType);
                recommendations.put("budget_range", budgetRange);
                recommendations.put("timestamp", System.currentTimeMillis());
                
                // Generate personalized recommendations
                List<Map<String, Object>> recommendedCoins = generatePersonalizedRecommendations(
                        riskTolerance, investmentType, budgetRange);
                recommendations.put("recommended_cryptocurrencies", recommendedCoins);
                
                // Generate investment strategy
                String strategy = generateInvestmentStrategy(riskTolerance, investmentType, budgetRange);
                recommendations.put("investment_strategy", strategy);
                
                // Risk warnings
                List<String> riskWarnings = generateRiskWarnings(riskTolerance);
                recommendations.put("risk_warnings", riskWarnings);
                
                return recommendations;
            } catch (Exception e) {
                log.error("Investment recommendation failed: {}", e.getMessage());
                throw new RuntimeException("Investment recommendation failed", e);
            }
        }))
        .map(response -> {
            return ResponseEntity.ok(ApiResponse.success(response, "Investment recommendations generated successfully"));
        })
        .onErrorResume(e -> {
            log.error("AI investment recommendation failed: {}", e.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("AI investment recommendation failed: " + e.getMessage())));
        });
    }

    /**
     * Get AI service health and capabilities
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAIServiceHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "operational");
        health.put("timestamp", System.currentTimeMillis());
        health.put("features", Arrays.asList(
                "Enhanced Q&A",
                "Similar Coin Recommendations",
                "Cryptocurrency Comparison",
                "Investment Recommendations",
                "Intelligent Question Analysis",
                "Cached Responses"
        ));
        health.put("version", "2.0");
        
        return ResponseEntity.ok(ApiResponse.success(health, "AI service is operational"));
    }

    // Helper methods for AI analysis
    private String generateComparisonAnalysis(List<String> symbols) {
        StringBuilder analysis = new StringBuilder();
        
        analysis.append("🔍 **Cryptocurrency Comparison Analysis**\n\n");
        analysis.append("**Comparing:** ").append(String.join(", ", symbols)).append("\n\n");
        
        analysis.append("**📊 Analysis Overview:**\n");
        analysis.append("• Each cryptocurrency has unique characteristics and use cases\n");
        analysis.append("• Market positioning and technology differ significantly\n");
        analysis.append("• Risk profiles vary based on market cap, adoption, and development activity\n");
        analysis.append("• Consider your investment goals and risk tolerance\n\n");
        
        analysis.append("**💡 Key Considerations:**\n");
        for (String symbol : symbols) {
            analysis.append("• **").append(symbol.toUpperCase()).append("** - ");
            analysis.append(getCryptoDescription(symbol)).append("\n");
        }
        
        analysis.append("\n**⚠️ Important Notes:**\n");
        analysis.append("• This analysis is for educational purposes only\n");
        analysis.append("• Always conduct your own research\n");
        analysis.append("• Cryptocurrency investments carry significant risks\n");
        analysis.append("• Past performance doesn't guarantee future results\n");
        
        return analysis.toString();
    }

    private List<Map<String, Object>> generateSimilarityMatrix(List<String> symbols) {
        List<Map<String, Object>> matrix = new ArrayList<>();
        
        for (int i = 0; i < symbols.size(); i++) {
            for (int j = i + 1; j < symbols.size(); j++) {
                Map<String, Object> similarity = new HashMap<>();
                similarity.put("pair", Arrays.asList(symbols.get(i), symbols.get(j)));
                similarity.put("similarity_score", calculateSimilarityScore(symbols.get(i), symbols.get(j)));
                similarity.put("relationship", getRelationshipType(symbols.get(i), symbols.get(j)));
                matrix.add(similarity);
            }
        }
        
        return matrix;
    }

    private Map<String, Object> generateInvestmentInsights(List<String> symbols) {
        Map<String, Object> insights = new HashMap<>();
        
        insights.put("portfolio_diversification", "Consider different categories for better diversification");
        insights.put("risk_assessment", "Mixed risk profile - some high-risk, some established assets");
        insights.put("market_correlation", "Some assets may move together during market events");
        insights.put("recommendation", "Research each asset individually and consider your risk tolerance");
        
        return insights;
    }

    private List<Map<String, Object>> generatePersonalizedRecommendations(
            String riskTolerance, String investmentType, Double budgetRange) {
        List<Map<String, Object>> recommendations = new ArrayList<>();
        
        // Generate recommendations based on risk tolerance
        List<String> recommendedSymbols = getRecommendedSymbols(riskTolerance, investmentType);
        
        for (String symbol : recommendedSymbols) {
            Map<String, Object> recommendation = new HashMap<>();
            recommendation.put("symbol", symbol);
            recommendation.put("reason", getRecommendationReason(symbol, riskTolerance, investmentType));
            recommendation.put("risk_level", getRiskLevel(symbol));
            recommendation.put("investment_type", getInvestmentType(symbol));
            recommendation.put("allocation_suggestion", getAllocationSuggestion(symbol, riskTolerance));
            recommendations.add(recommendation);
        }
        
        return recommendations;
    }

    private String generateInvestmentStrategy(String riskTolerance, String investmentType, Double budgetRange) {
        StringBuilder strategy = new StringBuilder();
        
        strategy.append("🎯 **Personalized Investment Strategy**\n\n");
        strategy.append("**Risk Profile:** ").append(riskTolerance).append("\n");
        strategy.append("**Investment Type:** ").append(investmentType).append("\n");
        if (budgetRange != null) {
            strategy.append("**Budget Range:** $").append(String.format("%.2f", budgetRange)).append("\n");
        }
        strategy.append("\n");
        
        switch (riskTolerance.toLowerCase()) {
            case "low":
                strategy.append("**Conservative Strategy:**\n");
                strategy.append("• Focus on established cryptocurrencies (BTC, ETH)\n");
                strategy.append("• Dollar-cost averaging for reduced volatility\n");
                strategy.append("• Long-term holding approach\n");
                strategy.append("• Limit exposure to 5-10% of total portfolio\n");
                break;
            case "medium":
                strategy.append("**Balanced Strategy:**\n");
                strategy.append("• Mix of established and emerging cryptocurrencies\n");
                strategy.append("• Diversification across different sectors\n");
                strategy.append("• Regular portfolio rebalancing\n");
                strategy.append("• Moderate position sizing\n");
                break;
            case "high":
                strategy.append("**Aggressive Strategy:**\n");
                strategy.append("• Include smaller cap and emerging tokens\n");
                strategy.append("• Active trading and position management\n");
                strategy.append("• Higher allocation to crypto assets\n");
                strategy.append("• Stay informed about market developments\n");
                break;
        }
        
        strategy.append("\n**⚠️ Risk Management:**\n");
        strategy.append("• Never invest more than you can afford to lose\n");
        strategy.append("• Use stop-loss orders to limit downside\n");
        strategy.append("• Diversify across different asset classes\n");
        strategy.append("• Keep up with regulatory developments\n");
        
        return strategy.toString();
    }

    private List<String> generateRiskWarnings(String riskTolerance) {
        List<String> warnings = new ArrayList<>();
        
        warnings.add("Cryptocurrency investments are highly volatile and risky");
        warnings.add("Past performance does not guarantee future results");
        warnings.add("Regulatory changes can significantly impact cryptocurrency values");
        warnings.add("Only invest what you can afford to lose completely");
        warnings.add("Consider consulting with a qualified financial advisor");
        
        if ("high".equals(riskTolerance.toLowerCase())) {
            warnings.add("High-risk investments can lead to significant losses");
            warnings.add("Smaller cap cryptocurrencies are extremely volatile");
            warnings.add("Consider position sizing and risk management strategies");
        }
        
        return warnings;
    }

    // Helper methods for crypto analysis
    private String getCryptoDescription(String symbol) {
        switch (symbol.toUpperCase()) {
            case "BTC":
                return "Digital gold, store of value, first cryptocurrency";
            case "ETH":
                return "Smart contract platform, DeFi ecosystem foundation";
            case "ADA":
                return "Proof-of-stake blockchain, academic research focus";
            case "SOL":
                return "High-performance blockchain, low transaction costs";
            case "DOT":
                return "Interoperability focused, parachain ecosystem";
            case "AVAX":
                return "Avalanche consensus, subnet architecture";
            case "MATIC":
                return "Ethereum Layer 2 scaling solution";
            case "LINK":
                return "Decentralized oracle network";
            case "UNI":
                return "Leading decentralized exchange token";
            case "AAVE":
                return "Decentralized lending and borrowing protocol";
            default:
                return "Cryptocurrency with unique features and use cases";
        }
    }

    private double calculateSimilarityScore(String symbol1, String symbol2) {
        // Simplified similarity calculation
        if (symbol1.equals(symbol2)) return 1.0;
        
        // Same category bonus
        if (isSameCategory(symbol1, symbol2)) return 0.8;
        
        // Related category
        if (isRelatedCategory(symbol1, symbol2)) return 0.6;
        
        return 0.3; // Base similarity
    }

    private String getRelationshipType(String symbol1, String symbol2) {
        if (isSameCategory(symbol1, symbol2)) return "Same Category";
        if (isRelatedCategory(symbol1, symbol2)) return "Related Category";
        return "Different Categories";
    }

    private boolean isSameCategory(String symbol1, String symbol2) {
        return getCryptoCategory(symbol1).equals(getCryptoCategory(symbol2));
    }

    private boolean isRelatedCategory(String symbol1, String symbol2) {
        String cat1 = getCryptoCategory(symbol1);
        String cat2 = getCryptoCategory(symbol2);
        
        return (cat1.equals("Layer 1") && cat2.equals("DeFi")) ||
               (cat1.equals("DeFi") && cat2.equals("Layer 2")) ||
               (cat1.equals("Layer 1") && cat2.equals("Layer 2"));
    }

    private String getCryptoCategory(String symbol) {
        switch (symbol.toUpperCase()) {
            case "BTC":
            case "ETH":
            case "ADA":
            case "SOL":
            case "DOT":
            case "AVAX":
                return "Layer 1";
            case "UNI":
            case "AAVE":
            case "COMP":
            case "MKR":
            case "SNX":
                return "DeFi";
            case "MATIC":
            case "LRC":
            case "IMX":
                return "Layer 2";
            case "LINK":
            case "BAND":
            case "API3":
                return "Oracle";
            case "DOGE":
            case "SHIB":
            case "FLOKI":
                return "Meme";
            default:
                return "Other";
        }
    }

    private List<String> getRecommendedSymbols(String riskTolerance, String investmentType) {
        switch (riskTolerance.toLowerCase()) {
            case "low":
                return Arrays.asList("BTC", "ETH");
            case "medium":
                return Arrays.asList("BTC", "ETH", "ADA", "SOL", "DOT");
            case "high":
                return Arrays.asList("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE");
            default:
                return Arrays.asList("BTC", "ETH", "ADA");
        }
    }

    private String getRecommendationReason(String symbol, String riskTolerance, String investmentType) {
        switch (symbol.toUpperCase()) {
            case "BTC":
                return "Digital gold, store of value, suitable for all risk profiles";
            case "ETH":
                return "Smart contract leader, strong ecosystem, moderate risk";
            case "ADA":
                return "Academic approach, proof-of-stake, growing ecosystem";
            case "SOL":
                return "High performance, growing DeFi ecosystem, higher risk/reward";
            case "DOT":
                return "Interoperability focus, parachain ecosystem, moderate risk";
            default:
                return "Fits your risk profile and investment strategy";
        }
    }

    private String getRiskLevel(String symbol) {
        switch (symbol.toUpperCase()) {
            case "BTC":
            case "ETH":
                return "Medium";
            case "ADA":
            case "SOL":
            case "DOT":
                return "Medium-High";
            case "AVAX":
            case "MATIC":
            case "LINK":
                return "High";
            case "UNI":
            case "AAVE":
                return "High";
            default:
                return "Very High";
        }
    }

    private String getInvestmentType(String symbol) {
        switch (symbol.toUpperCase()) {
            case "BTC":
                return "Store of Value";
            case "ETH":
                return "Platform/Utility";
            case "ADA":
            case "SOL":
            case "DOT":
            case "AVAX":
                return "Platform/Growth";
            case "MATIC":
            case "LINK":
                return "Utility";
            case "UNI":
            case "AAVE":
                return "DeFi/Yield";
            default:
                return "Speculative";
        }
    }

    private String getAllocationSuggestion(String symbol, String riskTolerance) {
        switch (riskTolerance.toLowerCase()) {
            case "low":
                return symbol.equals("BTC") ? "60-70%" : "30-40%";
            case "medium":
                return Arrays.asList("BTC", "ETH").contains(symbol) ? "20-30%" : "5-15%";
            case "high":
                return Arrays.asList("BTC", "ETH").contains(symbol) ? "15-25%" : "5-10%";
            default:
                return "5-10%";
        }
    }
}
