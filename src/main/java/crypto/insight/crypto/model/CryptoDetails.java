package crypto.insight.crypto.model;

import lombok.Data;
import java.util.HashMap;
import java.util.Map;

/**
 * Represents detailed information about a cryptocurrency.
 */
@Data
public class CryptoDetails {
    /**
     * Unique identifier for the cryptocurrency
     */
    private final String id;
    
    /**
     * Name of the cryptocurrency
     */
    private final String name;
    
    /**
     * Ticker symbol of the cryptocurrency
     */
    private final String symbol;
    
    /**
     * Description of the cryptocurrency
     */
    private final String description;
    
    /**
     * Market data including price, volume, etc.
     */
    private final Map<String, Object> marketData;
    
    /**
     * Related links and resources
     */
    private final Map<String, Object> links;
    
    /**
     * Market cap rank of the cryptocurrency
     */
    private final int marketCapRank;

    /**
     * Constructs a new CryptoDetails instance from a map of details.
     * 
     * @param details Map containing cryptocurrency details
     */
    @SuppressWarnings("unchecked")
    public CryptoDetails(Map<String, Object> details) {
        this.id = (String) details.getOrDefault("id", "");
        this.name = (String) details.getOrDefault("name", "");
        this.symbol = (String) details.getOrDefault("symbol", "");
        this.description = (String) details.getOrDefault("description", "");
        
        // Handle potential null values safely
        Object marketDataObj = details.get("market_data");
        this.marketData = (marketDataObj instanceof Map) ? 
                (Map<String, Object>) marketDataObj : new HashMap<>();
        
        Object linksObj = details.get("links");
        this.links = (linksObj instanceof Map) ? 
                (Map<String, Object>) linksObj : new HashMap<>();
        
        // Handle potential ClassCastException for market_cap_rank
        Object rankObj = details.get("market_cap_rank");
        if (rankObj instanceof Integer) {
            this.marketCapRank = (Integer) rankObj;
        } else if (rankObj instanceof Number) {
            this.marketCapRank = ((Number) rankObj).intValue();
        } else {
            this.marketCapRank = 0;
        }
    }

    /**
     * Constructs a new CryptoDetails instance from a Cryptocurrency object.
     *
     * @param crypto Cryptocurrency object
     */
    public CryptoDetails(Cryptocurrency crypto) {
        this.id = crypto.getId();
        this.name = crypto.getName();
        this.symbol = crypto.getSymbol();
        this.description = ""; // Set this if you have a description in Cryptocurrency
        this.marketData = new HashMap<>(); // Populate if you have market data
        this.links = new HashMap<>(); // Populate if you have links
        this.marketCapRank = 0; // Set this if you have rank info in Cryptocurrency
    }
}

