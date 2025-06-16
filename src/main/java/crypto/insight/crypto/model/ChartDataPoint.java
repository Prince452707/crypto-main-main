package crypto.insight.crypto.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a single data point in a cryptocurrency price chart.
 * This class is used to store timestamp and price data for chart visualization.
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
}
