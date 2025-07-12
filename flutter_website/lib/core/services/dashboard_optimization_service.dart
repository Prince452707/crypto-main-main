import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/cryptocurrency.dart';

/// Service to optimize dashboard API calls and reduce server load
class DashboardOptimizationService {
  static final DashboardOptimizationService _instance = DashboardOptimizationService._internal();
  factory DashboardOptimizationService() => _instance;
  DashboardOptimizationService._internal();

  final ApiService _apiService = ApiService();
  
  // Cache management
  final Map<String, Cryptocurrency> _cryptoCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Queue<String> _recentQueries = Queue<String>();
  
  // Request batching
  Timer? _batchTimer;
  final Set<String> _pendingRequests = {};
  final List<String> _batchQueue = [];
  
  // Configuration
  static const Duration _cacheValidityDuration = Duration(minutes: 3);
  static const Duration _batchDelay = Duration(milliseconds: 500);
  static const int _maxCacheSize = 100;
  static const int _maxBatchSize = 10;

  /// Get cryptocurrency data with intelligent caching and batching
  Future<Cryptocurrency?> getCryptocurrency(String symbol) async {
    final normalizedSymbol = symbol.toLowerCase();
    
    // Check cache first
    if (_isCacheValid(normalizedSymbol)) {
      debugPrint('📋 Cache HIT for $symbol');
      return _cryptoCache[normalizedSymbol];
    }
    
    // Avoid duplicate requests
    if (_pendingRequests.contains(normalizedSymbol)) {
      debugPrint('⏳ Request already pending for $symbol');
      return _waitForPendingRequest(normalizedSymbol);
    }
    
    // Add to batch queue
    return _addToBatch(normalizedSymbol);
  }

  /// Get multiple cryptocurrencies with optimized batching
  Future<List<Cryptocurrency>> getMultipleCryptocurrencies(List<String> symbols) async {
    final List<Cryptocurrency> results = [];
    final List<String> uncachedSymbols = [];
    
    // Check cache for each symbol
    for (String symbol in symbols) {
      final normalizedSymbol = symbol.toLowerCase();
      if (_isCacheValid(normalizedSymbol)) {
        results.add(_cryptoCache[normalizedSymbol]!);
      } else {
        uncachedSymbols.add(normalizedSymbol);
      }
    }
    
    // Fetch uncached symbols in batches
    if (uncachedSymbols.isNotEmpty) {
      final freshData = await _fetchBatch(uncachedSymbols);
      results.addAll(freshData);
    }
    
    return results;
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String symbol) {
    final timestamp = _cacheTimestamps[symbol];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheValidityDuration;
  }

