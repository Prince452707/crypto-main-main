package crypto.insight.crypto.model;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Represents the analysis response containing cryptocurrency analysis and chart data.
 */
@Data
@Builder
public class AnalysisResponse {
    /**
     * Map containing analysis results with keys as analysis types and values as analysis content
     */
    private Map<String, String> analysis;
    
    /**
     * List of chart data points for price visualization
     */
    private List<ChartDataPoint> chartData;
    
    /**
     * Detailed information about the cryptocurrency
     */
    private CryptoDetails details;
    
    /**
     * Team information related to the cryptocurrency
     */
    private Map<String, Object> teamData;
    
    /**
     * News data related to the cryptocurrency
     */
    private List<Map<String, String>> newsData;
    
    /**
     * Timestamp of the analysis
     */
    private LocalDateTime timestamp;
    
    /**
     * Timestamp when the analysis was generated
     */
    private LocalDateTime analysisTimestamp;
    
    /**
     * Timestamp when the underlying data was last updated
     */
    private LocalDateTime dataTimestamp;
}