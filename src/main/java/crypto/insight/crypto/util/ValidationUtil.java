package crypto.insight.crypto.util;

import org.springframework.util.StringUtils;
import java.util.regex.Pattern;

public class ValidationUtil {
    
    // More lenient pattern for development
    private static final Pattern SYMBOL_PATTERN = Pattern.compile("^[A-Za-z0-9]{1,20}$");
    private static final Pattern NAME_PATTERN = Pattern.compile("^[a-zA-Z0-9\\s-]{1,100}$");
    private static final int MAX_QUERY_LENGTH = 200;
    
    public static String sanitizeInput(String input) {
        if (input == null) {
            return "";
        }
        // Remove any HTML/script tags
        input = input.replaceAll("<[^>]*>", "");
        // Remove any special characters except alphanumeric, spaces, and hyphens
        input = input.replaceAll("[^a-zA-Z0-9\\s-]", "");
        return input.trim();
    }
    
    public static boolean isValidSymbol(String symbol) {
        return symbol != null && SYMBOL_PATTERN.matcher(symbol).matches();
    }
    
    public static boolean isValidName(String name) {
        return name != null && NAME_PATTERN.matcher(name).matches();
    }
    
    public static boolean isValidQuery(String query) {
        return StringUtils.hasText(query) && query.length() <= MAX_QUERY_LENGTH;
    }
    
    public static String validateAndSanitizeQuery(String query) {
        if (!isValidQuery(query)) {
            throw new IllegalArgumentException("Invalid query parameter");
        }
        return sanitizeInput(query);
    }
} 