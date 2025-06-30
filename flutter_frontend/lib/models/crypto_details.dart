class CryptoDetails {
  final String id;
  final String name;
  final String symbol;
  final String description;
  final Map<String, dynamic> marketData;
  final Map<String, dynamic> links;
  final int marketCapRank;

  CryptoDetails({
    required this.id,
    required this.name,
    required this.symbol,
    required this.description,
    required this.marketData,
    required this.links,
    required this.marketCapRank,
  });

  factory CryptoDetails.fromJson(Map<String, dynamic> json) {
    return CryptoDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      marketData: Map<String, dynamic>.from(json['marketData'] ?? {}),
      links: Map<String, dynamic>.from(json['links'] ?? {}),
      marketCapRank: json['marketCapRank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'description': description,
      'marketData': marketData,
      'links': links,
      'marketCapRank': marketCapRank,
    };
  }

  String get websiteUrl => links['homepage']?.toString() ?? '';
  String get twitterUrl => links['twitter_screen_name'] != null 
      ? 'https://twitter.com/${links['twitter_screen_name']}'
      : '';
  String get githubUrl => links['repos_url']?.toString() ?? '';
}
