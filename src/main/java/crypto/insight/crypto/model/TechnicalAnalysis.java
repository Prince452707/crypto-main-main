package crypto.insight.crypto.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Technical analysis data for cryptocurrency.
 * Contains various technical indicators and trading signals.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TechnicalAnalysis {
    
    /**
     * RSI (Relative Strength Index) - Momentum oscillator
     */
    @JsonProperty("rsi")
    private BigDecimal rsi;
    
    /**
     * MACD (Moving Average Convergence Divergence)
     */
    @JsonProperty("macd")
    private BigDecimal macd;
    
    /**
     * Simple Moving Average (20 periods)
     */
    @JsonProperty("sma_20")
    private BigDecimal sma20;
    
    /**
     * Simple Moving Average (50 periods)
     */
    @JsonProperty("sma_50")
    private BigDecimal sma50;
    
    /**
     * Exponential Moving Average (20 periods)
     */
    @JsonProperty("ema_20")
    private BigDecimal ema20;
    
    /**
     * Bollinger Bands upper limit
     */
    @JsonProperty("bollinger_upper")
    private BigDecimal bollingerUpper;
    
    /**
     * Bollinger Bands lower limit
     */
    @JsonProperty("bollinger_lower")
    private BigDecimal bollingerLower;
    
    /**
     * Stochastic oscillator
     */
    @JsonProperty("stochastic")
    private BigDecimal stochastic;
    
    /**
     * Williams %R indicator
     */
    @JsonProperty("williams_r")
    private BigDecimal williamsR;
    
    /**
     * Average True Range (volatility indicator)
     */
    @JsonProperty("atr")
    private BigDecimal atr;
    
    /**
     * Overall technical signal (BUY, SELL, HOLD)
     */
    @JsonProperty("signal")
    private String signal;
    
    /**
     * Signal strength (0-100)
     */
    @JsonProperty("signal_strength")
    private BigDecimal signalStrength;
    
    /**
     * Support level
     */
    @JsonProperty("support_level")
    private BigDecimal supportLevel;
    
    /**
     * Resistance level
     */
    @JsonProperty("resistance_level")
    private BigDecimal resistanceLevel;
}
