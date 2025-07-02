package crypto.insight.crypto.model;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Enum representing different types of cryptocurrency analysis available.
 */
public enum AnalysisType {
    GENERAL("general", "General Analysis"),
    TECHNICAL("technical", "Technical Analysis"),
    FUNDAMENTAL("fundamental", "Fundamental Analysis"),
    NEWS("news", "News Analysis"),
    SENTIMENT("sentiment", "Sentiment Analysis"),
    RISK("risk", "Risk Analysis"),
    PREDICTION("prediction", "Prediction Analysis");

    private final String code;
    private final String displayName;

    AnalysisType(String code, String displayName) {
        this.code = code;
        this.displayName = displayName;
    }

    public String getCode() {
        return code;
    }

    public String getDisplayName() {
        return displayName;
    }

    /**
     * Parse analysis types from comma-separated string
     */
    public static List<AnalysisType> parseTypes(String types) {
        if (types == null || types.trim().isEmpty()) {
            return Arrays.asList(values()); // Return all types if none specified
        }

        return Arrays.stream(types.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .map(AnalysisType::fromCode)
                .filter(type -> type != null)
                .collect(Collectors.toList());
    }

    /**
     * Get AnalysisType from code string
     */
    public static AnalysisType fromCode(String code) {
        for (AnalysisType type : values()) {
            if (type.code.equalsIgnoreCase(code)) {
                return type;
            }
        }
        return null;
    }

    /**
     * Get all available analysis types as codes
     */
    public static List<String> getAllCodes() {
        return Arrays.stream(values())
                .map(AnalysisType::getCode)
                .collect(Collectors.toList());
    }
}
