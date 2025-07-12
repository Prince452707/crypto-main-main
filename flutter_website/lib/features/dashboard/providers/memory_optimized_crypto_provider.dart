import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/optimized_api_service.dart';

class MemoryOptimizedCryptoProvider extends ChangeNotifier {
  final OptimizedApiService _apiService = OptimizedApiService();
  
  List<Cryptocurrency> _marketData = [];
  List<Cryptocurrency> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';
  
  // Memory optimization: limit data size
  static const int _maxMarketDataSize = 100;
  static const int _maxSearchResultsSize = 20;
  
  // Debounce timer for search
  Timer? _searchDebounceTimer;
  
  // Getters
  List<Cryptocurrency> get marketData => _marketData;
  List<Cryptocurrency> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  MemoryOptimizedCryptoProvider() {
    // Immediate background preload without showing loading
    _backgroundPreload();
  }

  /// Background preload for instant first render
  Future<void> _backgroundPreload() async {
    try {
      final data = await _apiService.getMarketDataOptimized(
        page: 1, 
        perPage: 50,
        useCache: true,
      );
      
      _marketData = data.take(_maxMarketDataSize).toList();
      // Don't notify listeners - this is background preload
    } catch (e) {
      // Silent fail for background preload
    }
  }

  /// Ultra-fast market data loading with memory limits
  Future<void> loadMarketDataInstant({bool refresh = false}) async {
    if (!refresh && _marketData.isNotEmpty) {
      // Return immediately if we have cached data
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getMarketDataOptimized(
        page: 1,
        perPage: _maxMarketDataSize,
        useCache: !refresh,
      );
      
      _marketData = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Debounced search for optimal performance
  void searchCryptocurrenciesDebounced(String query) {
    _searchQuery = query;
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    // Debounce for 300ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _apiService.searchCryptocurrenciesOptimized(
        query, 
        limit: _maxSearchResultsSize,
      );
      
      // Only update if query hasn't changed
      if (_searchQuery == query) {
        _searchResults = results;
      }
    } catch (e) {
      if (_searchQuery == query) {
        _error = e.toString();
        _searchResults = [];
      }
    } finally {
      if (_searchQuery == query) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  /// Get single cryptocurrency with instant cache check
  Future<Cryptocurrency?> getCryptocurrencyInstant(String symbol) async {
    // First check if it's already in our market data
    try {
      final existing = _marketData.firstWhere(
        (crypto) => crypto.symbol.toLowerCase() == symbol.toLowerCase(),
      );
      return existing;
    } catch (e) {
      // Not found in market data, fetch from API
      try {
        return await _apiService.getCryptocurrencyDetailsOptimized(symbol);
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return null;
      }
    }
  }

  /// Memory-efficient refresh
  Future<void> refreshQuick() async {
    // Only refresh visible data
    await loadMarketDataInstant(refresh: true);
  }

  /// Clear memory-heavy data
  void clearMemory() {
    _marketData.clear();
    _searchResults.clear();
    _apiService.clearCache();
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'marketDataCount': _marketData.length,
      'searchResultsCount': _searchResults.length,
      'cacheStats': _apiService.getCacheStats(),
      'memoryFootprint': {
        'marketData': _marketData.length * 100, // Rough estimate
        'searchResults': _searchResults.length * 100,
      }
    };
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
