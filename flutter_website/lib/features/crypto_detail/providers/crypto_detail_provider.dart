import 'package:flutter/foundation.dart';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/api_service.dart';

class CryptoDetailProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Cryptocurrency? _cryptocurrency;
  bool _isLoading = false;
  String? _error;
  String? _currentSymbol;

  // Getters
  Cryptocurrency? get cryptocurrency => _cryptocurrency;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSymbol => _currentSymbol;

  /// Load cryptocurrency data
  Future<void> loadCryptocurrencyData(String symbol) async {
    if (_currentSymbol == symbol && _cryptocurrency != null) {
      return; // Already loaded this symbol
    }

    _currentSymbol = symbol;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cryptocurrency = await _apiService.getCryptocurrency(symbol);
      _error = null;
    } catch (e) {
      _error = 'Failed to load cryptocurrency data: $e';
      debugPrint('Error loading cryptocurrency data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current cryptocurrency data
  Future<void> refreshData() async {
    if (_currentSymbol != null) {
      _cryptocurrency = null; // Clear current data to force reload
      await loadCryptocurrencyData(_currentSymbol!);
    }
  }

  /// Clear current data
  void clearData() {
    _cryptocurrency = null;
    _error = null;
    _currentSymbol = null;
    notifyListeners();
  }
}
