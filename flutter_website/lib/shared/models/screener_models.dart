class ScreenerCriteria {
  final ScreenerField field;
  final ScreenerOperator operator;
  final double value;
  final double? secondValue; // For between operator
  final String? stringValue; // For string-based criteria

  const ScreenerCriteria({
    required this.field,
    required this.operator,
    required this.value,
    this.secondValue,
    this.stringValue,
  });

  String get displayName => field.label;
  String get description => toString();

  @override
  String toString() {
    switch (operator) {
      case ScreenerOperator.between:
        return '${field.label} between ${value.toStringAsFixed(2)} and ${secondValue?.toStringAsFixed(2) ?? ''}';
      case ScreenerOperator.greaterThan:
        return '${field.label} > ${value.toStringAsFixed(2)}';
      case ScreenerOperator.lessThan:
        return '${field.label} < ${value.toStringAsFixed(2)}';
      case ScreenerOperator.equals:
        return '${field.label} = ${value.toStringAsFixed(2)}';
      case ScreenerOperator.greaterThanOrEqual:
        return '${field.label} >= ${value.toStringAsFixed(2)}';
      case ScreenerOperator.lessThanOrEqual:
        return '${field.label} <= ${value.toStringAsFixed(2)}';
      case ScreenerOperator.notEquals:
        return '${field.label} != ${value.toStringAsFixed(2)}';
    }
  }
}

class ScreenerResult {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double marketCap;
  final double volume24h;
  final double score;
  final Map<String, dynamic> data;

  const ScreenerResult({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.marketCap,
    required this.volume24h,
    required this.score,
    this.data = const {},
  });
}

enum ScreenerOperator {
  greaterThan,
  lessThan,
  equals,
  greaterThanOrEqual,
  lessThanOrEqual,
  notEquals,
  between;

  String get label {
    switch (this) {
      case ScreenerOperator.greaterThan:
        return '>';
      case ScreenerOperator.lessThan:
        return '<';
      case ScreenerOperator.equals:
        return '=';
      case ScreenerOperator.greaterThanOrEqual:
        return '>=';
      case ScreenerOperator.lessThanOrEqual:
        return '<=';
      case ScreenerOperator.notEquals:
        return '!=';
      case ScreenerOperator.between:
        return 'between';
    }
  }
}

class ScreenerField {
  final String key;
  final String label;
  final String unit;
  final bool isNumeric;

  const ScreenerField({
    required this.key,
    required this.label,
    required this.unit,
    this.isNumeric = true,
  });

  String get displayName => label;

