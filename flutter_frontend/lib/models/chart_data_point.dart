class ChartDataPoint {
  final int timestamp;
  final double price;

  ChartDataPoint({
    required this.timestamp,
    required this.price,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      timestamp: json['timestamp'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'price': price,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  String get formattedDate {
    final date = dateTime;
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedPrice {
    if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(6)}';
    }
  }
}
