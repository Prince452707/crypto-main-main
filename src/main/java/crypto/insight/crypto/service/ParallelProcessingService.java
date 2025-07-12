package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.IntStream;

@Slf4j
@Service
public class ParallelProcessingService {
    
    private final ExecutorService cpuIntensiveExecutor;
    private final ForkJoinPool parallelPool;
    
    // Simulated GPU-like parallel processing
    private static final int PARALLEL_WORKERS = Runtime.getRuntime().availableProcessors() * 4;
    private static final int BATCH_SIZE = 50;
    
    public ParallelProcessingService() {
        this.cpuIntensiveExecutor = Executors.newWorkStealingPool(PARALLEL_WORKERS);
        this.parallelPool = new ForkJoinPool(PARALLEL_WORKERS);
    }
    
    /**
     * Process market data in parallel - used by UltraHighPerformanceService
     */
    public Mono<List<Cryptocurrency>> processMarketDataParallel(List<Cryptocurrency> data) {
        return Mono.fromFuture(calculateMarketStatsParallel(data)
                .thenApply(stats -> {
                    // Just return the original data after processing statistics
                    return data;
                }));
    }
    
    /**
     * GPU-style parallel calculation of market statistics
     */
    public CompletableFuture<Map<String, Double>> calculateMarketStatsParallel(List<Cryptocurrency> data) {
        return CompletableFuture.supplyAsync(() -> {
            if (data.isEmpty()) return new HashMap<>();
            
            long startTime = System.nanoTime();
            
            // Split data into chunks for parallel processing
            List<List<Cryptocurrency>> chunks = partitionList(data, BATCH_SIZE);
            
            // Process chunks in parallel using fork-join
            List<CompletableFuture<Map<String, Double>>> chunkFutures = chunks.stream()
                    .map(chunk -> CompletableFuture.supplyAsync(() -> 
                        processChunk(chunk), cpuIntensiveExecutor))
                    .toList();
            
            // Combine results
            Map<String, Double> finalStats = chunkFutures.stream()
                    .map(CompletableFuture::join)
                    .reduce(new HashMap<>(), this::mergeStats);
            
            // Final calculations
            finalizeStats(finalStats, data.size());
            
            long endTime = System.nanoTime();
            log.debug("Parallel market stats calculated in {}ms for {} items", 
                    (endTime - startTime) / 1_000_000, data.size());
            
            return finalStats;
            
        }, cpuIntensiveExecutor);
    }
    
    /**
     * Vectorized-style price analysis
     */
    public CompletableFuture<List<Double>> calculateMovingAveragesParallel(
            List<Double> prices, int windowSize) {
        
        return CompletableFuture.supplyAsync(() -> {
            if (prices.size() < windowSize) return prices;
            
            // Parallel stream processing for moving averages
            return IntStream.range(0, prices.size() - windowSize + 1)
                    .parallel()
                    .mapToObj(i -> {
                        double sum = 0;
                        for (int j = i; j < i + windowSize; j++) {
                            sum += prices.get(j);
                        }
                        return sum / windowSize;
                    })
                    .toList();
                    
        }, cpuIntensiveExecutor);
    }
    
    /**
     * Parallel correlation matrix calculation
     */
    public CompletableFuture<Map<String, Map<String, Double>>> calculateCorrelationMatrix(
            Map<String, List<Double>> priceData) {
        
        return CompletableFuture.supplyAsync(() -> {
            List<String> symbols = new ArrayList<>(priceData.keySet());
            Map<String, Map<String, Double>> correlationMatrix = new HashMap<>();
            
            // Parallel computation of correlations
            symbols.parallelStream().forEach(symbol1 -> {
                Map<String, Double> correlations = new HashMap<>();
                
                symbols.parallelStream().forEach(symbol2 -> {
                    double correlation = calculateCorrelation(
                        priceData.get(symbol1), 
                        priceData.get(symbol2)
                    );
                    correlations.put(symbol2, correlation);
                });
                
                correlationMatrix.put(symbol1, correlations);
            });
            
            return correlationMatrix;
            
        }, cpuIntensiveExecutor);
    }
    
    /**
     * SIMD-style batch processing of cryptocurrency data
     */
    public CompletableFuture<List<Cryptocurrency>> processBatchParallel(
            List<Cryptocurrency> data, 
            java.util.function.Function<Cryptocurrency, Cryptocurrency> processor) {
        
        return CompletableFuture.supplyAsync(() -> {
            // Process in parallel chunks
            return data.parallelStream()
                    .map(processor)
                    .toList();
        }, cpuIntensiveExecutor);
    }
    
    /**
     * Parallel sorting with custom comparators
     */
    public CompletableFuture<List<Cryptocurrency>> sortParallel(
            List<Cryptocurrency> data, 
            Comparator<Cryptocurrency> comparator) {
        
        return CompletableFuture.supplyAsync(() -> {
            // Use parallel sort for large datasets
            return data.parallelStream()
                    .sorted(comparator)
                    .toList();
        }, cpuIntensiveExecutor);
    }
    
