class Cryptocurrency {
  final String id;
  final String name;
  final String symbol;
  final double? price;
  final double? marketCap;
  final double? fullyDilutedMarketCap;
  final double? volume24h;
  final double? percentChange24h;
  final double? percentChange7d;
  final double? percentChange30d;
  final double? percentChange1h;
  final double? allTimeHigh;
  final String? allTimeHighDate;
  final double? allTimeLow;
  final String? allTimeLowDate;
  final int? rank;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final String? lastUpdated;
  final double? high24h;
  final double? low24h;
  final double? priceChange24h;
  final double? athChangePercentage;
  final String? imageUrl;
  final String? websiteUrl;
  final String? description;
  final String? category;
  final String? platform;
  final String? contractAddress;
  final bool? isActive;
  final double? rsi;
  final double? volumeMarketCapRatio;
  final double? marketDominance;
  final int? tradingPairs;
  final double? volatility;
  final double? sharpeRatio;
  final double? sentimentScore;
  final int? socialMentions24h;
  final double? developerScore;
  final double? communityScore;
  final double? liquidityScore;
  final double? newsSentiment;

  const Cryptocurrency({
    required this.id,
    required this.name,
    required this.symbol,
    this.price,
    this.marketCap,
    this.fullyDilutedMarketCap,
    this.volume24h,
    this.percentChange24h,
    this.percentChange7d,
    this.percentChange30d,
    this.percentChange1h,
    this.allTimeHigh,
    this.allTimeHighDate,
    this.allTimeLow,
    this.allTimeLowDate,
    this.rank,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.lastUpdated,
    this.high24h,
    this.low24h,
    this.priceChange24h,
    this.athChangePercentage,
    this.imageUrl,
    this.websiteUrl,
    this.description,
    this.category,
    this.platform,
    this.contractAddress,
    this.isActive,
    this.rsi,
    this.volumeMarketCapRatio,
    this.marketDominance,
    this.tradingPairs,
    this.volatility,
    this.sharpeRatio,
    this.sentimentScore,
    this.socialMentions24h,
    this.developerScore,
    this.communityScore,
    this.liquidityScore,
    this.newsSentiment,
  });

