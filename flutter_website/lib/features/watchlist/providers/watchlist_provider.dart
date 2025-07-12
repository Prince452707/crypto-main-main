import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/watchlist.dart';

class WatchlistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Watchlist> _watchlists = [];
  Map<String, List<WatchlistItem>> _watchlistData = {};
  String? _selectedWatchlistId;
  bool _isLoading = false;
  String? _error;
  
  List<Watchlist> get watchlists => _watchlists;
  Map<String, List<WatchlistItem>> get watchlistData => _watchlistData;
  String? get selectedWatchlistId => _selectedWatchlistId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Watchlist? get selectedWatchlist => _selectedWatchlistId != null
      ? _watchlists.firstWhere((w) => w.id == _selectedWatchlistId, orElse: () => _watchlists.first)
      : _watchlists.isNotEmpty ? _watchlists.first : null;
  
  List<WatchlistItem> get selectedWatchlistData => 
      selectedWatchlist != null ? _watchlistData[selectedWatchlist!.id] ?? [] : [];

  WatchlistProvider() {
    _initializeDefaultWatchlists();
  }

  void _initializeDefaultWatchlists() {
    _watchlists = [
      Watchlist(
        id: 'default',
        name: 'My Favorites',
        description: 'Your favorite cryptocurrencies',
        symbols: ['BTC', 'ETH', 'BNB', 'ADA', 'SOL'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      Watchlist(
        id: 'top10',
        name: 'Top 10',
        description: 'Top 10 cryptocurrencies by market cap',
        symbols: ['BTC', 'ETH', 'USDT', 'BNB', 'SOL', 'USDC', 'XRP', 'STETH', 'TON', 'DOGE'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Watchlist(
        id: 'defi',
        name: 'DeFi Tokens',
        description: 'Decentralized Finance tokens',
        symbols: ['UNI', 'AAVE', 'SUSHI', 'COMP', 'MKR', 'SNX', 'YFI', 'CRV'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    _selectedWatchlistId = 'default';
    notifyListeners();
  }

  Future<void> loadWatchlistData(String watchlistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final watchlist = _watchlists.firstWhere((w) => w.id == watchlistId);
      final items = <WatchlistItem>[];
      
      // Load data for each symbol in the watchlist
      for (final symbol in watchlist.symbols) {
        try {
          final crypto = await _apiService.getCryptocurrencyDetails(symbol);
          items.add(WatchlistItem(
            symbol: crypto.symbol,
            name: crypto.name,
            currentPrice: crypto.price ?? 0,
            change24h: crypto.priceChange24h ?? 0,
            changePercent24h: crypto.percentChange24h ?? 0,
            marketCap: crypto.marketCap ?? 0,
            volume24h: crypto.volume24h ?? 0,
            lastUpdated: DateTime.now(),
          ));
        } catch (e) {
          debugPrint('Error loading data for $symbol: $e');
        }
      }
      
      _watchlistData[watchlistId] = items;
      
    } catch (e) {
      _error = 'Failed to load watchlist data: $e';
      debugPrint('Error loading watchlist data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWatchlist(String name, {String? description}) async {
    try {
      final watchlist = Watchlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        symbols: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _watchlists.add(watchlist);
      _watchlistData[watchlist.id] = [];
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to create watchlist: $e';
    }
  }

  Future<void> deleteWatchlist(String watchlistId) async {
    try {
      final watchlist = _watchlists.firstWhere((w) => w.id == watchlistId);
      if (watchlist.isDefault) {
        _error = 'Cannot delete default watchlist';
        return;
      }
      
      _watchlists.removeWhere((w) => w.id == watchlistId);
      _watchlistData.remove(watchlistId);
      
      // Select another watchlist if current one was deleted
      if (_selectedWatchlistId == watchlistId) {
        _selectedWatchlistId = _watchlists.isNotEmpty ? _watchlists.first.id : null;
      }
      
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to delete watchlist: $e';
    }
  }

  Future<void> addToWatchlist(String watchlistId, String symbol) async {
    try {
      final index = _watchlists.indexWhere((w) => w.id == watchlistId);
      if (index == -1) return;
      
      final watchlist = _watchlists[index];
      if (!watchlist.symbols.contains(symbol.toUpperCase())) {
        final updatedSymbols = [...watchlist.symbols, symbol.toUpperCase()];
        _watchlists[index] = watchlist.copyWith(
          symbols: updatedSymbols,
          updatedAt: DateTime.now(),
        );
        
        // Reload data for this watchlist
        await loadWatchlistData(watchlistId);
      }
      
    } catch (e) {
      _error = 'Failed to add to watchlist: $e';
    }
  }

  Future<void> removeFromWatchlist(String watchlistId, String symbol) async {
    try {
      final index = _watchlists.indexWhere((w) => w.id == watchlistId);
      if (index == -1) return;
      
      final watchlist = _watchlists[index];
      final updatedSymbols = watchlist.symbols.where((s) => s != symbol.toUpperCase()).toList();
      
      _watchlists[index] = watchlist.copyWith(
        symbols: updatedSymbols,
        updatedAt: DateTime.now(),
      );
      
      // Update cached data
      if (_watchlistData.containsKey(watchlistId)) {
        _watchlistData[watchlistId] = _watchlistData[watchlistId]!
            .where((item) => item.symbol != symbol.toUpperCase())
            .toList();
      }
      
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to remove from watchlist: $e';
    }
  }

  void selectWatchlist(String watchlistId) {
    _selectedWatchlistId = watchlistId;
    notifyListeners();
    
    // Load data if not already loaded
    if (!_watchlistData.containsKey(watchlistId)) {
      loadWatchlistData(watchlistId);
    }
  }

  bool isInWatchlist(String watchlistId, String symbol) {
    final watchlist = _watchlists.firstWhere((w) => w.id == watchlistId, orElse: () => 
        Watchlist(id: '', name: '', symbols: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
    return watchlist.containsSymbol(symbol);
  }

  Future<void> refreshCurrentWatchlist() async {
    if (_selectedWatchlistId != null) {
      await loadWatchlistData(_selectedWatchlistId!);
    }
  }
}
