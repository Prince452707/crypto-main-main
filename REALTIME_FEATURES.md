# Real-Time Cryptocurrency Data Features

This document describes the enhanced real-time data capabilities that have been added to ensure you always get the latest cryptocurrency information.

## 🚀 New Real-Time Features

### 1. Enhanced ChartDataPoint Model
- Added high-precision price fields using BigDecimal
- Added market cap and volume data
- Added source tracking and data freshness indicators
- Added `lastUpdated` timestamp for each data point
- Added `isRealData` flag to distinguish between real and demo data

### 2. Real-Time Data Service
- Automatic cache invalidation for stale data
- Force refresh capabilities
- Data freshness validation
- Prefetching for popular cryptocurrencies

### 3. Scheduled Data Refresh
- Automatic refresh every 2 minutes for popular cryptocurrencies
- Chart data refresh every 5 minutes for top 5 cryptos
- Cache cleanup every 5 minutes
- Daily cache statistics logging

### 4. Enhanced Cache Configuration
- 30-second TTL for price data (real-time)
- 2-minute TTL for chart data
- 15-minute TTL for analysis data
- Automatic cache statistics and monitoring

## 📡 New API Endpoints

### Fresh Data Endpoints (Force Refresh)
```
GET /api/v1/crypto/fresh/{symbol}           - Get fresh crypto data
GET /api/v1/crypto/fresh/{symbol}/{days}    - Get fresh crypto data with custom days
GET /api/v1/crypto/fresh-chart/{symbol}     - Get fresh chart data  
GET /api/v1/crypto/fresh-chart/{symbol}/{days} - Get fresh chart data with custom days
```

### Cache Management
```
POST /api/v1/crypto/clear-cache/{symbol}    - Clear cache for specific symbol
POST /api/v1/crypto/clear-all-caches        - Clear all caches (use carefully)
POST /api/v1/crypto/manual-refresh          - Trigger manual refresh of popular cryptos
```

### Status and Monitoring
```
GET /api/v1/crypto/status/{symbol}          - Check data freshness status
GET /api/v1/crypto/system-status            - Get comprehensive system status
```

### Enhanced Analysis (with refresh flag)
```
GET /api/v1/crypto/analysis/{symbol}?refresh=true  - Force fresh analysis
```

## 🔄 How to Get Latest Data

### Method 1: Use Fresh Endpoints
```bash
# Get absolutely fresh BTC data
curl "http://localhost:8081/api/v1/crypto/fresh/BTC"

# Get fresh 7-day chart for ETH
curl "http://localhost:8081/api/v1/crypto/fresh-chart/ETH/7"
```

### Method 2: Use Refresh Flag
```bash
# Force refresh in regular analysis
curl "http://localhost:8081/api/v1/crypto/analysis/BTC?refresh=true"
```

### Method 3: Clear Cache First
```bash
# Clear cache then fetch
curl -X POST "http://localhost:8081/api/v1/crypto/clear-cache/BTC"
curl "http://localhost:8081/api/v1/crypto/analysis/BTC"
```

## 📊 Data Freshness Indicators

### Response Fields Added:
- `lastUpdated`: When the data was last fetched
- `dataSource`: Which API provided the data
- `isRealData`: Whether this is real or demo/fallback data
- `isFresh()`: Method to check if data is less than 5 minutes old

### Example Enhanced Response:
```json
{
  "success": true,
  "data": {
    "cryptocurrency": {...},
    "lastUpdated": "2025-07-02T10:30:45",
    "dataSource": "Fresh from APIs",
    "requestedDays": 7
  },
  "message": "Fresh cryptocurrency data fetched successfully"
}
```

## ⚙️ Configuration

### Cache TTL Settings (application.properties):
```properties
# Real-time cache configuration
crypto.realtime.cache.ttl.prices=30     # seconds
crypto.realtime.cache.ttl.charts=120    # seconds  
crypto.realtime.cache.ttl.analysis=900  # seconds

# Refresh intervals
crypto.realtime.refresh.interval=120000  # 2 minutes
```

## 🎯 Recommended Usage

### For Real-Time Trading Applications:
1. Use `/fresh/` endpoints for critical price data
2. Set up automatic refresh every 30 seconds
3. Monitor data freshness with `/status/` endpoints

### For Dashboard Applications:
1. Use regular endpoints with `refresh=true` parameter
2. Implement client-side cache with 1-2 minute TTL
3. Use scheduled refresh for popular symbols

### For Analysis Applications:
1. Use regular analysis endpoints (cached for performance)
2. Use `refresh=true` when user explicitly requests fresh analysis
3. Clear cache periodically for active symbols

## 🔧 Testing

Run the test script to verify all endpoints:
```bash
./test_realtime_endpoints.bat
```

Or test individual endpoints:
```bash
# Check if BTC data is stale
curl "http://localhost:8081/api/v1/crypto/status/BTC"

# Get fresh data
curl "http://localhost:8081/api/v1/crypto/fresh/BTC"

# Check system status
curl "http://localhost:8081/api/v1/crypto/system-status"
```

## 📝 Notes

1. **Rate Limiting**: Fresh endpoints bypass cache but may hit API rate limits
2. **Performance**: Use cached endpoints for high-frequency requests
3. **Monitoring**: Check system status endpoint for cache performance
4. **Scheduling**: Automatic refresh runs in background for popular symbols

## 🚨 Important

- Fresh endpoints should be used sparingly to avoid API rate limits
- Regular endpoints with 30-second cache provide good balance of freshness and performance
- Monitor your API usage, especially when using force refresh features
- The system automatically prefetches data for popular cryptocurrencies (BTC, ETH, etc.)

## 🔍 Troubleshooting

If you're not getting fresh data:
1. Check the `lastUpdated` field in responses
2. Use `/status/{symbol}` to check data freshness
3. Clear caches with `/clear-cache/{symbol}`
4. Check API rate limits in application logs
5. Verify API keys are configured correctly
