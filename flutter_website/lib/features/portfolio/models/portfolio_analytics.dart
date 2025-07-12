class PortfolioAnalytics {
  final double totalValue;
  final double totalCost;
  final double totalProfit;
  final double totalProfitPercentage;
  final double dayChange;
  final double dayChangePercentage;
  final double weekChange;
  final double weekChangePercentage;
  final double monthChange;
  final double monthChangePercentage;
  final double allTimeHigh;
  final double allTimeLow;
  final DateTime? allTimeHighDate;
  final DateTime? allTimeLowDate;
  final double sharpeRatio;
  final double volatility;
  final double maxDrawdown;
  final List<PortfolioAssetAllocation> assetAllocation;
  final Map<String, double> sectorAllocation;
  final Map<String, double> performanceMetrics;

  const PortfolioAnalytics({
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalProfitPercentage,
    required this.dayChange,
    required this.dayChangePercentage,
    required this.weekChange,
    required this.weekChangePercentage,
    required this.monthChange,
    required this.monthChangePercentage,
    required this.allTimeHigh,
    required this.allTimeLow,
    this.allTimeHighDate,
    this.allTimeLowDate,
    required this.sharpeRatio,
    required this.volatility,
    required this.maxDrawdown,
    required this.assetAllocation,
    required this.sectorAllocation,
    required this.performanceMetrics,
  });

  factory PortfolioAnalytics.fromJson(Map<String, dynamic> json) {
    return PortfolioAnalytics(
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      totalProfit: (json['totalProfit'] as num).toDouble(),
      totalProfitPercentage: (json['totalProfitPercentage'] as num).toDouble(),
      dayChange: (json['dayChange'] as num).toDouble(),
      dayChangePercentage: (json['dayChangePercentage'] as num).toDouble(),
      weekChange: (json['weekChange'] as num).toDouble(),
      weekChangePercentage: (json['weekChangePercentage'] as num).toDouble(),
      monthChange: (json['monthChange'] as num).toDouble(),
      monthChangePercentage: (json['monthChangePercentage'] as num).toDouble(),
      allTimeHigh: (json['allTimeHigh'] as num).toDouble(),
      allTimeLow: (json['allTimeLow'] as num).toDouble(),
      allTimeHighDate: json['allTimeHighDate'] != null ? DateTime.parse(json['allTimeHighDate']) : null,
      allTimeLowDate: json['allTimeLowDate'] != null ? DateTime.parse(json['allTimeLowDate']) : null,
      sharpeRatio: (json['sharpeRatio'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
      assetAllocation: (json['assetAllocation'] as List)
          .map((item) => PortfolioAssetAllocation.fromJson(item))
          .toList(),
      sectorAllocation: Map<String, double>.from(json['sectorAllocation']),
      performanceMetrics: Map<String, double>.from(json['performanceMetrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalProfit': totalProfit,
      'totalProfitPercentage': totalProfitPercentage,
      'dayChange': dayChange,
      'dayChangePercentage': dayChangePercentage,
      'weekChange': weekChange,
      'weekChangePercentage': weekChangePercentage,
      'monthChange': monthChange,
      'monthChangePercentage': monthChangePercentage,
      'allTimeHigh': allTimeHigh,
      'allTimeLow': allTimeLow,
      'allTimeHighDate': allTimeHighDate?.toIso8601String(),
      'allTimeLowDate': allTimeLowDate?.toIso8601String(),
      'sharpeRatio': sharpeRatio,
      'volatility': volatility,
      'maxDrawdown': maxDrawdown,
      'assetAllocation': assetAllocation.map((item) => item.toJson()).toList(),
      'sectorAllocation': sectorAllocation,
      'performanceMetrics': performanceMetrics,
    };
  }
}

class PortfolioAssetAllocation {
  final String symbol;
  final String name;
  final double value;
  final double percentage;
  final double profit;
  final double profitPercentage;

  const PortfolioAssetAllocation({
    required this.symbol,
    required this.name,
    required this.value,
    required this.percentage,
    required this.profit,
    required this.profitPercentage,
  });

  factory PortfolioAssetAllocation.fromJson(Map<String, dynamic> json) {
    return PortfolioAssetAllocation(
      symbol: json['symbol'],
      name: json['name'],
      value: (json['value'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'value': value,
      'percentage': percentage,
      'profit': profit,
      'profitPercentage': profitPercentage,
    };
  }
}

class PortfolioPerformanceHistory {
  final DateTime date;
  final double value;
  final double change;
  final double changePercentage;

  const PortfolioPerformanceHistory({
    required this.date,
    required this.value,
    required this.change,
    required this.changePercentage,
  });

  factory PortfolioPerformanceHistory.fromJson(Map<String, dynamic> json) {
    return PortfolioPerformanceHistory(
      date: DateTime.parse(json['date']),
      value: (json['value'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'change': change,
      'changePercentage': changePercentage,
    };
  }
}
