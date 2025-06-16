package crypto.insight.crypto.model;

import crypto.insight.crypto.exception.CryptoApiException;
import lombok.Getter;
import java.time.LocalDateTime;

/**
 * A generic wrapper for API operation results that can represent either success or failure.
 *
 * @param <T> The type of the data payload
 */
@Getter
public class ApiResult<T> {
    /**
     * The data payload if the operation was successful
     */
    private final T data;
    
    /**
     * Error message if the operation failed
     */
    private final String error;
    
    /**
     * The provider that generated this result
     */
    private final String provider;
    
    /**
     * Indicates whether the operation was successful
     */
    private final boolean success;
    
    /**
     * Timestamp when the result was created
     */
    private final LocalDateTime timestamp;

    private ApiResult(T data, String error, String provider, boolean success) {
        this.data = data;
        this.error = error;
        this.provider = provider;
        this.success = success;
        this.timestamp = LocalDateTime.now();
    }

    /**
     * Creates a successful result with the given data and provider.
     *
     * @param <T> The type of the data
     * @param data The data to include in the result
     * @param provider The provider that generated the result
     * @return A successful ApiResult instance
     */
    public static <T> ApiResult<T> success(T data, String provider) {
        return new ApiResult<>(data, null, provider, true);
    }

    /**
     * Creates a failed result with the given error message and provider.
     *
     * @param <T> The type of the data
     * @param error The error message
     * @param provider The provider that generated the error
     * @return A failed ApiResult instance
     */
    public static <T> ApiResult<T> error(String error, String provider) {
        return new ApiResult<>(null, error, provider, false);
    }

    /**
     * Returns the data if the operation was successful, otherwise throws an exception.
     *
     * @return The data payload
     * @throws CryptoApiException if the operation was not successful
     */
    public T getDataOrThrow() {
        if (success && data != null) {
            return data;
        }
        throw new CryptoApiException(
            error != null ? error : "No data available",
            provider,
            null,
            "unknown"
        );
    }
}
