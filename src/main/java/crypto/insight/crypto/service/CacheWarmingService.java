package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Slf4j
@Service
public class CacheWarmingService {
    
    private final UltraFastApiService ultraFastApiService;
    private final EnhancedAIQAService enhancedAIQAService;
    private final EnhancedSimilarCoinService enhancedSimilarCoinService;
    private final PerfectAIQAService perfectAIQAService;
    private final PerfectSimilarCoinService perfectSimilarCoinService;
    private final ExecutorService warmupExecutor;
    
    public CacheWarmingService(
            UltraFastApiService ultraFastApiService,
            EnhancedAIQAService enhancedAIQAService,
            EnhancedSimilarCoinService enhancedSimilarCoinService,
            PerfectAIQAService perfectAIQAService,
            PerfectSimilarCoinService perfectSimilarCoinService) {
        this.ultraFastApiService = ultraFastApiService;
        this.enhancedAIQAService = enhancedAIQAService;
        this.enhancedSimilarCoinService = enhancedSimilarCoinService;
        this.perfectAIQAService = perfectAIQAService;
        this.perfectSimilarCoinService = perfectSimilarCoinService;
        this.warmupExecutor = Executors.newCachedThreadPool();
    }
    
    /**
     * Warm cache immediately when application starts with AI enhancements
     */
    @EventListener(ApplicationReadyEvent.class)
    @Async
    public void warmCacheOnStartup() {
        log.info("🔥 Starting AGGRESSIVE cache warming with AI enhancements for instant responses...");
        
        try {
            // Warm multiple data sets in parallel
            CompletableFuture<Void> marketDataWarmup = CompletableFuture.runAsync(() -> {
                try {
                    // Warm first 3 pages of market data
                    for (int page = 1; page <= 3; page++) {
                        ultraFastApiService.getMarketDataUltraFast(page, 50).block();
                        log.debug("Warmed market data page {}", page);
                    }
                } catch (Exception e) {
                    log.warn("Market data warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            CompletableFuture<Void> topCryptosWarmup = CompletableFuture.runAsync(() -> {
                try {
                    // Warm top 20 cryptocurrencies
                    List<String> topCryptos = List.of(
                        "bitcoin", "ethereum", "binancecoin", "cardano", "solana",
                        "ripple", "polkadot", "dogecoin", "avalanche-2", "polygon",
                        "shiba-inu", "chainlink", "tron", "uniswap", "cosmos",
                        "ethereum-classic", "filecoin", "hedera-hashgraph", "vechain", "internet-computer"
                    );
                    
                    ultraFastApiService.batchLoadUltraFast(topCryptos).block();
                    log.debug("Warmed top 20 cryptocurrencies");
                } catch (Exception e) {
                    log.warn("Top cryptos warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            CompletableFuture<Void> searchWarmup = CompletableFuture.runAsync(() -> {
                try {
                    // Warm common search terms
                    List<String> commonSearches = List.of(
                        "bitcoin", "ethereum", "btc", "eth", "doge", "ada", "sol", "bnb", "xrp", "dot"
                    );
                    
                    for (String search : commonSearches) {
                        ultraFastApiService.searchCryptocurrenciesUltraFast(search, 10).block();
                    }
                    log.debug("Warmed common search terms");
                } catch (Exception e) {
                    log.warn("Search warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            // NEW: AI Q&A Cache Warming
            CompletableFuture<Void> aiQAWarmup = CompletableFuture.runAsync(() -> {
                try {
                    log.info("🤖 Starting AI Q&A cache warming...");
                    
                    // Common questions for popular cryptocurrencies
                    List<String> popularSymbols = List.of("BTC", "ETH", "ADA", "SOL", "DOT");
                    List<String> commonQuestions = List.of(
                        "Should I invest in this cryptocurrency?",
                        "What is the price prediction for this coin?",
                        "Is this a good long-term investment?",
                        "What are the risks of investing in this?",
                        "How does this compare to Bitcoin?",
                        "What is the technology behind this cryptocurrency?"
                    );
                    
                    for (String symbol : popularSymbols) {
                        for (String question : commonQuestions) {
                            try {
                                // This will populate the cache
                                enhancedAIQAService.answerCryptoQuestionEnhanced(symbol, question, null, null)
                                        .get(); // Block to ensure completion
                                Thread.sleep(500); // Small delay to avoid overwhelming the AI service
                            } catch (Exception e) {
                                log.debug("AI Q&A warmup failed for {} - {}: {}", symbol, question, e.getMessage());
                            }
                        }
                    }
                    
                    // General cryptocurrency questions
                    List<String> generalQuestions = List.of(
                        "What is cryptocurrency?",
                        "How does blockchain technology work?",
                        "What is DeFi?",
                        "How to invest in cryptocurrency safely?",
                        "What are the risks of cryptocurrency investment?",
                        "What is the difference between Bitcoin and Ethereum?"
                    );
                    
                    for (String question : generalQuestions) {
                        try {
                            enhancedAIQAService.answerGeneralQuestionEnhanced(question).get();
                            Thread.sleep(500);
                        } catch (Exception e) {
                            log.debug("General AI Q&A warmup failed for {}: {}", question, e.getMessage());
                        }
                    }
                    
                    log.info("✅ AI Q&A cache warming completed");
                } catch (Exception e) {
                    log.warn("AI Q&A warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            // NEW: Similar Coins Cache Warming
            CompletableFuture<Void> similarCoinsWarmup = CompletableFuture.runAsync(() -> {
                try {
                    log.info("🔍 Starting similar coins cache warming...");
                    
                    List<String> targetSymbols = List.of("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE");
                    
                    for (String symbol : targetSymbols) {
                        try {
                            // Warm similar coins with analysis
                            enhancedSimilarCoinService.findSimilarCryptocurrenciesEnhanced(
                                symbol, 5, true, false).get();
                            Thread.sleep(300);
                        } catch (Exception e) {
                            log.debug("Similar coins warmup failed for {}: {}", symbol, e.getMessage());
                        }
                    }
                    
                    log.info("✅ Similar coins cache warming completed");
                } catch (Exception e) {
                    log.warn("Similar coins warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            // NEW: Perfect AI Q&A Cache Warming
            CompletableFuture<Void> perfectAIWarmup = CompletableFuture.runAsync(() -> {
                try {
                    log.info("🧠 Starting PERFECT AI Q&A cache warming...");
                    
                    // Warm specific crypto questions
                    List<String> cryptoSymbols = List.of("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE");
                    List<String> cryptoQuestions = List.of(
                        "What is the current market outlook?",
                        "Is this a good investment?",
                        "What are the key risks?",
                        "How does this compare to other cryptocurrencies?",
                        "What's the technology behind this project?"
                    );
                    
                    for (String symbol : cryptoSymbols) {
                        for (String question : cryptoQuestions) {
                            try {
                                perfectAIQAService.answerCryptoQuestionPerfect(symbol, question, null, "en").get();
                                Thread.sleep(200);
                            } catch (Exception e) {
                                log.debug("Perfect AI Q&A warmup failed for {} - {}: {}", symbol, question, e.getMessage());
                            }
                        }
                    }
                    
                    // Warm general questions
                    List<String> generalQuestions = List.of(
                        "What is cryptocurrency?",
                        "How does blockchain technology work?",
                        "What is DeFi?",
                        "How to invest in cryptocurrency safely?",
                        "What are the risks of cryptocurrency investment?",
                        "What is the difference between Bitcoin and Ethereum?",
                        "What's the current market sentiment?",
                        "Which cryptocurrencies are trending?"
                    );
                    
                    for (String question : generalQuestions) {
                        try {
                            perfectAIQAService.answerGeneralQuestionPerfect(question, null, "en").get();
                            Thread.sleep(300);
                        } catch (Exception e) {
                            log.debug("Perfect general AI Q&A warmup failed for {}: {}", question, e.getMessage());
                        }
                    }
                    
                    log.info("✅ Perfect AI Q&A cache warming completed");
                } catch (Exception e) {
                    log.warn("Perfect AI Q&A warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            // NEW: Perfect Similar Coins Cache Warming
            CompletableFuture<Void> perfectSimilarWarmup = CompletableFuture.runAsync(() -> {
                try {
                    log.info("🔍 Starting PERFECT similar coins cache warming...");
                    
                    List<String> targetSymbols = List.of("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE");
                    
                    for (String symbol : targetSymbols) {
                        try {
                            // Warm perfect similar coins with comprehensive analysis
                            perfectSimilarCoinService.findSimilarCryptocurrenciesPerfect(
                                symbol, 8, true, true, "deep").get();
                            Thread.sleep(400);
                        } catch (Exception e) {
                            log.debug("Perfect similar coins warmup failed for {}: {}", symbol, e.getMessage());
                        }
                    }
                    
                    log.info("✅ Perfect similar coins cache warming completed");
                } catch (Exception e) {
                    log.warn("Perfect similar coins warmup failed: {}", e.getMessage());
                }
            }, warmupExecutor);
            
            // Wait for all warmup tasks including perfect AI services
            CompletableFuture.allOf(marketDataWarmup, topCryptosWarmup, searchWarmup, 
                                   aiQAWarmup, similarCoinsWarmup, perfectAIWarmup, perfectSimilarWarmup)
                    .get(); // Block until complete
            
            log.info("🚀 ULTIMATE PERFECT AI cache warming completed! Application ready for LIGHTNING-FAST AI responses!");
            
        } catch (Exception e) {
            log.error("Cache warming failed: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Continuously refresh cache every 30 seconds to maintain hot data
     */
    @Scheduled(fixedRate = 30000) // 30 seconds
    @Async
    public void continuousWarmup() {
        try {
            // Refresh only the most critical data
            ultraFastApiService.getMarketDataUltraFast(1, 20).subscribe();
            
            // Refresh top 5 cryptos
            List<String> top5 = List.of("bitcoin", "ethereum", "binancecoin", "cardano", "solana");
            ultraFastApiService.batchLoadUltraFast(top5).subscribe();
            
        } catch (Exception e) {
            log.debug("Continuous warmup cycle failed: {}", e.getMessage());
        }
    }
    
    /**
     * Deep warmup every 5 minutes for comprehensive cache refresh
     */
    @Scheduled(fixedRate = 300000) // 5 minutes
    @Async
    public void deepWarmup() {
        log.debug("🔥 Performing deep cache refresh with PERFECT AI enhancements...");
        
        try {
            // Refresh larger dataset
            ultraFastApiService.getMarketDataUltraFast(1, 100).block();
            
            // Refresh extended crypto list
            List<String> extendedList = List.of(
                "bitcoin", "ethereum", "binancecoin", "cardano", "solana",
                "ripple", "polkadot", "dogecoin", "avalanche-2", "polygon",
                "chainlink", "uniswap", "cosmos", "filecoin", "vechain"
            );
            ultraFastApiService.batchLoadUltraFast(extendedList).block();
            
            // Refresh ALL AI caches periodically
            refreshAllAICaches();
            
            log.debug("✅ Deep cache refresh with PERFECT AI completed");
            
        } catch (Exception e) {
            log.warn("Deep warmup failed: {}", e.getMessage());
        }
    }
    
    /**
     * Refresh ALL AI caches with popular queries including perfect AI
     */
    private void refreshAllAICaches() {
        try {
            log.debug("🤖 Refreshing ALL AI caches including PERFECT AI...");
            
            // Refresh a few popular AI queries to keep caches warm
            List<String> quickRefreshSymbols = List.of("BTC", "ETH", "ADA", "SOL", "DOT");
            List<String> quickRefreshQuestions = List.of(
                "What is the current market outlook?",
                "Is this a good investment right now?",
                "What are the key risks?",
                "How does this compare to other cryptocurrencies?"
            );
            
            for (String symbol : quickRefreshSymbols) {
                for (String question : quickRefreshQuestions) {
                    try {
                        // Refresh enhanced AI
                        enhancedAIQAService.answerCryptoQuestionEnhanced(symbol, question, null, null);
                        enhancedSimilarCoinService.findSimilarCryptocurrenciesEnhanced(symbol, 3, false, false);
                        
                        // Refresh perfect AI
                        perfectAIQAService.answerCryptoQuestionPerfect(symbol, question, null, "en");
                        perfectSimilarCoinService.findSimilarCryptocurrenciesPerfect(symbol, 5, false, false, "standard");
                        
                        Thread.sleep(100);
                    } catch (Exception e) {
                        // Ignore errors during cache refresh
                    }
                }
            }
            
            // Refresh general questions
            List<String> generalQuestions = List.of(
                "What is cryptocurrency?",
                "How does blockchain work?",
                "What is DeFi?",
                "What's the market outlook?"
            );
            
            for (String question : generalQuestions) {
                try {
                    enhancedAIQAService.answerGeneralQuestionEnhanced(question);
                    perfectAIQAService.answerGeneralQuestionPerfect(question, null, "en");
                    Thread.sleep(200);
                } catch (Exception e) {
                    // Ignore errors during cache refresh
                }
            }
            
            log.debug("✅ ALL AI caches refreshed including PERFECT AI");
        } catch (Exception e) {
            log.debug("AI cache refresh failed: {}", e.getMessage());
        }
    }
}
