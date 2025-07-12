# Real-Time Data Integration - Flutter Frontend

## Overview

This document describes the implementation of real-time cryptocurrency data features in the Flutter frontend, integrating with the enhanced Spring Boot backend.

## Architecture

### Services

#### 1. Enhanced ApiService (`core/services/api_service.dart`)
- Added new endpoints for real-time data:
  - `getFreshCryptocurrency()` - Bypasses cache, gets latest data
  - `getFreshChartData()` - Bypasses cache for chart data
  - `clearCache()` - Clears all backend caches
  - `manualRefresh()` - Triggers manual refresh for specific symbol
  - `getSystemStatus()` - Gets system status and data freshness
  - `getDataStatus()` - Gets data status for specific symbol

#### 2. RealTimeService (`core/services/realtime_service.dart`)
- Manages real-time data updates and freshness tracking
- Features:
  - Automatic background refresh every 2 minutes
  - System status monitoring every 30 seconds
  - Data freshness tracking (5-minute threshold)
  - Refresh state management per symbol
  - Health status monitoring

### Providers

#### Enhanced CryptoProvider (`features/dashboard/providers/crypto_provider.dart`)
- Integrated with RealTimeService
- New methods:
  - `loadMarketData(fresh: true)` - Load with fresh data
  - `getCryptocurrencyDetails(fresh: true)` - Get fresh details
  - `refresh(force: true)` - Force refresh with real-time data
  - `clearCacheAndRefresh()` - Clear cache and refresh
  - `toggleRealTimeMode()` - Enable/disable real-time updates
  - Data freshness helpers: `getDataAge()`, `isSymbolRefreshing()`, `isSymbolDataFresh()`

### Models

#### Enhanced ChartDataPoint (`core/models/chart_data.dart`)
- Added real-time metadata:
  - `lastUpdated` - When data was last updated
  - `source` - Data source (e.g., "CoinMarketCap", "CoinGecko")
  - `isRealData` - Whether data is real or demo
  - `precisePriceUsd` - High-precision price
  - `marketCap` - Market capitalization
  - `volume` - Trading volume
- Helper methods:
  - `dataAge` - Human-readable age of data
  - `isFresh` - Boolean for freshness (< 5 minutes)

### UI Components

#### Enhanced Dashboard (`features/dashboard/screens/dashboard_screen.dart`)
- Real-time status indicator showing system health
- Last update timestamp
- Enhanced refresh button with loading state
- Real-time toggle switch
- System status display

#### DataFreshnessIndicator (`shared/widgets/data_freshness_indicator.dart`)
- Visual indicator for data freshness
- Shows:
  - Fresh/stale status with color coding
  - Data age (e.g., "2m ago", "Just now")
  - Demo data warning
  - Refresh button
  - Loading states

## Usage Examples

### 1. Loading Fresh Data
```dart
// Get fresh cryptocurrency data
final crypto = await cryptoProvider.getCryptocurrencyDetails('BTC', fresh: true);

// Load fresh market data
await cryptoProvider.loadMarketData(fresh: true);
```

### 2. Checking Data Freshness
```dart
// Check if data is fresh
bool isFresh = cryptoProvider.isSymbolDataFresh('BTC');

// Get data age
String age = cryptoProvider.getDataAge('BTC'); // "2m ago"

// Check if refreshing
bool refreshing = cryptoProvider.isSymbolRefreshing('BTC');
```

### 3. Real-Time Controls
```dart
// Toggle real-time mode
cryptoProvider.toggleRealTimeMode();

// Force refresh
await cryptoProvider.refresh(force: true);

// Clear cache and refresh
await cryptoProvider.clearCacheAndRefresh();
```

### 4. System Status
```dart
// Get system status
final status = cryptoProvider.realTimeService.systemStatus;
bool isHealthy = cryptoProvider.realTimeService.isHealthy;
```

## Real-Time Features

### Automatic Background Refresh
- Refreshes popular cryptocurrencies (BTC, ETH, ADA, DOT, LINK) every 2 minutes
- Only refreshes if data is older than 5 minutes
- Runs silently in background

### Data Freshness Tracking
- Tracks last update time for each symbol
- Visual indicators show data age
- Automatic detection of stale data
- Demo data detection and warnings

### System Health Monitoring
- Monitors backend health every 30 seconds
- Shows connection status
- Displays API rate limit status
- Fallback to demo data when needed

### Cache Management
- Manual cache clearing
- Automatic cache invalidation
- Fresh data bypass options
- Background cache warming

## UI Indicators

### Status Colors
- 🟢 Green: Fresh data (< 5 minutes)
- 🟡 Orange: Stale data (> 5 minutes) or demo data
- 🔴 Red: System offline or error
- 🔵 Blue: Refreshing/loading

### Real-Time Toggle
- Satellite icon: Real-time enabled
- Satellite dish icon: Real-time disabled
- Tooltip shows current mode

### Refresh Controls
- Manual refresh button in dashboard
- Pull-to-refresh on data lists
- Force refresh option available
- Loading states with spinners

## Configuration

### Timing Constants
```dart
static const Duration _refreshInterval = Duration(minutes: 2);
static const Duration _statusCheckInterval = Duration(seconds: 30);
static const Duration _dataFreshnessThreshold = Duration(minutes: 5);
```

### Backend Integration
The frontend integrates with these new backend endpoints:
- `GET /api/v1/crypto/{symbol}/fresh` - Fresh data
- `GET /api/v1/crypto/{symbol}/chart/fresh` - Fresh chart data
- `POST /api/v1/cache/clear` - Clear cache
- `POST /api/v1/crypto/{symbol}/refresh` - Manual refresh
- `GET /api/v1/status` - System status
- `GET /api/v1/crypto/{symbol}/status` - Symbol status

## Error Handling

### Network Errors
- Graceful fallback to cached data
- Error messages for users
- Retry mechanisms
- Offline mode support

### API Rate Limits
- Backend handles rate limiting
- Demo data fallback
- Visual indicators for limited data
- Automatic retry after cooldown

### Data Validation
- Type checking for all API responses
- Null safety throughout
- Default values for missing data
- Validation of data freshness

## Performance Optimizations

### Selective Refresh
- Only refresh symbols that need it
- Background refresh for popular coins only
- User-initiated refresh for specific symbols

### Memory Management
- Proper disposal of timers and services
- Cleanup of listeners
- Efficient state management

### Network Efficiency
- Batch requests when possible
- Minimal polling frequency
- Smart cache usage
- Request deduplication

## Future Enhancements

### WebSocket Integration
- Real-time price streaming
- Live order book updates
- Instant notifications

### Advanced Caching
- Persistent cache storage
- Intelligent prefetching
- Cache warming strategies

### Enhanced Indicators
- Real-time price change indicators
- Live charts with streaming data
- Push notifications for alerts

This implementation provides a solid foundation for real-time cryptocurrency data with excellent user experience and robust error handling.
