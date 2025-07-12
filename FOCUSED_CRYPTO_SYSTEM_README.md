# Focused Crypto Data System

## Overview

This system provides a comprehensive solution for fetching detailed cryptocurrency data with intelligent rate limiting and provider fallbacks. It's designed to handle the rate limiting issues you've been experiencing with crypto data providers.

## Key Features

### 1. Intelligent Rate Limiting
- **Per-provider rate limiting**: Each provider (CoinGecko, CoinMarketCap, etc.) has its own rate limits
- **Circuit breaker pattern**: Automatically stops calling providers that are failing
- **Exponential backoff**: Increases delay between requests when rate limits are hit
- **Provider prioritization**: Uses most reliable providers first

### 2. Comprehensive Data Aggregation
- **Multi-provider data**: Combines data from all available providers
- **Data validation**: Ensures data quality and consistency
- **Fallback mechanisms**: If one provider fails, others continue working

### 3. Smart Caching
- **Multi-level caching**: Identity resolution, detailed data, and price data are cached separately
- **Cache invalidation**: Automatic cache expiration and manual cache clearing
- **Optimized cache keys**: Prevents cache collisions and ensures data freshness

## Backend Implementation

### New Services

1. **RateLimitingService**: Manages rate limits for each provider
2. **FocusedCryptoDetailService**: Orchestrates data fetching with rate limiting
3. **FocusedCryptoController**: Provides REST endpoints for the frontend

### New Endpoints

```
GET /api/v1/crypto/focused/{cryptoId}
- Get comprehensive crypto data
- Query params: ?forceRefresh=true

POST /api/v1/crypto/focused/{cryptoId}/refresh
- Force refresh crypto data

GET /api/v1/crypto/focused/status/rate-limits
- Get current rate limiting status

DELETE /api/v1/crypto/focused/{cryptoId}/cache
- Clear cache for specific crypto

POST /api/v1/crypto/focused/preload
- Preload popular cryptocurrencies
```

## Frontend Implementation

### New Components

1. **FocusedCryptoService**: Flutter service for API communication
2. **FocusedCryptoProvider**: State management for crypto details
3. **FocusedCryptoDetailPage**: Comprehensive crypto detail page

### Usage Example

```dart
// In your widget
Consumer<FocusedCryptoProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (provider.selectedCrypto != null) {
      return CryptoDetailView(crypto: provider.selectedCrypto!);
    }
    
    return ErrorView(error: provider.error);
  },
)

// Load crypto data
final provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
await provider.loadFocusedCryptoData('avalanche'); // or 'AVAX', 'bitcoin', etc.
```

## Configuration

### Backend Configuration

The system is configured in `FocusedCryptoConfig.java`:

```java
@Configuration
@EnableCaching
@EnableAsync
@EnableScheduling
public class FocusedCryptoConfig {
    // Cache manager with multiple cache regions
    // WebClient configuration for HTTP requests
    // Thread pool for async operations
}
```

### Rate Limits (Default)

- **CoinGecko**: 30 requests/minute (free tier)
- **CoinMarketCap**: 10 requests/minute (free tier)
- **CoinPaprika**: 25 requests/minute (free tier)
- **CryptoCompare**: 100 requests/minute (free tier)

## How It Solves Your Rate Limiting Issues

### Problem: 429 Too Many Requests
**Solution**: 
- Smart rate limiting prevents exceeding provider limits
- Circuit breaker stops calling failing providers
- Exponential backoff increases delays after failures

### Problem: Multiple Concurrent Requests
**Solution**:
- Request deduplication prevents duplicate API calls
- Provider prioritization uses most reliable sources first
- Intelligent caching reduces API calls

### Problem: Inconsistent Data
**Solution**:
- Data aggregation from multiple providers
- Fallback mechanisms ensure data availability
- Comprehensive error handling and recovery

## Usage for AVAX (Avalanche)

To get focused data for AVAX that you mentioned:

### Backend
```bash
curl "http://localhost:8081/api/v1/crypto/focused/avalanche?forceRefresh=true"
```

### Frontend
```dart
// Load AVAX data with comprehensive details
final provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
await provider.loadFocusedCryptoData('avalanche', forceRefresh: true);

// The provider will fetch from all available sources:
// - Price data
// - Market cap and volume
// - Supply information
// - Historical data (ATH/ATL)
// - Technical indicators
// - Social metrics (if available)
```

## Monitoring and Debugging

### Rate Limit Status
```dart
// Check current rate limiting status
final provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
await provider.updateRateLimitStatus();

// View in the UI
_showRateLimitDialog(); // Shows detailed status
```

### Cache Management
```dart
// Clear cache for specific crypto
await provider.clearCurrentCache();

// Clear all cache
provider.clearAllCache();

// Get cache statistics
final stats = provider.getCacheStats();
print('Cache hit rate: ${stats['cacheHitRate']}');
```

## Benefits

1. **Reduced Rate Limiting**: Smart rate limiting prevents 429 errors
2. **Better Data Quality**: Multi-provider aggregation improves data accuracy
3. **Improved Performance**: Intelligent caching reduces API calls
4. **Better User Experience**: Fallback mechanisms ensure data availability
5. **Easy Monitoring**: Built-in rate limit and cache monitoring

## Next Steps

1. **Deploy the backend changes**: The new services and controllers
2. **Update the Flutter app**: Include the new providers and pages
3. **Test with AVAX**: Verify the system works with your specific use case
4. **Monitor performance**: Use the built-in monitoring tools

The system is designed to be production-ready and should significantly reduce the rate limiting issues you've been experiencing while providing much more comprehensive cryptocurrency data.
