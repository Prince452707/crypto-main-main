class Watchlist {
  final String id;
  final String name;
  final String? description;
  final List<String> symbols;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  const Watchlist({
    required this.id,
    required this.name,
    this.description,
    required this.symbols,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      symbols: List<String>.from(json['symbols'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'symbols': symbols,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  Watchlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? symbols,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      symbols: symbols ?? this.symbols,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  bool containsSymbol(String symbol) {
    return symbols.contains(symbol.toUpperCase());
  }

  int get count => symbols.length;
}

class WatchlistItem {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change24h;
  final double changePercent24h;
  final double marketCap;
  final double volume24h;
  final DateTime lastUpdated;

  const WatchlistItem({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change24h,
    required this.changePercent24h,
    required this.marketCap,
    required this.volume24h,
    required this.lastUpdated,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'],
      name: json['name'],
      currentPrice: (json['currentPrice'] as num).toDouble(),
      change24h: (json['change24h'] as num).toDouble(),
      changePercent24h: (json['changePercent24h'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      volume24h: (json['volume24h'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'change24h': change24h,
      'changePercent24h': changePercent24h,
      'marketCap': marketCap,
      'volume24h': volume24h,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  bool get isPositive => change24h >= 0;
}
