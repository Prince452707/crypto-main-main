import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/news.dart';

class NewsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CryptoNews> _generalNews = [];
  Map<String, List<CryptoNews>> _symbolNews = {};
  bool _isLoading = false;
  bool _isLoadingSymbolNews = false;
  String? _error;

  List<CryptoNews> get generalNews => _generalNews;
  Map<String, List<CryptoNews>> get symbolNews => _symbolNews;
  bool get isLoading => _isLoading;
  bool get isLoadingSymbolNews => _isLoadingSymbolNews;
  String? get error => _error;

  List<CryptoNews> getNewsForSymbol(String symbol) {
    return _symbolNews[symbol.toUpperCase()] ?? [];
  }

  Future<void> loadGeneralNews({int limit = 50, String lang = 'EN'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _generalNews = await _apiService.getCryptoNews(limit: limit, lang: lang);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading general news: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNewsForSymbol(String symbol, {int limit = 20, String lang = 'EN'}) async {
    _isLoadingSymbolNews = true;
    _error = null;
    notifyListeners();

    try {
      final news = await _apiService.getCryptoNewsBySymbol(
        symbol,
        limit: limit,
        lang: lang,
      );
      _symbolNews[symbol.toUpperCase()] = news;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading news for $symbol: $e');
    } finally {
      _isLoadingSymbolNews = false;
      notifyListeners();
    }
  }

  Future<void> refreshNews({int limit = 50, String lang = 'EN'}) async {
    await loadGeneralNews(limit: limit, lang: lang);
  }

  Future<void> refreshNewsForSymbol(String symbol, {int limit = 20, String lang = 'EN'}) async {
    await loadNewsForSymbol(symbol, limit: limit, lang: lang);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
