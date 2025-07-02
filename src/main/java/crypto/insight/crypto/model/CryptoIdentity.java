package crypto.insight.crypto.model;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

/**
 * Represents the identity of a cryptocurrency across multiple data providers.
 * This class maintains mappings to different provider-specific identifiers.
 */
@Data
@NoArgsConstructor
public class CryptoIdentity implements Serializable {
    private static final long serialVersionUID = 1L;

    // The original user input query
    private String query;
    
    // Standard identifiers
    private String name;
    private String symbol;
    
    // Provider-specific identifiers
    private String coingeckoId;
    private String coinmarketcapId;
    private String cryptocompareId;
    private String coinpaprikaId;
    
    // Additional potential symbols for fuzzy matching
    private Set<String> potentialSymbols = new HashSet<>();

    public CryptoIdentity(String query) {
        this.query = query;
    }

    /**
     * Merges data from another CryptoIdentity into this one.
     * Non-null values from the other identity will overwrite null values in this one.
     */
    public void merge(CryptoIdentity other) {
        if (other == null) return;
        
        if (other.getName() != null) this.name = other.getName();
        if (other.getSymbol() != null) this.symbol = other.getSymbol();
        if (other.getCoingeckoId() != null) this.coingeckoId = other.getCoingeckoId();
        if (other.getCoinmarketcapId() != null) this.coinmarketcapId = other.getCoinmarketcapId();
        if (other.getCryptocompareId() != null) this.cryptocompareId = other.getCryptocompareId();
        if (other.getCoinpaprikaId() != null) this.coinpaprikaId = other.getCoinpaprikaId();
        
        if (other.getPotentialSymbols() != null) {
            this.potentialSymbols.addAll(other.getPotentialSymbols());
        }
    }

    /**
     * Checks if this identity has been resolved to at least one provider.
     */
    public boolean isResolved() {
        return coingeckoId != null || coinmarketcapId != null || cryptocompareId != null || coinpaprikaId != null;
    }
    
    // Backward compatibility getters
    public String getId() {
        return coingeckoId; // Default to CoinGecko ID for backward compatibility
    }
    
    // Backward compatibility setters
    public void setId(String id) {
        this.coingeckoId = id;
    }
}
