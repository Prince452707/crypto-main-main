package crypto.insight.crypto.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashMap;
import java.util.Map;

/**
 * Generic API response wrapper class that provides a consistent structure for all API responses.
 * This class supports:
 * - Success/error status
 * - Custom messages
 * - Data payload of any type
 * - Metadata for additional context (e.g., pagination info)
 *
 * @param <T> The type of the data payload
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {
    /**
     * Indicates whether the request was successful
     */
    private boolean success;
    
    /**
     * A message describing the result of the operation
     */
    private String message;
    
    /**
     * The actual data payload
     */
    private T data;
    
    /**
     * Additional metadata for the response (e.g., pagination info, timestamps)
     */
    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();

    /**
     * Creates a successful API response with the given data and message.
     *
     * @param <T> The type of the data
     * @param data The data to include in the response
     * @param message A success message
     * @return An ApiResponse instance indicating success
     */
    /**
     * Creates a successful API response with the given data and message.
     *
     * @param <T> The type of the data
     * @param data The data to include in the response
     * @param message A success message
     * @return An ApiResponse instance indicating success
     */
    public static <T> ApiResponse<T> success(T data, String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }
    
    /**
     * Creates a successful API response with data, message, and metadata.
     *
     * @param <T> The type of the data
     * @param data The data to include in the response
     * @param message A success message
     * @param metadata Additional metadata map
     * @return An ApiResponse instance with metadata
     */
    public static <T> ApiResponse<T> success(T data, String message, Map<String, Object> metadata) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .metadata(metadata != null ? metadata : new HashMap<>())
                .build();
    }

    /**
     * Creates an error API response with the given error message.
     *
     * @param <T> The type of the data (usually Void for errors)
     * @param message An error message
     * @return An ApiResponse instance indicating an error
     */
    /**
     * Creates an error API response with the given error message.
     *
     * @param <T> The type of the data (usually Void for errors)
     * @param message An error message
     * @return An ApiResponse instance indicating an error
     */
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .data(null)
                .build();
    }
    
    /**
     * Creates an error API response with a message and additional error details.
     *
     * @param <T> The type of the data
     * @param message Error message
     * @param errorDetails Additional error details
     * @return An ApiResponse instance with error details
     */
    public static <T> ApiResponse<T> error(String message, Map<String, Object> errorDetails) {
        ApiResponse<T> response = ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .data(null)
                .build();
        
        if (errorDetails != null) {
            response.setMetadata(errorDetails);
        }
        
        return response;
    }
    
    /**
     * Adds a metadata key-value pair to the response.
     *
     * @param key The metadata key
     * @param value The metadata value
     * @return This ApiResponse instance for method chaining
     */
    public ApiResponse<T> withMetadata(String key, Object value) {
        if (this.metadata == null) {
            this.metadata = new HashMap<>();
        }
        this.metadata.put(key, value);
        return this;
    }
}