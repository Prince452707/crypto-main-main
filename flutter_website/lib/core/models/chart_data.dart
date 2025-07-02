class ChartDataPoint {
  final int timestamp;
  final double price;

  const ChartDataPoint({
    required this.timestamp,
    required this.price,
  });

  factory ChartDataPoint.fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      return ChartDataPoint(
        timestamp: (json[0] as num).toInt(),
        price: (json[1] as num).toDouble(),
      );
    } else if (json is Map<String, dynamic>) {
      return ChartDataPoint(
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
    }
    throw ArgumentError('Invalid ChartDataPoint JSON format');
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'price': price,
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

  @override
  String toString() {
    return 'ChartDataPoint{timestamp: $timestamp, price: $price}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataPoint &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          price == other.price;

  @override
  int get hashCode => timestamp.hashCode ^ price.hashCode;
}
