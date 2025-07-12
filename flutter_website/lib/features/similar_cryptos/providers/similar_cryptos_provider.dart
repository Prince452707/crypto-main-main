import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class SimilarCryptosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<SimilarCryptocurrency> _similarCryptos = [];
  String? _comparisonAnalysis;
  List<String> _similarityCriteria = [];
  String? _currentSymbol;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SimilarCryptocurrency> get similarCryptos => _similarCryptos;
  String? get comparisonAnalysis => _comparisonAnalysis;
  List<String> get similarityCriteria => _similarityCriteria;
  String? get currentSymbol => _currentSymbol;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Find similar cryptocurrencies for a given symbol
  Future<void> findSimilarCryptocurrencies(String symbol, {int limit = 5, bool includeAnalysis = true}) async {
    _currentSymbol = symbol;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.findSimilarCryptocurrencies(symbol, limit: limit, includeAnalysis: includeAnalysis);
      
      _similarCryptos = (response['similar_cryptocurrencies'] as List<dynamic>)
          .map((item) => SimilarCryptocurrency.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _comparisonAnalysis = response['comparison_analysis'] as String?;
      _similarityCriteria = (response['similarity_criteria'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [];
      
      _error = null;
    } catch (e) {
      _error = 'Failed to find similar cryptocurrencies: $e';
      debugPrint('Error finding similar cryptocurrencies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear current similar cryptocurrencies data
  void clearSimilarCryptos() {
    _similarCryptos.clear();
    _comparisonAnalysis = null;
    _similarityCriteria.clear();
    _currentSymbol = null;
    _error = null;
    notifyListeners();
  }

  /// Refresh similar cryptocurrencies data
  Future<void> refresh() async {
    if (_currentSymbol != null) {
      await findSimilarCryptocurrencies(_currentSymbol!);
    }
  }
}

class SimilarCryptocurrency {
  final String symbol;
  final double similarityScore;
  final List<String> matchReasons;
  final String? name;
  final double? price;
  final double? percentChange24h;
  final int? rank;

  SimilarCryptocurrency({
    required this.symbol,
    required this.similarityScore,
    required this.matchReasons,
    this.name,
    this.price,
    this.percentChange24h,
    this.rank,
  });

  factory SimilarCryptocurrency.fromJson(Map<String, dynamic> json) {
    return SimilarCryptocurrency(
      symbol: json['symbol'] as String,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      matchReasons: (json['match_reasons'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      percentChange24h: (json['percent_change_24h'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'similarity_score': similarityScore,
      'match_reasons': matchReasons,
      'name': name,
      'price': price,
      'percent_change_24h': percentChange24h,
      'rank': rank,
    };
  }

  /// Get similarity percentage (0-100)
  double get similarityPercentage => similarityScore * 100;

  /// Get formatted similarity score
  String get formattedSimilarityScore => '${similarityPercentage.toStringAsFixed(1)}%';

  /// Get similarity level description
  String get similarityLevel {
    if (similarityPercentage >= 90) return 'Very High';
    if (similarityPercentage >= 80) return 'High';
    if (similarityPercentage >= 70) return 'Moderate';
    if (similarityPercentage >= 60) return 'Low';
    return 'Very Low';
  }

  /// Get similarity level color
  Color get similarityColor {
    if (similarityPercentage >= 90) return const Color(0xFF2E7D32); // Dark Green
    if (similarityPercentage >= 80) return const Color(0xFF388E3C); // Green
    if (similarityPercentage >= 70) return const Color(0xFF689F38); // Light Green
    if (similarityPercentage >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFD32F2F); // Red
  }
}
