package crypto.insight.crypto.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Represents a cryptocurrency with its key market data and metadata.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cryptocurrency {
    /**
     * Unique identifier for the cryptocurrency (e.g., "bitcoin")
     */
    private String id;
    
    /**
     * Full name of the cryptocurrency (e.g., "Bitcoin")
     */
    private String name;
    
    /**
     * Ticker symbol (e.g., "BTC")
     */
    private String symbol;
    
    /**
     * Current price in USD
     */
    private BigDecimal price;
    
    /**
     * Market capitalization in USD
     */
    private BigDecimal marketCap;
    
    /**
     * 24-hour trading volume in USD
     */
    private BigDecimal volume24h;
    
    /**
     * Price change percentage in the last 24 hours
     */
    private BigDecimal percentChange24h;
    
    /**
     * URL to the cryptocurrency's logo/image
     */
    private String image;
    
    /**
     * Market cap rank (1 = highest market cap)
     */
    private int rank;
    
    /**
     * Number of coins currently in circulation
     */
    private BigDecimal circulatingSupply;
    
    /**
     * Total supply of the cryptocurrency
     */
    private BigDecimal totalSupply;
    
    /**
     * Maximum possible supply (null if no max supply)
     */
    private BigDecimal maxSupply;
    
    /**
     * Price change percentage in the last 1 hour
     */
    private BigDecimal percentChange1h;
    
    /**
     * Price change percentage in the last 7 days
     */
    private BigDecimal percentChange7d;
    
    /**
     * 24-hour high price
     */
    private BigDecimal high24h;
    
    /**
     * 24-hour low price
     */
    private BigDecimal low24h;
    
    /**
     * All-time high price
     */
    private BigDecimal ath;
    
    /**
     * Percentage change from all-time high
     */
    private BigDecimal athChangePercentage;
    
    /**
     * Date of all-time high
     */
    private LocalDateTime athDate;
    
    /**
     * Last updated timestamp
     */
    private LocalDateTime lastUpdated;
    
    /**
     * Whether this cryptocurrency is active/trading
     */
    private boolean active;
    
    /**
     * The platform this token is based on (for tokens)
     */
    private String platform;
    
    /**
     * The contract address (for tokens)
     */
    private String contractAddress;
}
