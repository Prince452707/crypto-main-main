import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/models/analysis_response.dart';
import '../../../core/models/chart_data.dart' as chart;
import '../../../core/services/websocket_service.dart';
import '../../../core/services/api_service.dart';

class RealTimeCryptoProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  Cryptocurrency? _currentCrypto;
  AnalysisResponse? _currentAnalysis;
  List<chart.ChartDataPoint> _chartData = [];
  String? _currentSymbol;
  String _connectionStatus = 'disconnected';
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  
  // Auto-refresh settings - OPTIMIZED INTERVALS
  bool _autoRefreshEnabled = true;
  Duration _refreshInterval = const Duration(minutes: 2); // Changed from 30s to 2 minutes
  String _selectedTimeframe = '7d';
  
  // Getters
  Cryptocurrency? get currentCrypto => _currentCrypto;
  AnalysisResponse? get currentAnalysis => _currentAnalysis;
  List<chart.ChartDataPoint> get chartData => _chartData;
  String? get currentSymbol => _currentSymbol;
  String get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _webSocketService.isConnected;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  Duration get refreshInterval => _refreshInterval;
  String get selectedTimeframe => _selectedTimeframe;

  RealTimeCryptoProvider() {
    _initializeWebSocket();
  }

  /// Initialize WebSocket connection and listeners
  void _initializeWebSocket() {
    // Listen to connection status
    _webSocketService.connectionStatusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
      
      if (status == 'connected' && _currentSymbol != null) {
        // Re-subscribe if we were tracking a symbol
        _webSocketService.subscribe(_currentSymbol!);
      }
    });

    // Listen to price updates
    _webSocketService.priceUpdateStream.listen((crypto) {
      if (crypto != null && crypto.symbol.toLowerCase() == _currentSymbol?.toLowerCase()) {
        _currentCrypto = crypto;
        _error = null;
        notifyListeners();
        
        debugPrint('🔄 Real-time data updated for ${crypto.symbol}');
      }
    });

    // Listen to general messages
    _webSocketService.messageStream.listen((message) {
      final type = message['type'];
      if (type == 'error') {
        _error = message['message'];
        notifyListeners();
      }
    });
  }

  /// Start tracking a cryptocurrency with real-time updates
  Future<void> startTracking(String symbol) async {
    if (_currentSymbol == symbol && _webSocketService.isConnected) {
      return; // Already tracking this symbol
    }

    _isLoading = true;
    _error = null;
    _currentSymbol = symbol.toLowerCase();
    notifyListeners();

    try {
      // Load initial data
      await _loadInitialData(symbol);
      
      // Connect to WebSocket and subscribe (but don't fail if WebSocket is down)
      try {
        await _webSocketService.connect();
        await _webSocketService.subscribe(symbol);
        debugPrint('✅ WebSocket connected for real-time updates');
      } catch (e) {
        debugPrint('⚠️ WebSocket connection failed, continuing without real-time updates: $e');
        _error = 'Real-time updates unavailable. Data will refresh periodically.';
      }
      
      // Start auto-refresh if enabled
      if (_autoRefreshEnabled) {
        _startAutoRefresh();
      }
      
      debugPrint('✅ Started real-time tracking for $symbol');
      
    } catch (e) {
      _error = 'Failed to start tracking: $e';
      debugPrint('❌ Error starting real-time tracking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stop tracking current cryptocurrency
  void stopTracking() {
    if (_currentSymbol != null) {
      _webSocketService.unsubscribe();
      _stopAutoRefresh();
      _currentSymbol = null;
      _currentCrypto = null;
      _currentAnalysis = null;
      _chartData.clear();
      notifyListeners();
      
      debugPrint('🛑 Stopped real-time tracking');
    }
  }

  /// Load initial data for a cryptocurrency
  Future<void> _loadInitialData(String symbol) async {
    try {
      // Load cryptocurrency data with fallback
      try {
        final crypto = await _apiService.getCryptocurrency(symbol, days: 1);
        _currentCrypto = crypto;
      } catch (e) {
        debugPrint('⚠️ Failed to load crypto data: $e');
        // Create a minimal crypto object if API fails
        _currentCrypto = Cryptocurrency(
          id: symbol.toLowerCase(),
          name: symbol.toUpperCase(),
          symbol: symbol.toUpperCase(),
          price: 0.0,
          percentChange24h: 0.0,
        );
      }
      
      // Load analysis data with fallback
      try {
        final analysis = await _apiService.getAnalysis(symbol, days: 7);
        _currentAnalysis = analysis;
      } catch (e) {
        debugPrint('⚠️ Failed to load analysis data: $e');
        _currentAnalysis = null;
      }
      
      // Load chart data with fallback
      try {
        final chartData = await _apiService.getChartDataPoints(symbol, 7);
        _chartData = chartData;
      } catch (e) {
        debugPrint('⚠️ Failed to load chart data: $e');
        _chartData = [];
      }
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('⚠️ Critical error loading initial data: $e');
      
      // Set a more user-friendly error message
      if (e.toString().contains('Network error') || e.toString().contains('Failed to fetch') || 
          e.toString().contains('429') || e.toString().contains('rate limit')) {
        throw Exception('Cryptocurrency data APIs are currently rate limited. Please try again in a few minutes. Some features may be unavailable.');
      } else {
        throw e;
      }
    }
  }

  /// Force refresh current cryptocurrency data
  Future<void> forceRefresh() async {
    if (_currentSymbol == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Force WebSocket refresh
      _webSocketService.forceRefresh();
      
      // Also refresh via API call with cache bypass
      await _loadInitialData(_currentSymbol!);
      
      debugPrint('🔄 Force refresh completed for $_currentSymbol');
      
    } catch (e) {
      _error = 'Refresh failed: $e';
      debugPrint('❌ Force refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _stopAutoRefresh();
    
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (_currentSymbol != null && !_isLoading) {
        forceRefresh();
      }
    });
    
    debugPrint('⏰ Auto-refresh started (${_refreshInterval.inSeconds}s interval)');
  }

  /// Stop auto-refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Toggle auto-refresh
  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    
    if (_autoRefreshEnabled && _currentSymbol != null) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
    
    notifyListeners();
    debugPrint('🔄 Auto-refresh ${_autoRefreshEnabled ? 'enabled' : 'disabled'}');
  }

  /// Set refresh interval
  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;
    
    if (_autoRefreshEnabled && _currentSymbol != null) {
      _startAutoRefresh(); // Restart with new interval
    }
    
    notifyListeners();
    debugPrint('⏰ Refresh interval set to ${interval.inSeconds}s');
  }

  /// Update chart data timeframe
  Future<void> updateChartTimeframe(String timeframe) async {
    if (_currentSymbol == null) return;

    _selectedTimeframe = timeframe;
    _isLoading = true;
    notifyListeners();

    try {
      int days;
      switch (timeframe) {
        case '1d':
          days = 1;
          break;
        case '7d':
          days = 7;
          break;
        case '30d':
          days = 30;
          break;
        case '90d':
          days = 90;
          break;
        case '1y':
          days = 365;
          break;
        default:
          days = 7;
      }
      
      _chartData = await _apiService.getChartDataPoints(_currentSymbol!, days);
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to update chart: $e';
      debugPrint('❌ Chart update error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check connection health
  void checkConnection() {
    if (!_webSocketService.isConnected && _currentSymbol != null) {
      debugPrint('🔗 Attempting to reconnect WebSocket');
      _webSocketService.connect().then((_) {
        if (_currentSymbol != null) {
          _webSocketService.subscribe(_currentSymbol!);
        }
      });
    }
  }

  /// Get last update time
  DateTime? getLastUpdateTime() {
    return _currentCrypto?.lastUpdated != null 
        ? DateTime.tryParse(_currentCrypto!.lastUpdated!)
        : null;
  }

  /// Check if data is fresh (updated within last minute)
  bool isDataFresh() {
    final lastUpdate = getLastUpdateTime();
    if (lastUpdate == null) return false;
    
    return DateTime.now().difference(lastUpdate).inMinutes < 1;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _webSocketService.disconnect();
    super.dispose();
  }
}
