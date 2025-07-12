import 'package:flutter/material.dart';
import '../../../core/models/crypto_detail.dart';
import '../../../core/services/focused_crypto_service.dart';

class FocusedCryptoProvider extends ChangeNotifier {
  final FocusedCryptoService _focusedService = FocusedCryptoService();
  
  CryptoDetail? _selectedCrypto;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _selectedCryptoId;
  Map<String, dynamic>? _rateLimitStatus;

  // Getters
  CryptoDetail? get selectedCrypto => _selectedCrypto;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String? get selectedCryptoId => _selectedCryptoId;
  Map<String, dynamic>? get rateLimitStatus => _rateLimitStatus;

  /// Load focused crypto data with comprehensive details
  Future<void> loadFocusedCryptoData(String cryptoId, {bool forceRefresh = false}) async {
    if (_isLoading || _isRefreshing) return;
    
    _isLoading = true;
    _error = null;
    _selectedCryptoId = cryptoId;
    notifyListeners();

    try {
      final cryptoDetail = await _focusedService.getFocusedCryptoData(
        cryptoId, 
        forceRefresh: forceRefresh
      );
      
      _selectedCrypto = cryptoDetail;
      _error = null;
      
      debugPrint('Loaded focused crypto data for: ${cryptoDetail.symbol}');
    } catch (e) {
      _error = 'Failed to load crypto data: ${e.toString()}';
      debugPrint('Error loading focused crypto data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the current crypto data
  Future<void> refreshCurrentCrypto() async {
    if (_selectedCryptoId == null || _isRefreshing) return;
    
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      final cryptoDetail = await _focusedService.refreshCryptoData(_selectedCryptoId!);
      _selectedCrypto = cryptoDetail;
      _error = null;
      
      debugPrint('Refreshed crypto data for: ${cryptoDetail.symbol}');
    } catch (e) {
      _error = 'Failed to refresh crypto data: ${e.toString()}';
      debugPrint('Error refreshing crypto data: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Get current rate limiting status
  Future<void> updateRateLimitStatus() async {
    try {
      _rateLimitStatus = await _focusedService.getRateLimitStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting rate limit status: $e');
    }
  }

  /// Clear cache for current crypto
  Future<void> clearCurrentCache() async {
    if (_selectedCryptoId == null) return;
    
    try {
      await _focusedService.clearCache(_selectedCryptoId!);
      debugPrint('Cache cleared for: $_selectedCryptoId');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear all cached data
  void clearAllCache() {
    _focusedService.clearAllCache();
    debugPrint('All cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _focusedService.getCacheStats();
  }

  /// Preload popular cryptocurrencies
  Future<void> preloadPopularCryptos() async {
    try {
      await _focusedService.preloadPopularCryptos();
      debugPrint('Started preloading popular cryptocurrencies');
    } catch (e) {
      debugPrint('Error preloading popular cryptos: $e');
    }
  }

  /// Reset state
  void reset() {
    _selectedCrypto = null;
    _isLoading = false;
    _isRefreshing = false;
    _error = null;
    _selectedCryptoId = null;
    _rateLimitStatus = null;
    notifyListeners();
  }

  /// Check if a crypto is currently selected
  bool isCryptoSelected(String cryptoId) {
    return _selectedCryptoId?.toLowerCase() == cryptoId.toLowerCase();
  }

  /// Get formatted error message
  String get formattedError {
    if (_error == null) return '';
    
    if (_error!.contains('429') || _error!.contains('Too Many Requests')) {
      return 'Rate limit exceeded. Please try again in a few minutes.';
    } else if (_error!.contains('404') || _error!.contains('not found')) {
      return 'Cryptocurrency not found. Please check the symbol and try again.';
    } else if (_error!.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    } else {
      return _error!;
    }
  }

  /// Get loading state description
  String get loadingStateDescription {
    if (_isRefreshing) return 'Refreshing cryptocurrency data...';
    if (_isLoading) return 'Loading cryptocurrency data...';
    return '';
  }

  @override
  void dispose() {
    _focusedService.dispose();
    super.dispose();
  }
}
