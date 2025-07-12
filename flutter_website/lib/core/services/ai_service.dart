import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/analysis_response.dart';

class AIService {
  static const String baseUrl = 'http://localhost:8081';
  static const String apiPath = '/api/v1';
  static const String fullBaseUrl = '$baseUrl$apiPath';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final http.Client _client = http.Client();

  /// Get AI analysis for a cryptocurrency
  Future<AnalysisResponse> getCryptoAnalysis(String symbol, {int days = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/analysis/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 180)); // Extended timeout for AI analysis

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return AnalysisResponse.fromJson(apiResponse.data!);
        }
      }
      throw Exception('Failed to get AI analysis: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting AI analysis: $e');
    }
  }

  /// Get similar cryptocurrencies analysis
  Future<List<Map<String, dynamic>>> getSimilarCryptos(String symbol) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/similar/$symbol'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as List<dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }
      throw Exception('Failed to get similar cryptos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting similar cryptos: $e');
    }
  }

  /// Get AI market sentiment for a cryptocurrency
  Future<Map<String, dynamic>> getMarketSentiment(String symbol) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/sentiment/$symbol'),
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
      throw Exception('Failed to get market sentiment: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting market sentiment: $e');
    }
  }

  /// Generate AI insights for a specific cryptocurrency
  Future<String> generateInsight(String symbol, String type) async {
    try {
      final response = await _client.post(
        Uri.parse('$fullBaseUrl/crypto/insight'),
        headers: _headers,
        body: json.encode({
          'symbol': symbol,
          'type': type,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!['insight'] as String? ?? '';
        }
      }
      throw Exception('Failed to generate insight: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error generating insight: $e');
    }
  }

  /// Get AI-powered price prediction
  Future<Map<String, dynamic>> getPricePrediction(String symbol, {int days = 30}) async {
    try {
      final response = await _client.get(
        Uri.parse('$fullBaseUrl/crypto/prediction/$symbol?days=$days'),
        headers: _headers,
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      throw Exception('Failed to get price prediction: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting price prediction: $e');
    }
  }

  /// Ask a question about a specific cryptocurrency (Enhanced AI)
  Future<Map<String, dynamic>> askCryptoQuestion(String symbol, String question) async {
    try {
      // Try enhanced AI endpoint first
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/ai/crypto/question/$symbol'),
        headers: _headers,
        body: json.encode({
          'question': question,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      
      // Fallback to basic endpoint if enhanced fails
      final fallbackResponse = await _client.post(
        Uri.parse('$fullBaseUrl/crypto/question/$symbol'),
        headers: _headers,
        body: json.encode({
          'question': question,
        }),
      ).timeout(const Duration(seconds: 120));

      if (fallbackResponse.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(fallbackResponse.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      throw Exception('Failed to get answer: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting answer: $e');
    }
  }

  /// Ask a general cryptocurrency question (Enhanced AI)
  Future<Map<String, dynamic>> askGeneralCryptoQuestion(String question) async {
    try {
      // Try enhanced AI endpoint first
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/ai/crypto/question'),
        headers: _headers,
        body: json.encode({
          'question': question,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      
      // Fallback to basic endpoint if enhanced fails
      final fallbackResponse = await _client.post(
        Uri.parse('$fullBaseUrl/crypto/question'),
        headers: _headers,
        body: json.encode({
          'question': question,
        }),
      ).timeout(const Duration(seconds: 120));

      if (fallbackResponse.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(fallbackResponse.body),
          (json) => json as Map<String, dynamic>,
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        }
      }
      throw Exception('Failed to get answer: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error getting answer: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
