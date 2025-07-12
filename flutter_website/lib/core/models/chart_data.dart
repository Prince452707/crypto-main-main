class ChartDataPoint {
  final int timestamp;
  final double price;
  final DateTime? lastUpdated;
  final String? source;
  final bool isRealData;
  final double? precisePriceUsd;
  final double? marketCap;
  final double? volume;

  const ChartDataPoint({
    required this.timestamp,
    required this.price,
    this.lastUpdated,
    this.source,
    this.isRealData = true,
    this.precisePriceUsd,
    this.marketCap,
    this.volume,
  });

  factory ChartDataPoint.fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      // Legacy format: [timestamp, price]
      return ChartDataPoint(
        timestamp: (json[0] as num).toInt(),
        price: (json[1] as num).toDouble(),
        isRealData: true,
      );
    } else if (json is Map<String, dynamic>) {
      // Enhanced format with metadata
      return ChartDataPoint(
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: json['lastUpdated'] != null 
            ? DateTime.tryParse(json['lastUpdated'].toString())
            : null,
        source: json['source']?.toString(),
        isRealData: json['isRealData'] as bool? ?? true,
        precisePriceUsd: (json['precisePriceUsd'] as num?)?.toDouble(),
        marketCap: (json['marketCap'] as num?)?.toDouble(),
        volume: (json['volume'] as num?)?.toDouble(),
      );
    }
    throw ArgumentError('Invalid ChartDataPoint JSON format');
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'price': price,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
      if (source != null) 'source': source,
      'isRealData': isRealData,
      if (precisePriceUsd != null) 'precisePriceUsd': precisePriceUsd,
      if (marketCap != null) 'marketCap': marketCap,
      if (volume != null) 'volume': volume,
    };
  }

  List<dynamic> toList() {
    return [timestamp, price];
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  String get formattedDate {
    final date = dateTime;
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    final date = dateTime;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    final date = dateTime;
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Returns age of data if lastUpdated is available
  String? get dataAge {
    if (lastUpdated == null) return null;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  /// Returns true if data is considered fresh (less than 5 minutes old)
  bool get isFresh {
    if (lastUpdated == null) return isRealData;
    return DateTime.now().difference(lastUpdated!).inMinutes < 5;
  }

  @override
  String toString() {
    return 'ChartDataPoint{timestamp: $timestamp, price: $price, isRealData: $isRealData, source: $source, lastUpdated: $lastUpdated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataPoint &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          price == other.price &&
          isRealData == other.isRealData &&
          source == other.source;

  @override
  int get hashCode => timestamp.hashCode ^ price.hashCode ^ isRealData.hashCode ^ source.hashCode;
}
