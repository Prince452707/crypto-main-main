package crypto.insight.crypto.service;

import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.websocket.CryptoWebSocketHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class RealTimeStreamingService {

    @Autowired
    private ApiService apiService;

    @Autowired
    private RealTimeDataService realTimeDataService;

    @Autowired
    private CryptoWebSocketHandler webSocketHandler;

    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(3);
    private final ConcurrentHashMap<String, Long> lastUpdateTimes = new ConcurrentHashMap<>();
    
    // Popular cryptocurrencies to update frequently
    private final List<String> popularCryptos = List.of(
        "bitcoin", "ethereum", "binancecoin", "ripple", "cardano",
        "solana", "polkadot", "dogecoin", "avalanche", "chainlink"
    );

    /**
     * Start real-time data streaming for popular cryptocurrencies
     */
    public void startRealTimeStreaming() {
        log.info("Starting real-time data streaming service");
        
        // Stream updates for popular cryptocurrencies every 15 seconds
        scheduler.scheduleAtFixedRate(this::updatePopularCryptos, 10, 15, TimeUnit.SECONDS);
        
        // Clean up old update times every 5 minutes
        scheduler.scheduleAtFixedRate(this::cleanupUpdateTimes, 5, 5, TimeUnit.MINUTES);
    }

    /**
     * Update popular cryptocurrencies with real-time data
     */
    private void updatePopularCryptos() {
        popularCryptos.parallelStream().forEach(symbol -> {
            try {
                updateCryptoData(symbol);
            } catch (Exception e) {
                log.warn("Error updating real-time data for {}: {}", symbol, e.getMessage());
            }
        });
    }

    /**
     * Update specific cryptocurrency data and broadcast to connected clients
     */
    public void updateCryptoData(String symbol) {
        long startTime = System.currentTimeMillis();
        
        try {
            // Check if we need to update (avoid too frequent updates)
            Long lastUpdate = lastUpdateTimes.get(symbol);
            long currentTime = System.currentTimeMillis();
            
            if (lastUpdate != null && (currentTime - lastUpdate) < 10000) { // 10 seconds minimum between updates
                return;
            }
            
            // Fetch fresh data
            realTimeDataService.getFreshCryptocurrencyData(symbol, 1)
                .subscribe(
                    crypto -> {
                        lastUpdateTimes.put(symbol, currentTime);
                        
                        // Broadcast to WebSocket clients
                        webSocketHandler.broadcastPriceUpdate(symbol, crypto);
                        
                        long duration = System.currentTimeMillis() - startTime;
                        log.debug("Updated real-time data for {} in {}ms", symbol, duration);
                    },
                    error -> {
                        log.warn("Failed to update real-time data for {}: {}", symbol, error.getMessage());
                    }
                );
                
        } catch (Exception e) {
            log.error("Error in real-time update for {}: {}", symbol, e.getMessage());
        }
    }

    /**
     * Force update for a specific symbol (triggered by user request)
     */
    public void forceUpdateSymbol(String symbol) {
        log.info("Force updating real-time data for {}", symbol);
        
        try {
            realTimeDataService.getFreshCryptocurrencyData(symbol, 1)
                .subscribe(
                    crypto -> {
                        lastUpdateTimes.put(symbol, System.currentTimeMillis());
                        webSocketHandler.broadcastPriceUpdate(symbol, crypto);
                        log.info("Force update completed for {}", symbol);
                    },
                    error -> {
                        log.error("Force update failed for {}: {}", symbol, error.getMessage());
                    }
                );
        } catch (Exception e) {
            log.error("Error in force update for {}: {}", symbol, e.getMessage());
        }
    }

    /**
     * Clean up old update times to prevent memory leaks
     */
    private void cleanupUpdateTimes() {
        long cutoffTime = System.currentTimeMillis() - (60 * 60 * 1000); // 1 hour ago
        lastUpdateTimes.entrySet().removeIf(entry -> entry.getValue() < cutoffTime);
        log.debug("Cleaned up {} old update time entries", lastUpdateTimes.size());
    }

    /**
     * Get last update time for a symbol
     */
    public Long getLastUpdateTime(String symbol) {
        return lastUpdateTimes.get(symbol);
    }

    /**
     * Check if data is considered fresh (updated within last 30 seconds)
     */
    public boolean isDataFresh(String symbol) {
        Long lastUpdate = lastUpdateTimes.get(symbol);
        if (lastUpdate == null) return false;
        
        return (System.currentTimeMillis() - lastUpdate) < 30000; // 30 seconds
    }

    /**
     * Get all symbols that are currently being tracked
     */
    public List<String> getTrackedSymbols() {
        return List.copyOf(lastUpdateTimes.keySet());
    }

    /**
     * Scheduled method to update popular cryptocurrencies
     */
    @Scheduled(fixedRate = 20000) // Every 20 seconds
    public void scheduledUpdate() {
        updatePopularCryptos();
    }
}
