import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/cryptocurrency.dart';
import '../models/analysis_response.dart';
import '../models/chart_data.dart' as chart;
import '../models/news.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081';
  static const String apiPath = '/api/v1';
  static const String fullBaseUrl = '$baseUrl$apiPath';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final http.Client _client = http.Client();

  // === CRYPTOCURRENCY DATA ENDPOINTS ===

  /// Search cryptocurrencies by query
  Future<List<Cryptocurrency>> searchCryptocurrencies(String query, {int limit = 10}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/search/$query?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((crypto) => Cryptocurrency.fromJson(crypto))
              .toList();
        }
      }
      throw Exception('Failed to search cryptocurrencies: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error searching cryptocurrencies: $e');
    }
  }

  /// Get market data with pagination
  Future<List<Cryptocurrency>> getMarketData({int page = 1, int perPage = 50}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/market-data?page=$page&perPage=$perPage'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((crypto) => Cryptocurrency.fromJson(crypto))
              .toList();
        }
      }
      throw Exception('Failed to get market data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting market data: $e');
    }
  }

  /// Get individual cryptocurrency data
  Future<Cryptocurrency> getCryptocurrency(String symbol, {int days = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return Cryptocurrency.fromJson(apiResponse.data!);
        }
      }
      throw Exception('Failed to get cryptocurrency: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting cryptocurrency: $e');
    }
  }

  /// Get cryptocurrency details
  Future<Cryptocurrency> getCryptocurrencyDetails(String symbol) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/details/$symbol'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return Cryptocurrency.fromJson(apiResponse.data!);
        }
      }
      throw Exception('Failed to get cryptocurrency details: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting cryptocurrency details: $e');
    }
  }

  // === MARKET CHART DATA ===

  /// Get market chart data
  Future<List<ChartDataPoint>> getMarketChart(String symbol, {int days = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol/market-chart?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          // Backend returns List<List<Number>> format: [[timestamp, price], ...]
          return apiResponse.data!
              .map((point) => ChartDataPoint.fromJson(point))
              .toList();
        }
      }
      throw Exception('Failed to get market chart: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting market chart: $e');
    }
  }

  /// Get price chart data
  Future<List<List<num>>> getPriceChart(String symbol, {int days = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/price-chart/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((point) => (point as List).cast<num>())
              .toList();
        }
      }
      throw Exception('Failed to get price chart: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting price chart: $e');
    }
  }

  /// Get chart data
  Future<List<chart.ChartDataPoint>> getChartData(String symbol, [String timeframe = '7d']) async {
    try {
      // Convert timeframe to days
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

      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol/market-chart?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          // Backend returns List<List<Number>> format: [[timestamp, price], ...]
          return apiResponse.data!
              .map((item) => chart.ChartDataPoint.fromJson(item))
              .toList();
        }
      }
      throw Exception('Failed to get chart data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting chart data: $e');
    }
  }

  /// Get chart data points
  Future<List<chart.ChartDataPoint>> getChartDataPoints(String symbol, [int days = 30]) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/price-chart/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => chart.ChartDataPoint.fromJson(item))
              .toList();
        }
      }
      throw Exception('Failed to get price chart: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting price chart: $e');
    }
  }

  // === AI ANALYSIS ENDPOINTS ===

  /// Get complete AI analysis for a cryptocurrency
  Future<AnalysisResponse> getAnalysis(
    String symbol, {
    int days = 30,
    List<String>? types,
    bool refresh = false,
  }) async {
    try {
      String url = '$fullBaseUrl/crypto/analysis/$symbol';
      
      List<String> queryParams = [];
      if (days != 30) queryParams.add('days=$days');
      if (types != null && types.isNotEmpty) {
        queryParams.add('types=${types.join(',')}');
      }
      if (refresh) queryParams.add('refresh=true');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 120)); // Longer timeout for AI analysis

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return AnalysisResponse.fromJson(apiResponse.data!);
        }
      }
      throw Exception('Failed to get analysis: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting analysis: $e');
    }
  }

  /// Get available analysis types
  Future<Map<String, dynamic>> getAnalysisTypes() async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/analysis-types'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      throw Exception('Failed to get analysis types: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting analysis types: $e');
    }
  }

  // === NEWS DATA ===

  /// Get general crypto news
  Future<List<CryptoNews>> getCryptoNews({int limit = 50, String lang = 'EN'}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/news?limit=$limit&lang=$lang'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((newsData) => CryptoNews.fromJson(newsData))
              .toList();
        }
      }
      throw Exception('Failed to get crypto news: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting crypto news: $e');
    }
  }

  /// Get crypto news for a specific symbol
  Future<List<CryptoNews>> getCryptoNewsBySymbol(String symbol, {int limit = 20, String lang = 'EN'}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol/news?limit=$limit&lang=$lang'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((newsData) => CryptoNews.fromJson(newsData))
              .toList();
        }
      }
      throw Exception('Failed to get crypto news for $symbol: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting crypto news for $symbol: $e');
    }
  }

  // === UTILITY METHODS ===

  /// Test backend connection
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/analysis-types'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get backend health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/actuator/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'DOWN', 'details': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'status': 'DOWN', 'details': e.toString()};
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
