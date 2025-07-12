package crypto.insight.crypto.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Represents a single data point in a cryptocurrency price chart.
 * This class is used to store timestamp and price data for chart visualization.
 * Enhanced with additional metadata and validation for real-time data updates.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChartDataPoint {
    /**
     * Unix timestamp in milliseconds
     */
    @JsonProperty("timestamp")
    private long timestamp;
    
    /**
     * Price at the given timestamp
     */
    @JsonProperty("price")
    private double price;
    
    /**
     * High-precision price using BigDecimal for financial accuracy
     */
    @JsonProperty("precisePriceUsd")
    private BigDecimal precisePriceUsd;
    
    /**
     * Market cap at this timestamp (optional)
     */
    @JsonProperty("marketCap")
    private BigDecimal marketCap;
    
    /**
     * Trading volume at this timestamp (optional)
     */
    @JsonProperty("volume")
    private BigDecimal volume;
    
    /**
     * When this data point was last updated/fetched
     */
    @JsonProperty("lastUpdated")
    private LocalDateTime lastUpdated;
    
    /**
     * Data source (e.g., "CoinGecko", "CryptoCompare", "CoinMarketCap")
     */
    @JsonProperty("source")
    private String source;
    
    /**
     * Whether this is real data or demo/fallback data
     */
    @JsonProperty("isRealData")
    @Builder.Default
    private boolean isRealData = true;
    
    /**
     * Constructor for backward compatibility with existing code
     */
    public ChartDataPoint(long timestamp, double price) {
        this.timestamp = timestamp;
        this.price = price;
        this.precisePriceUsd = BigDecimal.valueOf(price);
        this.lastUpdated = LocalDateTime.now();
        this.isRealData = true;
    }
    
    /**
     * Constructor with source tracking
     */
    public ChartDataPoint(long timestamp, double price, String source) {
        this(timestamp, price);
        this.source = source;
    }
    
    /**
     * Get formatted timestamp for display
     */
    public String getFormattedTimestamp() {
        return LocalDateTime.ofEpochSecond(timestamp / 1000, 0, java.time.ZoneOffset.UTC)
                .format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
    }
    
    /**
     * Check if this data point is considered fresh (less than 5 minutes old)
     */
    public boolean isFresh() {
        if (lastUpdated == null) return false;
        return lastUpdated.isAfter(LocalDateTime.now().minusMinutes(5));
    }
    
    /**
     * Create a demo/fallback data point
     */
    public static ChartDataPoint createDemo(long timestamp, double price, String source) {
        return ChartDataPoint.builder()
                .timestamp(timestamp)
                .price(price)
                .precisePriceUsd(BigDecimal.valueOf(price))
                .source(source + " (Demo)")
                .lastUpdated(LocalDateTime.now())
                .isRealData(false)
                .build();
    }
}