  static const List<ScreenerField> availableFields = [
    ScreenerField(key: 'price', label: 'Price', unit: 'USD'),
    ScreenerField(key: 'change24h', label: '24h Change', unit: '%'),
    ScreenerField(key: 'change7d', label: '7d Change', unit: '%'),
    ScreenerField(key: 'marketCap', label: 'Market Cap', unit: 'USD'),
    ScreenerField(key: 'volume24h', label: '24h Volume', unit: 'USD'),
    ScreenerField(key: 'volumeChange24h', label: '24h Volume Change', unit: '%'),
    ScreenerField(key: 'circulatingSupply', label: 'Circulating Supply', unit: ''),
    ScreenerField(key: 'totalSupply', label: 'Total Supply', unit: ''),
    ScreenerField(key: 'maxSupply', label: 'Max Supply', unit: ''),
    ScreenerField(key: 'ath', label: 'All Time High', unit: 'USD'),
    ScreenerField(key: 'atl', label: 'All Time Low', unit: 'USD'),
    ScreenerField(key: 'athChangePercentage', label: 'ATH Change', unit: '%'),
    ScreenerField(key: 'atlChangePercentage', label: 'ATL Change', unit: '%'),
    ScreenerField(key: 'rsi', label: 'RSI', unit: ''),
    ScreenerField(key: 'macd', label: 'MACD', unit: ''),
    ScreenerField(key: 'ema50', label: 'EMA 50', unit: 'USD'),
    ScreenerField(key: 'ema200', label: 'EMA 200', unit: 'USD'),
    ScreenerField(key: 'sma50', label: 'SMA 50', unit: 'USD'),
    ScreenerField(key: 'sma200', label: 'SMA 200', unit: 'USD'),
    ScreenerField(key: 'volatility', label: 'Volatility', unit: '%'),
    ScreenerField(key: 'beta', label: 'Beta', unit: ''),
    ScreenerField(key: 'sharpeRatio', label: 'Sharpe Ratio', unit: ''),
    ScreenerField(key: 'sortino', label: 'Sortino Ratio', unit: ''),
    ScreenerField(key: 'socialScore', label: 'Social Score', unit: ''),
    ScreenerField(key: 'developerScore', label: 'Developer Score', unit: ''),
    ScreenerField(key: 'liquidityScore', label: 'Liquidity Score', unit: ''),
    ScreenerField(key: 'githubCommits', label: 'GitHub Commits', unit: ''),
    ScreenerField(key: 'githubStars', label: 'GitHub Stars', unit: ''),
    ScreenerField(key: 'githubForks', label: 'GitHub Forks', unit: ''),
    ScreenerField(key: 'twitterFollowers', label: 'Twitter Followers', unit: ''),
    ScreenerField(key: 'redditSubscribers', label: 'Reddit Subscribers', unit: ''),
    ScreenerField(key: 'activeAddresses', label: 'Active Addresses', unit: ''),
    ScreenerField(key: 'transactionCount', label: 'Transaction Count', unit: ''),
    ScreenerField(key: 'networkHashRate', label: 'Network Hash Rate', unit: 'H/s'),
    ScreenerField(key: 'stakingRatio', label: 'Staking Ratio', unit: '%'),
    ScreenerField(key: 'inflationRate', label: 'Inflation Rate', unit: '%'),
    ScreenerField(key: 'yield', label: 'Staking Yield', unit: '%'),
    ScreenerField(key: 'tvl', label: 'Total Value Locked', unit: 'USD'),
    ScreenerField(key: 'fdv', label: 'Fully Diluted Valuation', unit: 'USD'),
    ScreenerField(key: 'priceToSales', label: 'Price to Sales', unit: ''),
    ScreenerField(key: 'priceToBook', label: 'Price to Book', unit: ''),
    ScreenerField(key: 'peRatio', label: 'P/E Ratio', unit: ''),
    ScreenerField(key: 'pegRatio', label: 'PEG Ratio', unit: ''),
    ScreenerField(key: 'nvtRatio', label: 'NVT Ratio', unit: ''),
    ScreenerField(key: 'mvrvRatio', label: 'MVRV Ratio', unit: ''),
    ScreenerField(key: 'realizationCapRatio', label: 'Realization Cap Ratio', unit: ''),
    ScreenerField(key: 'exchangeReserveRatio', label: 'Exchange Reserve Ratio', unit: '%'),
    ScreenerField(key: 'whaleTransactionCount', label: 'Whale Transactions', unit: ''),
    ScreenerField(key: 'institutionalInflow', label: 'Institutional Inflow', unit: 'USD'),
    ScreenerField(key: 'fearGreedIndex', label: 'Fear & Greed Index', unit: ''),
    ScreenerField(key: 'dominanceIndex', label: 'Dominance Index', unit: '%'),
    ScreenerField(key: 'correlationBtc', label: 'BTC Correlation', unit: ''),
    ScreenerField(key: 'correlationEth', label: 'ETH Correlation', unit: ''),
    ScreenerField(key: 'correlationSp500', label: 'S&P 500 Correlation', unit: ''),
    ScreenerField(key: 'correlationGold', label: 'Gold Correlation', unit: ''),
    ScreenerField(key: 'fundamentalScore', label: 'Fundamental Score', unit: ''),
    ScreenerField(key: 'technicalScore', label: 'Technical Score', unit: ''),
    ScreenerField(key: 'sentimentScore', label: 'Sentiment Score', unit: ''),
    ScreenerField(key: 'momentumScore', label: 'Momentum Score', unit: ''),
    ScreenerField(key: 'qualityScore', label: 'Quality Score', unit: ''),
    ScreenerField(key: 'valueScore', label: 'Value Score', unit: ''),
    ScreenerField(key: 'growthScore', label: 'Growth Score', unit: ''),
    ScreenerField(key: 'profitabilityScore', label: 'Profitability Score', unit: ''),
    ScreenerField(key: 'financialHealthScore', label: 'Financial Health Score', unit: ''),
    ScreenerField(key: 'managementScore', label: 'Management Score', unit: ''),
    ScreenerField(key: 'esgScore', label: 'ESG Score', unit: ''),
    ScreenerField(key: 'riskScore', label: 'Risk Score', unit: ''),
    ScreenerField(key: 'liquidityRisk', label: 'Liquidity Risk', unit: ''),
    ScreenerField(key: 'counterpartyRisk', label: 'Counterparty Risk', unit: ''),
    ScreenerField(key: 'regulatoryRisk', label: 'Regulatory Risk', unit: ''),
    ScreenerField(key: 'technicalRisk', label: 'Technical Risk', unit: ''),
    ScreenerField(key: 'marketRisk', label: 'Market Risk', unit: ''),
    ScreenerField(key: 'concentrationRisk', label: 'Concentration Risk', unit: ''),
    ScreenerField(key: 'operationalRisk', label: 'Operational Risk', unit: ''),
  ];

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenerField &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
