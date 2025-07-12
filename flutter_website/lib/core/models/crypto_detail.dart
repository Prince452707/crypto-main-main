class CryptoDetail {
  final String? id;
  final String symbol;
  final String name;
  final String? description;
  final double? currentPrice;
  final double? marketCap;
  final double? volume24h;
  final double? priceChange24h;
  final double? priceChangePercentage24h;
  final double? priceChangePercentage7d;
  final double? priceChangePercentage30d;
  final double? priceChangePercentage1y;
  final int? marketCapRank;
  final double? fullyDilutedValuation;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double? ath;
  final double? athChangePercentage;
  final DateTime? athDate;
  final double? atl;
  final double? atlChangePercentage;
  final DateTime? atlDate;
  final String? imageUrl;
  final String? websiteUrl;
  final String? explorerUrl;
  final String? sourceCodeUrl;
  final List<String>? categories;
  final double? communityScore;
  final double? developerScore;
  final double? liquidityScore;
  final double? publicInterestScore;
  final Map<String, dynamic>? additionalData;
  final DateTime? lastUpdated;
  final List<String>? dataSources;

  CryptoDetail({
    this.id,
    required this.symbol,
    required this.name,
    this.description,
    this.currentPrice,
    this.marketCap,
    this.volume24h,
    this.priceChange24h,
    this.priceChangePercentage24h,
    this.priceChangePercentage7d,
    this.priceChangePercentage30d,
    this.priceChangePercentage1y,
    this.marketCapRank,
    this.fullyDilutedValuation,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.ath,
    this.athChangePercentage,
    this.athDate,
    this.atl,
    this.atlChangePercentage,
    this.atlDate,
    this.imageUrl,
    this.websiteUrl,
    this.explorerUrl,
    this.sourceCodeUrl,
    this.categories,
    this.communityScore,
    this.developerScore,
    this.liquidityScore,
    this.publicInterestScore,
    this.additionalData,
    this.lastUpdated,
    this.dataSources,
  });

  factory CryptoDetail.fromJson(Map<String, dynamic> json) {
    return CryptoDetail(
      id: json['id']?.toString(),
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      currentPrice: _parseDouble(json['currentPrice'] ?? json['price']),
      marketCap: _parseDouble(json['marketCap']),
      volume24h: _parseDouble(json['volume24h']),
      priceChange24h: _parseDouble(json['priceChange24h']),
      priceChangePercentage24h: _parseDouble(json['priceChangePercentage24h'] ?? json['percentChange24h']),
      priceChangePercentage7d: _parseDouble(json['priceChangePercentage7d']),
      priceChangePercentage30d: _parseDouble(json['priceChangePercentage30d']),
      priceChangePercentage1y: _parseDouble(json['priceChangePercentage1y']),
      marketCapRank: _parseInt(json['marketCapRank'] ?? json['rank']),
      fullyDilutedValuation: _parseDouble(json['fullyDilutedValuation']),
      circulatingSupply: _parseDouble(json['circulatingSupply']),
      totalSupply: _parseDouble(json['totalSupply']),
      maxSupply: _parseDouble(json['maxSupply']),
      ath: _parseDouble(json['ath']),
      athChangePercentage: _parseDouble(json['athChangePercentage']),
      athDate: _parseDateTime(json['athDate']),
      atl: _parseDouble(json['atl']),
      atlChangePercentage: _parseDouble(json['atlChangePercentage']),
      atlDate: _parseDateTime(json['atlDate']),
      imageUrl: json['imageUrl']?.toString(),
      websiteUrl: json['websiteUrl']?.toString(),
      explorerUrl: json['explorerUrl']?.toString(),
      sourceCodeUrl: json['sourceCodeUrl']?.toString(),
      categories: _parseStringList(json['categories']),
      communityScore: _parseDouble(json['communityScore']),
      developerScore: _parseDouble(json['developerScore']),
      liquidityScore: _parseDouble(json['liquidityScore']),
      publicInterestScore: _parseDouble(json['publicInterestScore']),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      lastUpdated: _parseDateTime(json['lastUpdated']),
      dataSources: _parseStringList(json['dataSources']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'description': description,
      'currentPrice': currentPrice,
      'marketCap': marketCap,
      'volume24h': volume24h,
      'priceChange24h': priceChange24h,
      'priceChangePercentage24h': priceChangePercentage24h,
      'priceChangePercentage7d': priceChangePercentage7d,
      'priceChangePercentage30d': priceChangePercentage30d,
      'priceChangePercentage1y': priceChangePercentage1y,
      'marketCapRank': marketCapRank,
      'fullyDilutedValuation': fullyDilutedValuation,
      'circulatingSupply': circulatingSupply,
      'totalSupply': totalSupply,
      'maxSupply': maxSupply,
      'ath': ath,
      'athChangePercentage': athChangePercentage,
      'athDate': athDate?.toIso8601String(),
      'atl': atl,
      'atlChangePercentage': atlChangePercentage,
      'atlDate': atlDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'websiteUrl': websiteUrl,
      'explorerUrl': explorerUrl,
      'sourceCodeUrl': sourceCodeUrl,
      'categories': categories,
      'communityScore': communityScore,
      'developerScore': developerScore,
      'liquidityScore': liquidityScore,
      'publicInterestScore': publicInterestScore,
      'additionalData': additionalData,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'dataSources': dataSources,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Helper getters
  bool get isPriceUp => (priceChangePercentage24h ?? 0) > 0;
  bool get isPriceDown => (priceChangePercentage24h ?? 0) < 0;
  
  String get formattedPrice {
    if (currentPrice == null) return 'N/A';
    return '\$${currentPrice!.toStringAsFixed(currentPrice! < 1 ? 4 : 2)}';
  }

  String get formattedMarketCap {
    if (marketCap == null) return 'N/A';
    if (marketCap! >= 1e9) {
      return '\$${(marketCap! / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap! >= 1e6) {
      return '\$${(marketCap! / 1e6).toStringAsFixed(2)}M';
    } else if (marketCap! >= 1e3) {
      return '\$${(marketCap! / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${marketCap!.toStringAsFixed(2)}';
  }

  String get formattedVolume {
    if (volume24h == null) return 'N/A';
    if (volume24h! >= 1e9) {
      return '\$${(volume24h! / 1e9).toStringAsFixed(2)}B';
    } else if (volume24h! >= 1e6) {
      return '\$${(volume24h! / 1e6).toStringAsFixed(2)}M';
    } else if (volume24h! >= 1e3) {
      return '\$${(volume24h! / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${volume24h!.toStringAsFixed(2)}';
  }

  String get formattedPriceChange {
    if (priceChangePercentage24h == null) return 'N/A';
    final sign = priceChangePercentage24h! >= 0 ? '+' : '';
    return '$sign${priceChangePercentage24h!.toStringAsFixed(2)}%';
  }

  @override
  String toString() {
    return 'CryptoDetail(symbol: $symbol, name: $name, price: $formattedPrice, change: $formattedPriceChange)';
  }
}
