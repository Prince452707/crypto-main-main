class PriceAlert {
  final String id;
  final String symbol;
  final String coinName;
  final double targetPrice;
  final AlertType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final String? notes;

  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.coinName,
    required this.targetPrice,
    required this.type,
    required this.isActive,
    required this.createdAt,
    this.triggeredAt,
    this.notes,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      symbol: json['symbol'],
      coinName: json['coinName'],
      targetPrice: (json['targetPrice'] as num).toDouble(),
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.above,
      ),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      triggeredAt: json['triggeredAt'] != null 
          ? DateTime.parse(json['triggeredAt'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'coinName': coinName,
      'targetPrice': targetPrice,
      'type': type.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'notes': notes,
    };
  }

  PriceAlert copyWith({
    String? id,
    String? symbol,
    String? coinName,
    double? targetPrice,
    AlertType? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? triggeredAt,
    String? notes,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      coinName: coinName ?? this.coinName,
      targetPrice: targetPrice ?? this.targetPrice,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      notes: notes ?? this.notes,
    );
  }
}

enum AlertType {
  above,
  below,
  percentageGain,
  percentageLoss,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.above:
        return 'Price Above';
      case AlertType.below:
        return 'Price Below';
      case AlertType.percentageGain:
        return 'Percentage Gain';
      case AlertType.percentageLoss:
        return 'Percentage Loss';
    }
  }

  String get description {
    switch (this) {
      case AlertType.above:
        return 'Alert when price goes above target';
      case AlertType.below:
        return 'Alert when price goes below target';
      case AlertType.percentageGain:
        return 'Alert when price increases by percentage';
      case AlertType.percentageLoss:
        return 'Alert when price decreases by percentage';
    }
  }
}
