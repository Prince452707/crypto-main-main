class TradingSignal {
  final String id;
  final String symbol;
  final SignalType type;
  final double entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final double confidence;
  final String description;
  final DateTime createdAt;
  final SignalStatus status;
  final List<String> indicators;
  final String timeframe;

  const TradingSignal({
    required this.id,
    required this.symbol,
    required this.type,
    required this.entryPrice,
    this.targetPrice,
    this.stopLoss,
    required this.confidence,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.indicators,
    required this.timeframe,
  });

  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    return TradingSignal(
      id: json['id'],
      symbol: json['symbol'],
      type: SignalType.values.firstWhere((e) => e.name == json['type']),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      targetPrice: json['targetPrice'] != null ? (json['targetPrice'] as num).toDouble() : null,
      stopLoss: json['stopLoss'] != null ? (json['stopLoss'] as num).toDouble() : null,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      status: SignalStatus.values.firstWhere((e) => e.name == json['status']),
      indicators: List<String>.from(json['indicators'] ?? []),
      timeframe: json['timeframe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.name,
      'entryPrice': entryPrice,
      'targetPrice': targetPrice,
      'stopLoss': stopLoss,
      'confidence': confidence,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'indicators': indicators,
      'timeframe': timeframe,
    };
  }
}

enum SignalType {
  buy,
  sell,
  hold,
  strongBuy,
  strongSell,
}

enum SignalStatus {
  active,
  executed,
  expired,
  cancelled,
}

extension SignalTypeExtension on SignalType {
  String get displayName {
    switch (this) {
      case SignalType.buy:
        return 'BUY';
      case SignalType.sell:
        return 'SELL';
      case SignalType.hold:
        return 'HOLD';
      case SignalType.strongBuy:
        return 'STRONG BUY';
      case SignalType.strongSell:
        return 'STRONG SELL';
    }
  }

  bool get isBuySignal => this == SignalType.buy || this == SignalType.strongBuy;
  bool get isSellSignal => this == SignalType.sell || this == SignalType.strongSell;
}

class TechnicalIndicator {
  final String name;
  final double value;
  final String signal;
  final String description;
  final DateTime calculatedAt;

  const TechnicalIndicator({
    required this.name,
    required this.value,
    required this.signal,
    required this.description,
    required this.calculatedAt,
  });

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      name: json['name'],
      value: (json['value'] as num).toDouble(),
      signal: json['signal'],
      description: json['description'],
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'signal': signal,
      'description': description,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

class TradingStrategy {
  final String id;
  final String name;
  final String description;
  final List<String> indicators;
  final Map<String, dynamic> parameters;
  final double riskLevel;
  final String timeframe;
  final bool isActive;

  const TradingStrategy({
    required this.id,
    required this.name,
    required this.description,
    required this.indicators,
    required this.parameters,
    required this.riskLevel,
    required this.timeframe,
    required this.isActive,
  });

  factory TradingStrategy.fromJson(Map<String, dynamic> json) {
    return TradingStrategy(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      indicators: List<String>.from(json['indicators'] ?? []),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      riskLevel: (json['riskLevel'] as num).toDouble(),
      timeframe: json['timeframe'],
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'indicators': indicators,
      'parameters': parameters,
      'riskLevel': riskLevel,
      'timeframe': timeframe,
      'isActive': isActive,
    };
  }
}
