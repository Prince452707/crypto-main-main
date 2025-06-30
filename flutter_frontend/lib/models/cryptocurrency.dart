class Cryptocurrency {
  final String id;
  final String name;
  final String symbol;
  final double? price;
  final double? marketCap;
  final double? volume24h;
  final double? percentChange24h;
  final double? percentChange7d;
  final double? percentChange30d;
  final int? rank;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final String? imageUrl;
  final DateTime? lastUpdated;
  final double? high24h;
  final double? low24h;
  final double? allTimeHigh;
  final double? allTimeLow;
  final String? description;

  Cryptocurrency({
    required this.id,
    required this.name,
    required this.symbol,
    this.price,
    this.marketCap,
    this.volume24h,
    this.percentChange24h,
    this.percentChange7d,
    this.percentChange30d,
    this.rank,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.imageUrl,
    this.lastUpdated,
    this.high24h,
    this.low24h,
    this.allTimeHigh,
    this.allTimeLow,
    this.description,
  });

  factory Cryptocurrency.fromJson(Map<String, dynamic> json) {
    return Cryptocurrency(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      price: _parseDouble(json['price']),
      marketCap: _parseDouble(json['marketCap']),
      volume24h: _parseDouble(json['volume24h']),
      percentChange24h: _parseDouble(json['percentChange24h']),
      percentChange7d: _parseDouble(json['percentChange7d']),
      percentChange30d: _parseDouble(json['percentChange30d']),
      rank: json['rank'] as int?,
      circulatingSupply: _parseDouble(json['circulatingSupply']),
      totalSupply: _parseDouble(json['totalSupply']),
      maxSupply: _parseDouble(json['maxSupply']),
      imageUrl: json['imageUrl'] as String?,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
      high24h: _parseDouble(json['high24h']),
      low24h: _parseDouble(json['low24h']),
      allTimeHigh: _parseDouble(json['allTimeHigh']),
      allTimeLow: _parseDouble(json['allTimeLow']),
      description: json['description'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'price': price,
      'marketCap': marketCap,
      'volume24h': volume24h,
      'percentChange24h': percentChange24h,
      'percentChange7d': percentChange7d,
      'percentChange30d': percentChange30d,
      'rank': rank,
      'circulatingSupply': circulatingSupply,
      'totalSupply': totalSupply,
      'maxSupply': maxSupply,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'high24h': high24h,
      'low24h': low24h,
      'allTimeHigh': allTimeHigh,
      'allTimeLow': allTimeLow,
      'description': description,
    };
  }

  bool get isPositiveChange => (percentChange24h ?? 0) > 0;
  
  String get formattedPrice {
    if (price == null) return 'N/A';
    if (price! >= 1) {
      return '\$${price!.toStringAsFixed(2)}';
    } else {
      return '\$${price!.toStringAsFixed(6)}';
    }
  }

  String get formattedMarketCap {
    if (marketCap == null) return 'N/A';
    if (marketCap! >= 1e12) {
      return '\$${(marketCap! / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap! >= 1e9) {
      return '\$${(marketCap! / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap! >= 1e6) {
      return '\$${(marketCap! / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${marketCap!.toStringAsFixed(0)}';
    }
  }

  String get formattedVolume24h {
    if (volume24h == null) return 'N/A';
    if (volume24h! >= 1e9) {
      return '\$${(volume24h! / 1e9).toStringAsFixed(2)}B';
    } else if (volume24h! >= 1e6) {
      return '\$${(volume24h! / 1e6).toStringAsFixed(2)}M';
    } else if (volume24h! >= 1e3) {
      return '\$${(volume24h! / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${volume24h!.toStringAsFixed(0)}';
    }
  }

  String get formattedPercentChange24h {
    if (percentChange24h == null) return 'N/A';
    final prefix = percentChange24h! >= 0 ? '+' : '';
    return '$prefix${percentChange24h!.toStringAsFixed(2)}%';
  }
}
