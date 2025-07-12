import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/cryptocurrency.dart';
import '../models/crypto_detail.dart';

class FocusedCryptoService {
  static const String baseUrl = 'http://localhost:8081';
  static const String apiPath = '/api/v1/crypto/focused';
  static const String fullBaseUrl = '$baseUrl$apiPath';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Connection': 'keep-alive',
  };

  // Persistent HTTP client
  static final http.Client _client = http.Client();
  
  // Cache for focused crypto data
  static final Map<String, _CachedCryptoData> _focusedCache = {};
  static const int _cacheExpirationMs = 60000; // 1 minute cache for focused data

  /// Get comprehensive focused crypto data with all available details
  Future<CryptoDetail> getFocusedCryptoData(String cryptoId, {bool forceRefresh = false}) async {
    final normalizedId = cryptoId.toLowerCase().trim();
    final cacheKey = 'focused_$normalizedId';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _isValidCache(cacheKey)) {
      debugPrint('Cache hit for focused crypto: $normalizedId');
      return _focusedCache[cacheKey]!.data as CryptoDetail;
    }

    try {
      final uri = Uri.parse('$fullBaseUrl/$normalizedId?forceRefresh=$forceRefresh');
      debugPrint('Fetching focused crypto data from: $uri');
      
      final response = await _client.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final cryptoDetail = CryptoDetail.fromJson(jsonResponse['data']);
          
          // Cache the result
          _focusedCache[cacheKey] = _CachedCryptoData(cryptoDetail, DateTime.now());
          
          debugPrint('Successfully fetched focused data for: $normalizedId');
          return cryptoDetail;
        } else {
          throw Exception('Invalid response format: ${jsonResponse['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching focused crypto data for $normalizedId: $e');
      rethrow;
    }
  }

  /// Refresh crypto data (force refresh from all providers)
  Future<CryptoDetail> refreshCryptoData(String cryptoId) async {
    final normalizedId = cryptoId.toLowerCase().trim();
    
    try {
      final uri = Uri.parse('$fullBaseUrl/$normalizedId/refresh');
      debugPrint('Refreshing crypto data from: $uri');
      
      final response = await _client.post(uri, headers: _headers)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final cryptoDetail = CryptoDetail.fromJson(jsonResponse['data']);
          
          // Update cache
          final cacheKey = 'focused_$normalizedId';
          _focusedCache[cacheKey] = _CachedCryptoData(cryptoDetail, DateTime.now());
          
          debugPrint('Successfully refreshed data for: $normalizedId');
          return cryptoDetail;
        } else {
          throw Exception('Refresh failed: ${jsonResponse['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error refreshing crypto data for $normalizedId: $e');
      rethrow;
    }
  }

  /// Get rate limiting status from backend
  Future<Map<String, dynamic>> getRateLimitStatus() async {
    try {
      final uri = Uri.parse('$fullBaseUrl/status/rate-limits');
      final response = await _client.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting rate limit status: $e');
      rethrow;
    }
  }

  /// Clear cache for specific crypto
  Future<void> clearCache(String cryptoId) async {
    final normalizedId = cryptoId.toLowerCase().trim();
    
    try {
      // Clear local cache
      _focusedCache.remove('focused_$normalizedId');
      
      // Clear backend cache
      final uri = Uri.parse('$fullBaseUrl/$normalizedId/cache');
      await _client.delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      
      debugPrint('Cache cleared for: $normalizedId');
    } catch (e) {
      debugPrint('Error clearing cache for $normalizedId: $e');
    }
  }

  /// Preload popular cryptocurrencies
  Future<void> preloadPopularCryptos() async {
    try {
      final uri = Uri.parse('$fullBaseUrl/preload');
      final response = await _client.post(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Successfully started preloading popular cryptocurrencies');
      } else {
        debugPrint('Failed to start preloading: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error preloading popular cryptos: $e');
    }
  }

  /// Check if cached data is still valid
  bool _isValidCache(String key) {
    if (!_focusedCache.containsKey(key)) {
      return false;
    }
    
    final cachedData = _focusedCache[key]!;
    final now = DateTime.now();
    final age = now.difference(cachedData.timestamp).inMilliseconds;
    
    return age < _cacheExpirationMs;
  }

  /// Clear all cached data
  void clearAllCache() {
    _focusedCache.clear();
    debugPrint('All focused crypto cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validEntries = _focusedCache.entries.where((entry) => 
        _isValidCache(entry.key)).length;
    
    return {
      'totalEntries': _focusedCache.length,
      'validEntries': validEntries,
      'expiredEntries': _focusedCache.length - validEntries,
      'cacheHitRate': validEntries / (_focusedCache.length + 1), // Avoid division by zero
    };
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

class _CachedCryptoData {
  final dynamic data;
  final DateTime timestamp;

  _CachedCryptoData(this.data, this.timestamp);
}