  /// Add symbol to batch queue and wait for batch processing
  Future<Cryptocurrency?> _addToBatch(String symbol) async {
    final completer = Completer<Cryptocurrency?>();
    
    // Mark as pending
    _pendingRequests.add(symbol);
    _batchQueue.add(symbol);
    
    // Start batch timer if not already running
    _batchTimer ??= Timer(_batchDelay, _processBatch);
    
    // Wait for batch processing
    try {
      // Set up a timeout for the batch processing
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Batch timeout for $symbol');
          _pendingRequests.remove(symbol);
          return null;
        },
      );
    } catch (e) {
      _pendingRequests.remove(symbol);
      return null;
    }
  }

  /// Wait for an already pending request to complete
  Future<Cryptocurrency?> _waitForPendingRequest(String symbol) async {
    // Poll cache until data is available or timeout
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (_isCacheValid(symbol)) {
        return _cryptoCache[symbol];
      }
    }
    return null;
  }

  /// Process batch queue
  void _processBatch() async {
    _batchTimer = null;
    
    if (_batchQueue.isEmpty) return;
    
    final batchToProcess = List<String>.from(_batchQueue.take(_maxBatchSize));
    _batchQueue.removeRange(0, batchToProcess.length.clamp(0, _batchQueue.length));
    
    debugPrint('🚀 Processing batch of ${batchToProcess.length} symbols: ${batchToProcess.join(', ')}');
    
    try {
      final results = await _fetchBatch(batchToProcess);
      
      // Update cache with results
      for (var crypto in results) {
        _updateCache(crypto.symbol.toLowerCase(), crypto);
      }
      
    } catch (e) {
      debugPrint('❌ Batch processing failed: $e');
    } finally {
      // Remove from pending
      for (String symbol in batchToProcess) {
        _pendingRequests.remove(symbol);
      }
      
      // Process remaining queue if any
      if (_batchQueue.isNotEmpty) {
        _batchTimer = Timer(_batchDelay, _processBatch);
      }
    }
  }

  /// Fetch a batch of cryptocurrencies from API
  Future<List<Cryptocurrency>> _fetchBatch(List<String> symbols) async {
    if (symbols.length == 1) {
      try {
        final crypto = await _apiService.getCryptocurrency(symbols.first);
        return [crypto];
      } catch (e) {
        debugPrint('❌ Single fetch failed for ${symbols.first}: $e');
        return [];
      }
    }
    
    // For multiple symbols, try to get market data efficiently
    try {
      final marketData = await _apiService.getMarketData(perPage: symbols.length * 2);
      
      // Filter to requested symbols
      final requestedSymbols = symbols.map((s) => s.toLowerCase()).toSet();
      return marketData.where((crypto) => 
        requestedSymbols.contains(crypto.symbol.toLowerCase())
      ).toList();
      
    } catch (e) {
      debugPrint('❌ Batch fetch failed: $e');
      
      // Fallback: fetch individually with delays
      final results = <Cryptocurrency>[];
      for (int i = 0; i < symbols.length; i++) {
        try {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 200)); // Throttle requests
          }
          final crypto = await _apiService.getCryptocurrency(symbols[i]);
          results.add(crypto);
        } catch (e) {
          debugPrint('❌ Individual fallback fetch failed for ${symbols[i]}: $e');
        }
      }
      return results;
    }
  }

  /// Update cache with new data
  void _updateCache(String symbol, Cryptocurrency crypto) {
    // Implement LRU cache eviction
    if (_cryptoCache.length >= _maxCacheSize) {
      _evictOldestCacheEntry();
    }
    
    _cryptoCache[symbol] = crypto;
    _cacheTimestamps[symbol] = DateTime.now();
    _recentQueries.remove(symbol);
    _recentQueries.addLast(symbol);
    
    debugPrint('💾 Cached data for $symbol');
  }

  /// Evict oldest cache entry (LRU)
  void _evictOldestCacheEntry() {
    if (_recentQueries.isNotEmpty) {
      final oldestSymbol = _recentQueries.removeFirst();
      _cryptoCache.remove(oldestSymbol);
      _cacheTimestamps.remove(oldestSymbol);
      debugPrint('🗑️ Evicted cache for $oldestSymbol');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cryptoCache.clear();
    _cacheTimestamps.clear();
    _recentQueries.clear();
    debugPrint('🧹 Cache cleared');
  }

  /// Clear cache for specific symbol
  void clearCacheForSymbol(String symbol) {
    final normalizedSymbol = symbol.toLowerCase();
    _cryptoCache.remove(normalizedSymbol);
    _cacheTimestamps.remove(normalizedSymbol);
    _recentQueries.remove(normalizedSymbol);
    debugPrint('🧹 Cache cleared for $symbol');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (String symbol in _cacheTimestamps.keys) {
      final timestamp = _cacheTimestamps[symbol]!;
      if (now.difference(timestamp) < _cacheValidityDuration) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }
    
    return {
      'totalEntries': _cryptoCache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'pendingRequests': _pendingRequests.length,
      'queuedRequests': _batchQueue.length,
      'cacheHitRate': _recentQueries.length > 0 ? (validEntries / _recentQueries.length * 100).toStringAsFixed(1) + '%' : '0%',
    };
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    clearCache();
    _pendingRequests.clear();
    _batchQueue.clear();
  }
}
