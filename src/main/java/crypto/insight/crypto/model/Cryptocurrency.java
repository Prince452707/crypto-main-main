package crypto.insight.crypto.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Comprehensive cryptocurrency model with market data, technical indicators, and metadata.
 * This model represents real-time and historical data for professional crypto analysis.
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
    @JsonProperty("market_cap")
    private BigDecimal marketCap;
    
    /**
     * Fully diluted market cap
     */
    @JsonProperty("fully_diluted_market_cap")
    private BigDecimal fullyDilutedMarketCap;
    
    /**
     * 24-hour trading volume in USD
     */
    @JsonProperty("volume_24h")
    private BigDecimal volume24h;
    
    /**
     * Price change percentage in the last 24 hours
     */
    @JsonProperty("percent_change_24h")
    private BigDecimal percentChange24h;
    
    /**
     * Price change percentage in the last 7 days
     */
    @JsonProperty("percent_change_7d")
    private BigDecimal percentChange7d;
    
    /**
     * Price change percentage in the last 30 days
     */
    @JsonProperty("percent_change_30d")
    private BigDecimal percentChange30d;
    
    /**
     * All-time high price
     */
    @JsonProperty("ath")
    private BigDecimal allTimeHigh;
    
    /**
     * All-time high date
     */
    @JsonProperty("ath_date")
    private LocalDateTime allTimeHighDate;
    
    /**
     * All-time low price
     */
    @JsonProperty("atl")
    private BigDecimal allTimeLow;
    
    /**
     * All-time low date
     */
    @JsonProperty("atl_date")
    private LocalDateTime allTimeLowDate;
    
    /**
     * Market cap rank
     */
    @JsonProperty("market_cap_rank")
    private Integer rank;
    
    /**
     * Circulating supply
     */
    @JsonProperty("circulating_supply")
    private BigDecimal circulatingSupply;
    
    /**
     * Total supply
     */
    @JsonProperty("total_supply")
    private BigDecimal totalSupply;
    
    /**
     * Maximum supply
     */
    @JsonProperty("max_supply")
    private BigDecimal maxSupply;
    
    /**
     * Last updated timestamp
     */
    @JsonProperty("last_updated")
    private LocalDateTime lastUpdated;
    
    /**
     * RSI (Relative Strength Index) - Technical indicator
     */
    private BigDecimal rsi;
    
    /**
     * Volume/Market Cap ratio
     */
    @JsonProperty("volume_market_cap_ratio")
    private BigDecimal volumeMarketCapRatio;
    
    /**
     * 24h price change in absolute value
     */
    @JsonProperty("price_change_24h")
    private BigDecimal priceChange24h;
    
    /**
     * Market dominance percentage
     */
    @JsonProperty("market_dominance")
    private BigDecimal marketDominance;
    
    /**
     * Trading pairs count
     */
    @JsonProperty("trading_pairs")
    private Integer tradingPairs;
    
    /**
     * Price volatility (standard deviation)
     */
    private BigDecimal volatility;
    
    /**
     * Sharpe ratio for risk assessment
     */
    @JsonProperty("sharpe_ratio")
    private BigDecimal sharpeRatio;
    
    /**
     * Fear & Greed index specific to this crypto
     */
    @JsonProperty("sentiment_score")
    private BigDecimal sentimentScore;
    
    /**
     * Social media mentions count (24h)
     */
    @JsonProperty("social_mentions_24h")
    private Integer socialMentions24h;
    
    /**
     * Developer activity score
     */
    @JsonProperty("developer_score")
    private BigDecimal developerScore;
    
    /**
     * Community score
     */
    @JsonProperty("community_score")
    private BigDecimal communityScore;
    
    /**
     * Liquidity score
     */
    @JsonProperty("liquidity_score")
    private BigDecimal liquidityScore;
    
    /**
     * Price data for different timeframes
     */
    @JsonProperty("price_data")
    private Map<String, BigDecimal> priceData;
    
    /**
     * Technical analysis summary
     */
    @JsonProperty("technical_analysis")
    private TechnicalAnalysis technicalAnalysis;
    
    /**
     * News sentiment score
     */
    @JsonProperty("news_sentiment")
    private BigDecimal newsSentiment;
    
    /**
     * Is this crypto actively traded
     */
    @JsonProperty("is_active")
    private Boolean isActive;
    
    /**
     * Category/sector of the cryptocurrency
     */
    private String category;
    
    /**
     * Platform (for tokens)
     */
    private String platform;
    
    /**
     * Contract address (for tokens)
     */
    @JsonProperty("contract_address")
    private String contractAddress;
    
    /**
     * Logo/image URL
     */
    @JsonProperty("image_url")
    private String imageUrl;
    
    /**
     * Website URL
     */
    @JsonProperty("website_url")
    private String websiteUrl;
    
    /**
     * Description/summary
     */
    private String description;
    
    /**
     * Price change percentage in the last 1 hour
     */
    @JsonProperty("percent_change_1h")
    private BigDecimal percentChange1h;
    
    /**
     * 24-hour high price
     */
    @JsonProperty("high_24h")
    private BigDecimal high24h;
    
    /**
     * 24-hour low price
     */
    @JsonProperty("low_24h")
    private BigDecimal low24h;
    
    /**
     * Percentage change from all-time high
     */
    @JsonProperty("ath_change_percentage")
    private BigDecimal athChangePercentage;
}
