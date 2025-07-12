import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/optimized_api_service.dart';

class OptimizedCryptoProvider extends ChangeNotifier {
  final OptimizedApiService _apiService = OptimizedApiService();
  
  List<Cryptocurrency> _marketData = [];
  List<Cryptocurrency> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Getters
  List<Cryptocurrency> get marketData => _marketData;
  List<Cryptocurrency> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;

  OptimizedCryptoProvider() {
    // Preload critical data immediately
    _preloadCriticalData();
    
    // Clean cache periodically
    _scheduleCleanup();
  }

  /// Preload critical data for faster initial load
  Future<void> _preloadCriticalData() async {
    try {
      await _apiService.preloadCriticalData();
    } catch (e) {
      // Silent fail for preload
    }
  }

  /// Load market data with intelligent caching
  Future<void> loadMarketData({
    int page = 1, 
    int perPage = 50, 
    bool refresh = false,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _apiService.getMarketDataOptimized(
        page: page,
        perPage: perPage,
        useCache: !refresh,
      );
      
      if (page == 1) {
        _marketData = data;
      } else {
        _marketData.addAll(data);
      }
      
      _currentPage = page;
      _hasMoreData = data.length == perPage;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load more data for pagination
  Future<void> loadMoreMarketData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final data = await _apiService.getMarketDataOptimized(
        page: nextPage,
        perPage: 50,
      );
      
      _marketData.addAll(data);
      _currentPage = nextPage;
      _hasMoreData = data.length == 50;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Search cryptocurrencies with debouncing
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
      final results = await _apiService.searchCryptocurrenciesOptimized(
        query, 
        limit: limit,
      );
      _searchResults = results;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Get cryptocurrency details
  Future<Cryptocurrency?> getCryptocurrencyDetails(String symbol) async {
    try {
      return await _apiService.getCryptocurrencyDetailsOptimized(symbol);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Batch load multiple cryptocurrencies
  Future<List<Cryptocurrency>> batchLoadCryptocurrencies(List<String> symbols) async {
    try {
      return await _apiService.batchLoadCryptocurrencies(symbols);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadMarketData(refresh: true);
  }

  /// Clear cache
  void clearCache() {
    _apiService.clearCache();
  }

  /// Schedule periodic cache cleanup
  void _scheduleCleanup() {
    // Clean expired cache every 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      _apiService.cleanExpiredCache();
      _scheduleCleanup(); // Schedule next cleanup
    });
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _apiService.getCacheStats();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