    /**
     * Parallel search with multiple criteria
     */
    public CompletableFuture<List<Cryptocurrency>> searchParallel(
            List<Cryptocurrency> data,
            List<java.util.function.Predicate<Cryptocurrency>> predicates) {
        
        return CompletableFuture.supplyAsync(() -> {
            return data.parallelStream()
                    .filter(crypto -> predicates.parallelStream()
                            .anyMatch(predicate -> predicate.test(crypto)))
                    .toList();
        }, cpuIntensiveExecutor);
    }
    
    /**
     * Process chunk of data (simulates GPU kernel)
     */
    private Map<String, Double> processChunk(List<Cryptocurrency> chunk) {
        Map<String, Double> chunkStats = new HashMap<>();
        
        double totalMarketCap = 0;
        double totalVolume = 0;
        double totalPriceChange = 0;
        double btcMarketCap = 0;
        int validPriceChanges = 0;
        
        for (Cryptocurrency crypto : chunk) {
            if (crypto.getMarketCap() != null) {
                totalMarketCap += crypto.getMarketCap().doubleValue();
                if ("BTC".equals(crypto.getSymbol())) {
                    btcMarketCap += crypto.getMarketCap().doubleValue();
                }
            }
            
            if (crypto.getVolume24h() != null) {
                totalVolume += crypto.getVolume24h().doubleValue();
            }
            
            if (crypto.getPercentChange24h() != null) {
                totalPriceChange += crypto.getPercentChange24h().doubleValue();
                validPriceChanges++;
            }
        }
        
        chunkStats.put("totalMarketCap", totalMarketCap);
        chunkStats.put("totalVolume", totalVolume);
        chunkStats.put("totalPriceChange", totalPriceChange);
        chunkStats.put("btcMarketCap", btcMarketCap);
        chunkStats.put("validPriceChanges", (double) validPriceChanges);
        
        return chunkStats;
    }
    
    /**
     * Merge statistics from parallel chunks
     */
    private Map<String, Double> mergeStats(Map<String, Double> stats1, Map<String, Double> stats2) {
        Map<String, Double> merged = new HashMap<>(stats1);
        
        stats2.forEach((key, value) -> 
            merged.merge(key, value, Double::sum));
        
        return merged;
    }
    
    /**
     * Finalize statistics calculations
     */
    private void finalizeStats(Map<String, Double> stats, int totalCount) {
        double totalPriceChange = stats.getOrDefault("totalPriceChange", 0.0);
        double validPriceChanges = stats.getOrDefault("validPriceChanges", 1.0);
        
        // Calculate averages
        stats.put("avgPriceChange", totalPriceChange / validPriceChanges);
        
        // Calculate BTC dominance
        double totalMarketCap = stats.getOrDefault("totalMarketCap", 0.0);
        double btcMarketCap = stats.getOrDefault("btcMarketCap", 0.0);
        
        if (totalMarketCap > 0) {
            stats.put("btcDominance", (btcMarketCap / totalMarketCap) * 100);
        }
        
        stats.put("totalCount", (double) totalCount);
    }
    
    /**
     * Calculate correlation between two price series
     */
    private double calculateCorrelation(List<Double> prices1, List<Double> prices2) {
        if (prices1.size() != prices2.size() || prices1.isEmpty()) {
            return 0.0;
        }
        
        double mean1 = prices1.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        double mean2 = prices2.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        
        double numerator = 0;
        double sumSq1 = 0;
        double sumSq2 = 0;
        
        for (int i = 0; i < prices1.size(); i++) {
            double diff1 = prices1.get(i) - mean1;
            double diff2 = prices2.get(i) - mean2;
            
            numerator += diff1 * diff2;
            sumSq1 += diff1 * diff1;
            sumSq2 += diff2 * diff2;
        }
        
        double denominator = Math.sqrt(sumSq1 * sumSq2);
        return denominator == 0 ? 0 : numerator / denominator;
    }
    
    /**
     * Partition list into chunks for parallel processing
     */
    private <T> List<List<T>> partitionList(List<T> list, int chunkSize) {
        List<List<T>> chunks = new ArrayList<>();
        for (int i = 0; i < list.size(); i += chunkSize) {
            chunks.add(list.subList(i, Math.min(i + chunkSize, list.size())));
        }
        return chunks;
    }
    
    /**
     * Get processing statistics
     */
    public Map<String, Object> getProcessingStats() {
        return Map.of(
            "parallelWorkers", PARALLEL_WORKERS,
            "batchSize", BATCH_SIZE,
            "cpuCores", Runtime.getRuntime().availableProcessors(),
            "activeThreads", parallelPool.getActiveThreadCount(),
            "queuedTasks", parallelPool.getQueuedTaskCount()
        );
    }
}
