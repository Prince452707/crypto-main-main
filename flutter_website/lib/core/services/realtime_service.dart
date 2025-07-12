import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/cryptocurrency.dart';
import '../models/chart_data.dart';
import 'api_service.dart';

/// Service for managing real-time data updates and freshness
class RealTimeService extends ChangeNotifier {
  final ApiService _apiService;
  Timer? _refreshTimer;
  Timer? _statusTimer;
  
  // Data freshness tracking
  final Map<String, DateTime> _lastUpdated = {};
  final Map<String, bool> _isRefreshing = {};
  
  // System status
  Map<String, dynamic> _systemStatus = {};
  bool _isHealthy = false;
  
  static const Duration _refreshInterval = Duration(minutes: 2);
  static const Duration _statusCheckInterval = Duration(seconds: 30);
  static const Duration _dataFreshnessThreshold = Duration(minutes: 5);

  RealTimeService(this._apiService) {
    _startAutoRefresh();
    _startStatusCheck();
  }

  // Getters
  Map<String, dynamic> get systemStatus => _systemStatus;
  bool get isHealthy => _isHealthy;
  
  bool isRefreshing(String symbol) => _isRefreshing[symbol] ?? false;
  DateTime? getLastUpdated(String symbol) => _lastUpdated[symbol];
  
  bool isDataFresh(String symbol) {
    final lastUpdate = _lastUpdated[symbol];
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _dataFreshnessThreshold;
  }
  
  String getDataAge(String symbol) {
    final lastUpdate = _lastUpdated[symbol];
    if (lastUpdate == null) return 'Unknown';
    
    final difference = DateTime.now().difference(lastUpdate);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  /// Start automatic background refresh
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _backgroundRefresh();
    });
  }

  /// Start periodic system status checks
  void _startStatusCheck() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(_statusCheckInterval, (_) {
      _checkSystemStatus();
    });
    // Initial status check
    _checkSystemStatus();
  }

  /// Perform background refresh for commonly used symbols
  Future<void> _backgroundRefresh() async {
    final commonSymbols = ['BTC', 'ETH', 'ADA', 'DOT', 'LINK'];
    
    for (final symbol in commonSymbols) {
      if (!isDataFresh(symbol)) {
        try {
          await refreshSymbolData(symbol, silent: true);
        } catch (e) {
          debugPrint('Background refresh failed for $symbol: $e');
        }
      }
    }
  }

  /// Check system status and health
  Future<void> _checkSystemStatus() async {
    try {
      _systemStatus = await _apiService.getSystemStatus();
      _isHealthy = _systemStatus['status'] == 'UP' || _systemStatus['status'] == 'healthy';
      notifyListeners();
    } catch (e) {
      _isHealthy = false;
      _systemStatus = {'status': 'error', 'error': e.toString()};
      notifyListeners();
    }
  }

  /// Get fresh cryptocurrency data
  Future<Cryptocurrency> getFreshCryptocurrency(String symbol, {int days = 30}) async {
    _setRefreshing(symbol, true);
    
    try {
      final crypto = await _apiService.getFreshCryptocurrency(symbol, days: days);
      _updateLastUpdated(symbol);
      return crypto;
    } finally {
      _setRefreshing(symbol, false);
    }
  }

  /// Get fresh chart data
  Future<List<ChartDataPoint>> getFreshChartData(String symbol, {int days = 30}) async {
    _setRefreshing(symbol, true);
    
    try {
      final chartData = await _apiService.getFreshChartData(symbol, days: days);
      _updateLastUpdated(symbol);
      return chartData;
    } finally {
      _setRefreshing(symbol, false);
    }
  }

  /// Refresh data for a specific symbol
  Future<void> refreshSymbolData(String symbol, {bool silent = false}) async {
    if (!silent) _setRefreshing(symbol, true);
    
    try {
      await _apiService.manualRefresh(symbol);
      _updateLastUpdated(symbol);
      
      if (!silent) {
        notifyListeners();
      }
    } finally {
      if (!silent) _setRefreshing(symbol, false);
    }
  }

  /// Clear all caches
  Future<bool> clearAllCache() async {
    try {
      final success = await _apiService.clearCache();
      if (success) {
        _lastUpdated.clear();
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Get data status for a symbol
  Future<Map<String, dynamic>> getDataStatus(String symbol) async {
    return await _apiService.getDataStatus(symbol);
  }

  /// Force refresh for critical data
  Future<void> forceRefreshCriticalData() async {
    final criticalSymbols = ['BTC', 'ETH'];
    
    for (final symbol in criticalSymbols) {
      await refreshSymbolData(symbol, silent: true);
    }
    
    notifyListeners();
  }

  void _setRefreshing(String symbol, bool refreshing) {
    _isRefreshing[symbol] = refreshing;
    notifyListeners();
  }

  void _updateLastUpdated(String symbol) {
    _lastUpdated[symbol] = DateTime.now();
  }

  /// Start real-time monitoring (can be enhanced for WebSocket in future)
  void startRealTimeMonitoring() {
    _startAutoRefresh();
    _startStatusCheck();
  }

  /// Stop real-time monitoring
  void stopRealTimeMonitoring() {
    _refreshTimer?.cancel();
    _statusTimer?.cancel();
  }

  /// Restart monitoring with new settings
  void restartMonitoring() {
    stopRealTimeMonitoring();
    startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}
