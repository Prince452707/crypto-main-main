import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/models/cryptocurrency.dart';
import '../../../core/services/api_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Set<String> _bookmarkedSymbols = {};
  List<Cryptocurrency> _bookmarkedCryptos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Set<String> get bookmarkedSymbols => _bookmarkedSymbols;
  List<Cryptocurrency> get bookmarkedCryptos => _bookmarkedCryptos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get bookmarkCount => _bookmarkedSymbols.length;

  BookmarkProvider() {
    _loadBookmarks();
  }

  /// Check if a cryptocurrency is bookmarked
  bool isBookmarked(String symbol) {
    return _bookmarkedSymbols.contains(symbol.toLowerCase());
  }

  /// Add a cryptocurrency to bookmarks
  Future<void> addBookmark(String symbol, {String? name}) async {
    final symbolLower = symbol.toLowerCase();
    
    if (_bookmarkedSymbols.contains(symbolLower)) {
      return; // Already bookmarked
    }

    _bookmarkedSymbols.add(symbolLower);
    await _saveBookmarks();
    
    // Refresh bookmark data
    await _refreshBookmarkData();
    
    notifyListeners();
  }

  /// Remove a cryptocurrency from bookmarks
  Future<void> removeBookmark(String symbol) async {
    final symbolLower = symbol.toLowerCase();
    
    if (!_bookmarkedSymbols.contains(symbolLower)) {
      return; // Not bookmarked
    }

    _bookmarkedSymbols.remove(symbolLower);
    _bookmarkedCryptos.removeWhere((crypto) => crypto.symbol.toLowerCase() == symbolLower);
    
    await _saveBookmarks();
    notifyListeners();
  }

  /// Toggle bookmark status
  Future<void> toggleBookmark(String symbol, {String? name}) async {
    if (isBookmarked(symbol)) {
      await removeBookmark(symbol);
    } else {
      await addBookmark(symbol, name: name);
    }
  }

  /// Clear all bookmarks
  Future<void> clearBookmarks() async {
    _bookmarkedSymbols.clear();
    _bookmarkedCryptos.clear();
    await _saveBookmarks();
    notifyListeners();
  }

  /// Refresh bookmark data from API
  Future<void> refreshBookmarkData() async {
    await _refreshBookmarkData();
  }

  /// Load bookmarks from persistent storage
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString('crypto_bookmarks');
      
      if (bookmarksJson != null) {
        final List<dynamic> bookmarksList = json.decode(bookmarksJson);
        _bookmarkedSymbols.clear();
        _bookmarkedSymbols.addAll(bookmarksList.cast<String>());
        
        // Load crypto data for bookmarked symbols
        await _refreshBookmarkData();
      } else {
        // Initialize with default bookmarks
        _bookmarkedSymbols.addAll(['bitcoin', 'ethereum', 'binancecoin']);
        await _saveBookmarks();
        await _refreshBookmarkData();
      }
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
      debugPrint('Error loading bookmarks: $e');
    }
  }

  /// Save bookmarks to persistent storage
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = json.encode(_bookmarkedSymbols.toList());
      await prefs.setString('crypto_bookmarks', bookmarksJson);
    } catch (e) {
      _error = 'Failed to save bookmarks: $e';
      debugPrint('Error saving bookmarks: $e');
    }
  }

  /// Refresh cryptocurrency data for bookmarked symbols
  Future<void> _refreshBookmarkData() async {
    if (_bookmarkedSymbols.isEmpty) {
      _bookmarkedCryptos.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Cryptocurrency> cryptos = [];
      
      // Fetch data for each bookmarked symbol
      for (String symbol in _bookmarkedSymbols) {
        try {
          final crypto = await _apiService.getCryptocurrency(symbol);
          cryptos.add(crypto);
        } catch (e) {
          debugPrint('Error fetching data for $symbol: $e');
          // Continue with other bookmarks even if one fails
        }
      }

      _bookmarkedCryptos = cryptos;
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh bookmark data: $e';
      debugPrint('Error refreshing bookmark data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get bookmarked cryptocurrencies sorted by a specific criteria
  List<Cryptocurrency> getBookmarksSorted({String sortBy = 'rank'}) {
    final sortedList = List<Cryptocurrency>.from(_bookmarkedCryptos);
    
    switch (sortBy) {
      case 'rank':
        sortedList.sort((a, b) => (a.rank ?? 999999).compareTo(b.rank ?? 999999));
        break;
      case 'name':
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        sortedList.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'change24h':
        sortedList.sort((a, b) => (b.percentChange24h ?? 0).compareTo(a.percentChange24h ?? 0));
        break;
      case 'marketCap':
        sortedList.sort((a, b) => (b.marketCap ?? 0).compareTo(a.marketCap ?? 0));
        break;
      default:
        // Default to rank
        sortedList.sort((a, b) => (a.rank ?? 999999).compareTo(b.rank ?? 999999));
        break;
    }
    
    return sortedList;
  }

  /// Import bookmarks from a list of symbols
  Future<void> importBookmarks(List<String> symbols) async {
    try {
      _bookmarkedSymbols.clear();
      _bookmarkedSymbols.addAll(symbols.map((s) => s.toLowerCase()));
      
      await _saveBookmarks();
      await _refreshBookmarkData();
    } catch (e) {
      _error = 'Failed to import bookmarks: $e';
      debugPrint('Error importing bookmarks: $e');
    }
  }

  /// Export bookmarks as a list of symbols
  List<String> exportBookmarks() {
    return _bookmarkedSymbols.toList();
  }
}
