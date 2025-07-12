class MarketScreener {
  final String name;
  final String description;
  final List<ScreenerCriteria> criteria;
  final DateTime createdAt;
  final bool isDefault;

  const MarketScreener({
    required this.name,
    required this.description,
    required this.criteria,
    required this.createdAt,
    this.isDefault = false,
  });

  factory MarketScreener.fromJson(Map<String, dynamic> json) {
    return MarketScreener(
      name: json['name'],
      description: json['description'],
      criteria: (json['criteria'] as List)
          .map((c) => ScreenerCriteria.fromJson(c))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }
}

class ScreenerCriteria {
  final String field;
  final ScreenerOperator operator;
  final dynamic value;
  final String displayName;

  const ScreenerCriteria({
    required this.field,
    required this.operator,
    required this.value,
    required this.displayName,
  });

  factory ScreenerCriteria.fromJson(Map<String, dynamic> json) {
    return ScreenerCriteria(
      field: json['field'],
      operator: ScreenerOperator.values.firstWhere((e) => e.name == json['operator']),
      value: json['value'],
      displayName: json['displayName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator.name,
      'value': value,
      'displayName': displayName,
    };
  }

  String get description {
    String operatorText;
    switch (operator) {
      case ScreenerOperator.greaterThan:
        operatorText = '>';
      case ScreenerOperator.lessThan:
        operatorText = '<';
      case ScreenerOperator.equals:
        operatorText = '=';
      case ScreenerOperator.greaterThanOrEqual:
        operatorText = '>=';
      case ScreenerOperator.lessThanOrEqual:
        operatorText = '<=';
      case ScreenerOperator.between:
        operatorText = 'between';
      case ScreenerOperator.notEquals:
        operatorText = '!=';
    }
    return '$displayName $operatorText $value';
  }
}

enum ScreenerOperator {
  greaterThan,
  lessThan,
  equals,
  greaterThanOrEqual,
  lessThanOrEqual,
  between,
  notEquals,
}

class ScreenerField {
  final String key;
  final String displayName;
  final ScreenerFieldType type;
  final String? unit;
  final double? min;
  final double? max;

  const ScreenerField({
    required this.key,
    required this.displayName,
    required this.type,
    this.unit,
    this.min,
    this.max,
  });

  static const List<ScreenerField> availableFields = [
    ScreenerField(
      key: 'price',
      displayName: 'Price',
      type: ScreenerFieldType.currency,
      unit: 'USD',
      min: 0,
    ),
    ScreenerField(
      key: 'marketCap',
      displayName: 'Market Cap',
      type: ScreenerFieldType.currency,
      unit: 'USD',
      min: 0,
    ),
    ScreenerField(
      key: 'volume24h',
      displayName: '24h Volume',
      type: ScreenerFieldType.currency,
      unit: 'USD',
      min: 0,
    ),
    ScreenerField(
      key: 'percentChange24h',
      displayName: '24h Change %',
      type: ScreenerFieldType.percentage,
      unit: '%',
      min: -100,
      max: 1000,
    ),
    ScreenerField(
      key: 'percentChange7d',
      displayName: '7d Change %',
      type: ScreenerFieldType.percentage,
      unit: '%',
      min: -100,
      max: 1000,
    ),
    ScreenerField(
      key: 'rank',
      displayName: 'Market Rank',
      type: ScreenerFieldType.number,
      min: 1,
      max: 10000,
    ),
    ScreenerField(
      key: 'rsi',
      displayName: 'RSI',
      type: ScreenerFieldType.number,
      min: 0,
      max: 100,
    ),
    ScreenerField(
      key: 'volatility',
      displayName: 'Volatility',
      type: ScreenerFieldType.percentage,
      unit: '%',
      min: 0,
      max: 200,
    ),
  ];
}

enum ScreenerFieldType {
  currency,
  percentage,
  number,
  text,
}

class ScreenerResult {
  final String symbol;
  final String name;
  final Map<String, dynamic> data;
  final double score;

  const ScreenerResult({
    required this.symbol,
    required this.name,
    required this.data,
    required this.score,
  });

  factory ScreenerResult.fromJson(Map<String, dynamic> json) {
    return ScreenerResult(
      symbol: json['symbol'],
      name: json['name'],
      data: Map<String, dynamic>.from(json['data']),
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'data': data,
      'score': score,
    };
  }
}
