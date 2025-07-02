import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class PortfolioItem {
  final String symbol;
  final String name;
  final double amount;
  final double buyPrice;
  final DateTime purchaseDate;
  double? currentPrice;

  PortfolioItem({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.buyPrice,
    required this.purchaseDate,
    this.currentPrice,
  });

  double get totalValue => (currentPrice ?? buyPrice) * amount;
  double get totalCost => buyPrice * amount;
  double get profit => totalValue - totalCost;
  double get profitPercentage => totalCost > 0 ? (profit / totalCost) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'amount': amount,
      'buyPrice': buyPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currentPrice': currentPrice,
    };
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      symbol: json['symbol'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      buyPrice: (json['buyPrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
    );
  }
}

class PortfolioProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PortfolioItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<PortfolioItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalValue => _items.fold(0, (sum, item) => sum + item.totalValue);
  double get totalCost => _items.fold(0, (sum, item) => sum + item.totalCost);
  double get totalProfit => totalValue - totalCost;
  double get totalProfitPercentage => totalCost > 0 ? (totalProfit / totalCost) * 100 : 0;

  PortfolioProvider() {
    // Initialize with empty portfolio
    _loadPortfolioFromStorage();
  }

  void _loadPortfolioFromStorage() {
    // In a real app, load from local storage or backend
    // For now, start with empty portfolio
    _items = [];
    notifyListeners();
  }

  void addItem(PortfolioItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(int index, PortfolioItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      notifyListeners();
    }
  }

  Future<void> refreshPrices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch current prices for all portfolio items from backend
      for (var item in _items) {
        try {
          final cryptoDetails = await _apiService.getCryptocurrencyDetails(item.symbol);
          if (cryptoDetails.price != null) {
            item.currentPrice = cryptoDetails.price!;
          }
        } catch (e) {
          debugPrint('Error fetching price for ${item.symbol}: $e');
          // Continue with other items even if one fails
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPortfolio() {
    _items.clear();
    notifyListeners();
  }
}