  factory Cryptocurrency.fromJson(Map<String, dynamic> json) {
    return Cryptocurrency(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      price: _parseDouble(json['price']),
      marketCap: _parseDouble(json['market_cap'] ?? json['marketCap']),
      fullyDilutedMarketCap: _parseDouble(json['fully_diluted_market_cap'] ?? json['fullyDilutedMarketCap']),
      volume24h: _parseDouble(json['volume_24h'] ?? json['volume24h']),
      percentChange24h: _parseDouble(json['percent_change_24h'] ?? json['percentChange24h']),
      percentChange7d: _parseDouble(json['percent_change_7d'] ?? json['percentChange7d']),
      percentChange30d: _parseDouble(json['percent_change_30d'] ?? json['percentChange30d']),
      percentChange1h: _parseDouble(json['percent_change_1h'] ?? json['percentChange1h']),
      allTimeHigh: _parseDouble(json['ath'] ?? json['allTimeHigh']),
      allTimeHighDate: json['ath_date'] as String? ?? json['allTimeHighDate'] as String?,
      allTimeLow: _parseDouble(json['atl'] ?? json['allTimeLow']),
      allTimeLowDate: json['atl_date'] as String? ?? json['allTimeLowDate'] as String?,
      rank: _parseInt(json['market_cap_rank'] ?? json['rank']),
      circulatingSupply: _parseDouble(json['circulating_supply'] ?? json['circulatingSupply']),
      totalSupply: _parseDouble(json['total_supply'] ?? json['totalSupply']),
      maxSupply: _parseDouble(json['max_supply'] ?? json['maxSupply']),
      lastUpdated: json['last_updated'] as String? ?? json['lastUpdated'] as String?,
      high24h: _parseDouble(json['high_24h'] ?? json['high24h']),
      low24h: _parseDouble(json['low_24h'] ?? json['low24h']),
      priceChange24h: _parseDouble(json['price_change_24h'] ?? json['priceChange24h']),
      athChangePercentage: _parseDouble(json['ath_change_percentage'] ?? json['athChangePercentage']),
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      websiteUrl: json['website_url'] as String? ?? json['websiteUrl'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      platform: json['platform'] as String?,
      contractAddress: json['contract_address'] as String? ?? json['contractAddress'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool?,
      rsi: _parseDouble(json['rsi']),
      volumeMarketCapRatio: _parseDouble(json['volume_market_cap_ratio'] ?? json['volumeMarketCapRatio']),
      marketDominance: _parseDouble(json['market_dominance'] ?? json['marketDominance']),
      tradingPairs: _parseInt(json['trading_pairs'] ?? json['tradingPairs']),
      volatility: _parseDouble(json['volatility']),
      sharpeRatio: _parseDouble(json['sharpe_ratio'] ?? json['sharpeRatio']),
      sentimentScore: _parseDouble(json['sentiment_score'] ?? json['sentimentScore']),
      socialMentions24h: _parseInt(json['social_mentions_24h'] ?? json['socialMentions24h']),
      developerScore: _parseDouble(json['developer_score'] ?? json['developerScore']),
      communityScore: _parseDouble(json['community_score'] ?? json['communityScore']),
      liquidityScore: _parseDouble(json['liquidity_score'] ?? json['liquidityScore']),
      newsSentiment: _parseDouble(json['news_sentiment'] ?? json['newsSentiment']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'price': price,
      'market_cap': marketCap,
      'fully_diluted_market_cap': fullyDilutedMarketCap,
      'volume_24h': volume24h,
      'percent_change_24h': percentChange24h,
      'percent_change_7d': percentChange7d,
      'percent_change_30d': percentChange30d,
      'percent_change_1h': percentChange1h,
      'ath': allTimeHigh,
      'ath_date': allTimeHighDate,
      'atl': allTimeLow,
      'atl_date': allTimeLowDate,
      'market_cap_rank': rank,
      'circulating_supply': circulatingSupply,
      'total_supply': totalSupply,
      'max_supply': maxSupply,
      'last_updated': lastUpdated,
      'high_24h': high24h,
      'low_24h': low24h,
      'price_change_24h': priceChange24h,
      'ath_change_percentage': athChangePercentage,
      'image_url': imageUrl,
      'website_url': websiteUrl,
      'description': description,
      'category': category,
      'platform': platform,
      'contract_address': contractAddress,
      'is_active': isActive,
      'rsi': rsi,
      'volume_market_cap_ratio': volumeMarketCapRatio,
      'market_dominance': marketDominance,
      'trading_pairs': tradingPairs,
      'volatility': volatility,
      'sharpe_ratio': sharpeRatio,
      'sentiment_score': sentimentScore,
      'social_mentions_24h': socialMentions24h,
      'developer_score': developerScore,
      'community_score': communityScore,
      'liquidity_score': liquidityScore,
      'news_sentiment': newsSentiment,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  String toString() {
    return 'Cryptocurrency{id: $id, name: $name, symbol: $symbol, price: $price}';
  }

  // Helper methods for UI
  bool get isPriceUp => percentChange24h != null && percentChange24h! > 0;
  bool get isPriceDown => percentChange24h != null && percentChange24h! < 0;
  
  String get formattedPrice {
    if (price == null) return 'N/A';
    if (price! < 1) {
      return '\$${price!.toStringAsFixed(6)}';
    } else if (price! < 100) {
      return '\$${price!.toStringAsFixed(2)}';
    } else {
      return '\$${price!.toStringAsFixed(0)}';
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
    final sign = percentChange24h! >= 0 ? '+' : '';
    return '$sign${percentChange24h!.toStringAsFixed(2)}%';
  }
}
