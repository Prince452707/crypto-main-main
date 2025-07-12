import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/cryptocurrency.dart';

class OptimizedApiService {
  static const String baseUrl = 'http://localhost:8081';
  static const String apiPath = '/api/v1';
  static const String fullBaseUrl = '$baseUrl$apiPath';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Connection': 'keep-alive',
    'Cache-Control': 'max-age=30',
  };

  static final http.Client _client = http.Client();
  
 
  static final Map<String, _CacheEntry> _cache = {};
  static const int _cacheExpirationMs = 300000; // 5 minutes cache
  

  static final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// Get market data with aggressive caching and optimization
  Future<List<Cryptocurrency>> getMarketDataOptimized({
    int page = 1, 
    int perPage = 50,
    bool useCache = true,
  }) async {
    final cacheKey = 'market_data_${page}_$perPage';
    
    // Check cache first
    if (useCache && _isValidCache(cacheKey)) {
      return List<Cryptocurrency>.from(_cache[cacheKey]!.data);
    }
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }
    
    // Create new request
    final completer = Completer<List<Cryptocurrency>>();
    _pendingRequests[cacheKey] = completer;
    
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/market-data?page=$page&perPage=$perPage'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15)); // Shorter timeout

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          final result = apiResponse.data!
              .map((crypto) => Cryptocurrency.fromJson(crypto))
              .toList();
          
          // Cache the result
          _cache[cacheKey] = _CacheEntry(result, DateTime.now());
          
          completer.complete(result);
          return result;
        }
      }
      throw Exception('Failed to get market data: ${response.statusCode}');
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Search cryptocurrencies with intelligent caching
  Future<List<Cryptocurrency>> searchCryptocurrenciesOptimized(
    String query, {
    int limit = 10,
    bool useCache = true,
  }) async {
    final normalizedQuery = query.toLowerCase().trim();
    final cacheKey = 'search_${normalizedQuery}_$limit';
    
    if (normalizedQuery.isEmpty) return [];
    
    // Check cache
    if (useCache && _isValidCache(cacheKey)) {
      return List<Cryptocurrency>.from(_cache[cacheKey]!.data);
    }
    
    // Deduplicate requests
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }
    
    final completer = Completer<List<Cryptocurrency>>();
    _pendingRequests[cacheKey] = completer;
    
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/search/$normalizedQuery?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          final result = apiResponse.data!
              .map((crypto) => Cryptocurrency.fromJson(crypto))
              .toList();
          
          _cache[cacheKey] = _CacheEntry(result, DateTime.now());
          
          completer.complete(result);
          return result;
        }
      }
      throw Exception('Failed to search: ${response.statusCode}');
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Get cryptocurrency details with caching
  Future<Cryptocurrency?> getCryptocurrencyDetailsOptimized(
    String symbol, {
    bool useCache = true,
  }) async {
    final cacheKey = 'details_${symbol.toLowerCase()}';
    
    if (useCache && _isValidCache(cacheKey)) {
      return _cache[cacheKey]!.data as Cryptocurrency?;
    }
    
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }
    
    final completer = Completer<Cryptocurrency?>();
    _pendingRequests[cacheKey] = completer;
    
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          final result = Cryptocurrency.fromJson(apiResponse.data!);
          _cache[cacheKey] = _CacheEntry(result, DateTime.now());
          
          completer.complete(result);
          return result;
        }
      }
      completer.complete(null);
      return null;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Batch load multiple cryptocurrencies efficiently
  Future<List<Cryptocurrency>> batchLoadCryptocurrencies(
    List<String> symbols, {
    bool useCache = true,
  }) async {
    // Check cache for already loaded symbols
    final results = <Cryptocurrency>[];
    final symbolsToLoad = <String>[];
    
    if (useCache) {
      for (final symbol in symbols) {
        final cacheKey = 'details_${symbol.toLowerCase()}';
        if (_isValidCache(cacheKey)) {
          final cached = _cache[cacheKey]!.data as Cryptocurrency?;
          if (cached != null) {
            results.add(cached);
          }
        } else {
          symbolsToLoad.add(symbol);
        }
      }
    } else {
      symbolsToLoad.addAll(symbols);
    }
    
    // Load remaining symbols in parallel
    if (symbolsToLoad.isNotEmpty) {
      final futures = symbolsToLoad.map((symbol) => 
        getCryptocurrencyDetailsOptimized(symbol, useCache: false)
      ).toList();
      
      final loadedCryptos = await Future.wait(futures);
      results.addAll(loadedCryptos.whereType<Cryptocurrency>());
    }
    
    return results;
  }

  /// Clear cache manually
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      print('OptimizedApiService: Cache cleared');
    }
  }

  /// Clean expired cache entries
  void cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) =>
        now.difference(entry.timestamp).inMilliseconds > _cacheExpirationMs);
  }

  /// Check if cache entry is valid
  bool _isValidCache(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    final age = DateTime.now().difference(entry.timestamp).inMilliseconds;
    return age < _cacheExpirationMs;
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'pendingRequests': _pendingRequests.length,
      'entries': _cache.keys.toList(),
    };
  }

  /// Preload frequently accessed data
  Future<void> preloadCriticalData() async {
    try {
      // Preload top market data
      await getMarketDataOptimized(page: 1, perPage: 20, useCache: false);
      
      // Preload top cryptocurrencies
      final topSymbols = ['bitcoin', 'ethereum', 'binancecoin', 'cardano', 'solana'];
      await batchLoadCryptocurrencies(topSymbols, useCache: false);
      
      if (kDebugMode) {
        print('OptimizedApiService: Critical data preloaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OptimizedApiService: Preload failed: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _cache.clear();
    _pendingRequests.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  _CacheEntry(this.data, this.timestamp);
}
