package crypto.insight.crypto.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import crypto.insight.crypto.model.Cryptocurrency;
import crypto.insight.crypto.service.ApiService;
import crypto.insight.crypto.service.RealTimeDataService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
public class CryptoWebSocketHandler extends TextWebSocketHandler {

    @Autowired
    private ApiService apiService;

    @Autowired
    private RealTimeDataService realTimeDataService;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Map<String, String> sessionSubscriptions = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        sessions.put(session.getId(), session);
        log.info("WebSocket connection established: {}", session.getId());
        
        // Send welcome message
        sendMessage(session, Map.of(
            "type", "connected",
            "message", "Connected to real-time crypto data stream"
        ));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        try {
            String payload = message.getPayload();
            log.info("Received message from {}: {}", session.getId(), payload);
            
            Map<String, Object> request = objectMapper.readValue(payload, Map.class);
            String action = (String) request.get("action");
            
            switch (action) {
                case "subscribe":
                    handleSubscribe(session, request);
                    break;
                case "unsubscribe":
                    handleUnsubscribe(session, request);
                    break;
                case "ping":
                    handlePing(session);
                    break;
                default:
                    sendError(session, "Unknown action: " + action);
            }
        } catch (Exception e) {
            log.error("Error handling message from {}: {}", session.getId(), e.getMessage());
            sendError(session, "Error processing message: " + e.getMessage());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        sessions.remove(session.getId());
        sessionSubscriptions.remove(session.getId());
        log.info("WebSocket connection closed: {} - {}", session.getId(), status);
    }

    private void handleSubscribe(WebSocketSession session, Map<String, Object> request) {
        String symbol = (String) request.get("symbol");
        if (symbol == null || symbol.trim().isEmpty()) {
            sendError(session, "Symbol is required for subscription");
            return;
        }
        
        symbol = symbol.toLowerCase().trim();
        sessionSubscriptions.put(session.getId(), symbol);
        
        log.info("Session {} subscribed to {}", session.getId(), symbol);
        
        // Send immediate data
        sendInitialData(session, symbol);
        
        // Start real-time updates
        startRealTimeUpdates(session, symbol);
        
        sendMessage(session, Map.of(
            "type", "subscribed",
            "symbol", symbol,
            "message", "Subscribed to real-time updates for " + symbol.toUpperCase()
        ));
    }

    private void handleUnsubscribe(WebSocketSession session, Map<String, Object> request) {
        sessionSubscriptions.remove(session.getId());
        log.info("Session {} unsubscribed", session.getId());
        
        sendMessage(session, Map.of(
            "type", "unsubscribed",
            "message", "Unsubscribed from real-time updates"
        ));
    }

    private void handlePing(WebSocketSession session) {
        sendMessage(session, Map.of(
            "type", "pong",
            "timestamp", System.currentTimeMillis()
        ));
    }

    private void sendInitialData(WebSocketSession session, String symbol) {
        try {
            // Get current data
            apiService.getCryptocurrencyData(symbol, 1, true)
                .subscribe(
                    crypto -> {
                        sendMessage(session, Map.of(
                            "type", "initial_data",
                            "symbol", symbol,
                            "data", crypto
                        ));
                    },
                    error -> {
                        log.error("Error fetching initial data for {}: {}", symbol, error.getMessage());
                        sendError(session, "Error fetching initial data: " + error.getMessage());
                    }
                );
        } catch (Exception e) {
            log.error("Error sending initial data: {}", e.getMessage());
            sendError(session, "Error sending initial data: " + e.getMessage());
        }
    }

    private void startRealTimeUpdates(WebSocketSession session, String symbol) {
        // Schedule periodic updates every 10 seconds
        scheduler.scheduleAtFixedRate(() -> {
            if (sessions.containsKey(session.getId()) && 
                symbol.equals(sessionSubscriptions.get(session.getId()))) {
                
                try {
                    // Force fresh data
                    realTimeDataService.getFreshCryptocurrencyData(symbol, 1)
                        .subscribe(
                            crypto -> {
                                sendMessage(session, Map.of(
                                    "type", "price_update",
                                    "symbol", symbol,
                                    "data", crypto,
                                    "timestamp", System.currentTimeMillis()
                                ));
                            },
                            error -> {
                                log.error("Error fetching real-time data for {}: {}", symbol, error.getMessage());
                                sendError(session, "Error fetching real-time data: " + error.getMessage());
                            }
                        );
                } catch (Exception e) {
                    log.error("Error in real-time update for {}: {}", symbol, e.getMessage());
                }
            }
        }, 5, 10, TimeUnit.SECONDS); // Initial delay 5s, then every 10s
    }

    private void sendMessage(WebSocketSession session, Map<String, Object> message) {
        try {
            if (session.isOpen()) {
                String json = objectMapper.writeValueAsString(message);
                session.sendMessage(new TextMessage(json));
            }
        } catch (IOException e) {
            log.error("Error sending message to {}: {}", session.getId(), e.getMessage());
        }
    }

    private void sendError(WebSocketSession session, String error) {
        sendMessage(session, Map.of(
            "type", "error",
            "message", error,
            "timestamp", System.currentTimeMillis()
        ));
    }

    public void broadcastPriceUpdate(String symbol, Cryptocurrency crypto) {
        sessions.values().forEach(session -> {
            String subscribedSymbol = sessionSubscriptions.get(session.getId());
            if (symbol.equals(subscribedSymbol)) {
                sendMessage(session, Map.of(
                    "type", "price_update",
                    "symbol", symbol,
                    "data", crypto,
                    "timestamp", System.currentTimeMillis()
                ));
            }
        });
    }
}
