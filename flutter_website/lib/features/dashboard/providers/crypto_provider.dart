import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/dashboard_optimization_service.dart';

class CryptoProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DashboardOptimizationService _optimizationService = DashboardOptimizationService();
  late final RealTimeService _realTimeService;
  
  List<Cryptocurrency> _marketData = [];
  List<Cryptocurrency> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';
  bool _realTimeEnabled = true;

  CryptoProvider() {
    _realTimeService = RealTimeService(_apiService);
    _realTimeService.addListener(_onRealTimeUpdate);
  }

  // Getters
  List<Cryptocurrency> get marketData => _marketData;
  List<Cryptocurrency> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get realTimeEnabled => _realTimeEnabled;
  RealTimeService get realTimeService => _realTimeService;

  // Real-time update handler
  void _onRealTimeUpdate() {
    // Trigger UI updates when real-time service notifies changes
    notifyListeners();
  }

  // Load market data with OPTIMIZED API calls
  Future<void> loadMarketData({int page = 1, int perPage = 50, bool fresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Cryptocurrency> data;
      if (fresh && _realTimeEnabled) {
        // Use optimization service to reduce redundant API calls
        data = await _apiService.getMarketData(page: page, perPage: perPage);
        // Smart refresh only for critical symbols to reduce load
        final criticalSymbols = data.take(10).map((c) => c.symbol).toList();
        final freshData = await _optimizationService.getMultipleCryptocurrencies(criticalSymbols);
        
        // Merge fresh data with existing data
        final Map<String, Cryptocurrency> freshMap = {
          for (var crypto in freshData) crypto.symbol.toLowerCase(): crypto
        };
        
        data = data.map((crypto) {
          return freshMap[crypto.symbol.toLowerCase()] ?? crypto;
        }).toList();
      } else {
        data = await _apiService.getMarketData(page: page, perPage: perPage);
      }
      _marketData = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search cryptocurrencies
  Future<void> searchCryptocurrencies(String query, {int limit = 10}) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.searchCryptocurrencies(query, limit: limit);
      _searchResults = results;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Get cryptocurrency details with OPTIMIZED caching
  Future<Cryptocurrency?> getCryptocurrencyDetails(String symbol, {bool fresh = false}) async {
    try {
      if (fresh && _realTimeEnabled) {
        return await _realTimeService.getFreshCryptocurrency(symbol);
      } else {
        // Use optimization service for intelligent caching
        return await _optimizationService.getCryptocurrency(symbol);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Refresh data with real-time support
  Future<void> refresh({bool force = false}) async {
    if (force && _realTimeEnabled) {
      await loadMarketData(fresh: true);
    } else {
      await loadMarketData();
    }
  }

  // Clear cache and refresh with SMART optimization
  Future<void> clearCacheAndRefresh() async {
    // Clear optimization service cache too
    _optimizationService.clearCache();
    
    if (_realTimeEnabled) {
      await _realTimeService.clearAllCache();
      await loadMarketData(fresh: true);
    } else {
      await loadMarketData();
    }
  }

  // Toggle real-time mode
  void toggleRealTimeMode() {
    _realTimeEnabled = !_realTimeEnabled;
    if (_realTimeEnabled) {
      _realTimeService.startRealTimeMonitoring();
    } else {
      _realTimeService.stopRealTimeMonitoring();
    }
    notifyListeners();
  }

  // Get data freshness info for a symbol
  String getDataAge(String symbol) {
    return _realTimeService.getDataAge(symbol);
  }

  // Check if symbol data is being refreshed
  bool isSymbolRefreshing(String symbol) {
    return _realTimeService.isRefreshing(symbol);
  }

  // Check if symbol data is fresh
  bool isSymbolDataFresh(String symbol) {
    return _realTimeService.isDataFresh(symbol);
  }

  // Get optimization service statistics
  Map<String, dynamic> getOptimizationStats() {
    return _optimizationService.getCacheStats();
  }

  @override
  void dispose() {
    _realTimeService.removeListener(_onRealTimeUpdate);
    _realTimeService.dispose();
    _optimizationService.dispose();
    _apiService.dispose();
    super.dispose();
  }
}
