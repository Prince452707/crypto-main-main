import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/api_service.dart';

class CryptoProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Cryptocurrency> _marketData = [];
  List<Cryptocurrency> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Cryptocurrency> get marketData => _marketData;
  List<Cryptocurrency> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Load market data
  Future<void> loadMarketData({int page = 1, int perPage = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getMarketData(page: page, perPage: perPage);
      _marketData = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search cryptocurrencies
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
      final results = await _apiService.searchCryptocurrencies(query, limit: limit);
      _searchResults = results;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Get cryptocurrency details
  Future<Cryptocurrency?> getCryptocurrencyDetails(String symbol) async {
    try {
      return await _apiService.getCryptocurrencyDetails(symbol);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadMarketData();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
