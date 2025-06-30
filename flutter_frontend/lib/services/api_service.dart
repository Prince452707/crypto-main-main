import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cryptocurrency.dart';
import '../models/analysis_response.dart';
import '../models/api_response.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081';
  static const String apiVersion = 'v1';
  static const String fullBaseUrl = '$baseUrl/api/$apiVersion';
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static void initialize() {
    // Any initialization logic can go here
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Search cryptocurrencies
  Future<List<Cryptocurrency>> searchCryptocurrencies(String query, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/search/$query?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as List<dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => Cryptocurrency.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching cryptocurrencies: $e');
      return [];
    }
  }

  // Get cryptocurrency details
  Future<Cryptocurrency?> getCryptocurrencyDetails(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as Map<String, dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return Cryptocurrency.fromJson(apiResponse.data!);
        }
      }
      return null;
    } catch (e) {
      print('Error getting cryptocurrency details: $e');
      return null;
    }
  }

  // Get comprehensive analysis
  Future<AnalysisResponse?> getCryptoAnalysis(String symbol, {int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/analysis/$symbol/$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 180)); // Extended timeout for AI analysis

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as Map<String, dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return AnalysisResponse.fromJson(apiResponse.data!);
        }
      }
      return null;
    } catch (e) {
      print('Error getting crypto analysis: $e');
      return null;
    }
  }

  // Get market data (popular cryptocurrencies)
  Future<List<Cryptocurrency>> getMarketData({int page = 1, int perPage = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/market-data?page=$page&perPage=$perPage'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as List<dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => Cryptocurrency.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting market data: $e');
      return [];
    }
  }

  // Get market chart data
  Future<List<List<double>>> getMarketChart(String symbol, {int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/$symbol/market-chart?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as List<dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => (item as List<dynamic>)
                  .map((value) => (value as num).toDouble())
                  .toList())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting market chart: $e');
      return [];
    }
  }

  // Get price chart data
  Future<List<List<double>>> getPriceChart(String symbol, {int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$fullBaseUrl/crypto/price-chart/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as List<dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => (item as List<dynamic>)
                  .map((value) => (value as num).toDouble())
                  .toList())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting price chart: $e');
      return [];
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/actuator/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
