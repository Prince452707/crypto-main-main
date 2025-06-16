package crypto.insight.crypto.model;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Represents cryptocurrency market data from various sources.
 * This class is designed to aggregate data from multiple providers.
 */
@Data
@NoArgsConstructor
public class CryptoData {
    private CryptoIdentity identity;
    private String source;
    
    // Market Data
    private BigDecimal price;  // Alias for currentPrice for backward compatibility
    private BigDecimal currentPrice;
    private BigDecimal marketCap;
    private BigDecimal volume24h;
    private BigDecimal percentChange24h;  // Alias for priceChange24h
    private BigDecimal priceChange24h;
    private Integer marketCapRank;
    private BigDecimal circulatingSupply;
    private BigDecimal totalSupply;
    private BigDecimal maxSupply;
    private String imageUrl;
    private LocalDateTime lastUpdated;
    private Map<String, Object> additionalData = new HashMap<>();

    public CryptoData(CryptoIdentity identity) {
        this.identity = identity;
        this.lastUpdated = LocalDateTime.now();
    }

    // Getters with backward compatibility
    public BigDecimal getPrice() {
        return price != null ? price : currentPrice;
    }

    public BigDecimal getCurrentPrice() {
        return currentPrice != null ? currentPrice : price;
    }

    public BigDecimal getPercentChange24h() {
        return percentChange24h != null ? percentChange24h : priceChange24h;
    }

    public BigDecimal getPriceChange24h() {
        return priceChange24h != null ? priceChange24h : percentChange24h;
    }

    // Convenience methods
    public String getSymbol() {
        return identity != null ? identity.getSymbol() : null;
    }

    public String getName() {
        return identity != null ? identity.getName() : null;
    }

    /**
     * Merges data from another CryptoData object into this one.
     * Fields are only updated if they are null in the current object.
     */
    public void mergeWith(CryptoData other) {
        if (other == null) return;

        // Merge price fields
        if (this.price == null) this.price = other.getPrice();
        if (this.currentPrice == null) this.currentPrice = other.getCurrentPrice();
        
        // Merge other fields
        if (this.marketCap == null) this.marketCap = other.getMarketCap();
        if (this.volume24h == null) this.volume24h = other.getVolume24h();
        
        // Merge price change fields
        if (this.percentChange24h == null) this.percentChange24h = other.getPercentChange24h();
        if (this.priceChange24h == null) this.priceChange24h = other.getPriceChange24h();
        
        // Merge remaining fields
        if (this.marketCapRank == null) this.marketCapRank = other.getMarketCapRank();
        if (this.circulatingSupply == null) this.circulatingSupply = other.getCirculatingSupply();
        if (this.totalSupply == null) this.totalSupply = other.getTotalSupply();
        if (this.maxSupply == null) this.maxSupply = other.getMaxSupply();
        if (this.imageUrl == null) this.imageUrl = other.getImageUrl();
        
        // Update last updated if the other one is more recent
        if (other.getLastUpdated() != null && 
            (this.lastUpdated == null || other.getLastUpdated().isAfter(this.lastUpdated))) {
            this.lastUpdated = other.getLastUpdated();
        }

        // Merge additional data
        if (other.getAdditionalData() != null) {
            other.getAdditionalData().forEach((key, value) -> 
                this.additionalData.putIfAbsent(key, value)
            );
        }

        // Update source to reflect the latest data provider
        if (other.getSource() != null) {
            this.source = other.getSource();
        }
    }
}
