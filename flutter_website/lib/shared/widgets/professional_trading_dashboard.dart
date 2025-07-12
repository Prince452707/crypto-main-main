import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analysis/providers/analysis_provider.dart';

class ProfessionalTradingDashboard extends StatefulWidget {
  const ProfessionalTradingDashboard({super.key});

  @override
  State<ProfessionalTradingDashboard> createState() => _ProfessionalTradingDashboardState();
}

class _ProfessionalTradingDashboardState extends State<ProfessionalTradingDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyzeSymbol('bitcoin');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopMetricsBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTechnicalAnalysisTab(),
                _buildOnChainTab(),
                _buildSentimentTab(),
                _buildRiskAnalysisTab(),
                _buildForecastTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D1421),
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.trending_up, color: Color(0xFF00D4AA), size: 28),
          const SizedBox(width: 12),
          const Text(
            'Professional Trading Suite',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Consumer<AnalysisProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRecommendationColor(provider.investmentRecommendation),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  provider.investmentRecommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricsBar() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 80,
          color: const Color(0xFF1A1A2E),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTopMetricItem(
                'Fear & Greed',
                '${provider.fearGreedIndex?.toInt() ?? 0}',
                _getFearGreedColor(provider.fearGreedIndex ?? 50),
                Icons.psychology,
              ),
              _buildTopMetricItem(
                'Risk Level',
                provider.riskAssessment,
                _getRiskColor(provider.riskAssessment),
                Icons.warning,
              ),
              _buildTopMetricItem(
                'Volatility',
                '${((provider.volatilityData['volatility'] as double? ?? 0) * 100).toStringAsFixed(1)}%',
                _getVolatilityColor(provider.volatilityData['volatility'] as double? ?? 0),
                Icons.show_chart,
              ),
              _buildTopMetricItem(
                'Liquidity Score',
                '${(provider.liquidityMetrics['liquidity_score'] as double? ?? 0).toStringAsFixed(1)}/10',
                _getLiquidityColor(provider.liquidityMetrics['liquidity_score'] as double? ?? 0),
                Icons.water_drop,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMetricItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A92B2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF16213E),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF00D4AA),
        labelColor: const Color(0xFF00D4AA),
        unselectedLabelColor: const Color(0xFF8A92B2),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Technical'),
          Tab(text: 'On-Chain'),
          Tab(text: 'Sentiment'),
          Tab(text: 'Risk'),
          Tab(text: 'Forecast'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSignalsCard(provider),
              const SizedBox(height: 16),
              _buildKeyMetricsCard(provider),
              const SizedBox(height: 16),
              _buildMarketComparisonCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechnicalAnalysisTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTechnicalIndicatorsCard(provider),
              const SizedBox(height: 16),
              _buildAdvancedIndicatorsCard(provider),
              const SizedBox(height: 16),
              _buildVolumeAnalysisCard(provider),
              const SizedBox(height: 16),
              _buildFibonacciCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnChainTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOnChainMetricsCard(provider),
              const SizedBox(height: 16),
              _buildWhaleActivityCard(provider),
              const SizedBox(height: 16),
              _buildExchangeFlowCard(provider),
              const SizedBox(height: 16),
              _buildDevelopmentCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentimentTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMarketSentimentCard(provider),
              const SizedBox(height: 16),
              _buildSocialMetricsCard(provider),
              const SizedBox(height: 16),
              _buildFearGreedCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskAnalysisTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRiskMetricsCard(provider),
              const SizedBox(height: 16),
              _buildVolatilityCard(provider),
              const SizedBox(height: 16),
              _buildLiquidityCard(provider),
              const SizedBox(height: 16),
              _buildRiskWarningsCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForecastTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPriceForecastCard(provider),
              const SizedBox(height: 16),
              _buildAnalyticalInsightsCard(provider),
              const SizedBox(height: 16),
              _buildKeyEventsCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignalsCard(AnalysisProvider provider) {
    return _buildCard(
      'Trading Signals',
      Icons.signal_cellular_alt,
      Column(
        children: provider.signals.entries.map((entry) {
          final color = _getSignalColor(entry.value);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: Color(0xFF8A92B2)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyMetricsCard(AnalysisProvider provider) {
    return _buildCard(
      'Key Metrics',
      Icons.analytics,
      Column(
        children: [
          _buildMetricRow('Support Levels', provider.supportLevels.take(3).join(', ')),
          _buildMetricRow('Resistance Levels', provider.resistanceLevels.take(3).join(', ')),
          _buildMetricRow('Beta', provider.riskMetrics['beta']?.toStringAsFixed(2) ?? 'N/A'),
          _buildMetricRow('Sharpe Ratio', provider.riskMetrics['sharpe_ratio']?.toStringAsFixed(2) ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildMarketComparisonCard(AnalysisProvider provider) {
    return _buildCard(
      'Market Comparison',
      Icons.compare_arrows,
      Column(
        children: [
          _buildMetricRow('Market Cap Rank', '#${provider.marketComparison['market_cap_rank'] ?? 'N/A'}'),
          _buildMetricRow('Volume Rank', '#${provider.marketComparison['volume_rank'] ?? 'N/A'}'),
          _buildMetricRow('24h Performance Rank', '#${provider.marketComparison['performance_rank_24h'] ?? 'N/A'}'),
          _buildMetricRow('Volatility Rank', '#${provider.marketComparison['volatility_rank'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicatorsCard(AnalysisProvider provider) {
    return _buildCard(
      'Technical Indicators',
      Icons.trending_up,
      Column(
        children: provider.technicalIndicators.entries.map((entry) {
          return _buildMetricRow(entry.key, entry.value.toStringAsFixed(2));
        }).toList(),
      ),
    );
  }

  Widget _buildAdvancedIndicatorsCard(AnalysisProvider provider) {
    return _buildCard(
      'Advanced Indicators',
      Icons.insights,
      Column(
        children: provider.advancedIndicators.entries.map((entry) {
          if (entry.value is Map) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...(entry.value as Map).entries.map((subEntry) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildMetricRow(subEntry.key, subEntry.value.toStringAsFixed(2)),
                  ),
                ),
              ],
            );
          }
          return _buildMetricRow(entry.key, entry.value.toStringAsFixed(2));
        }).toList(),
      ),
    );
  }

  Widget _buildVolumeAnalysisCard(AnalysisProvider provider) {
    return _buildCard(
      'Volume Analysis',
      Icons.bar_chart,
      Column(
        children: provider.volumeIndicators.entries.map((entry) {
          return _buildMetricRow(entry.key, _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildFibonacciCard(AnalysisProvider provider) {
    final fibs = provider.fibonacciLevels;
    return _buildCard(
      'Fibonacci Levels',
      Icons.timeline,
      Column(
        children: [
          if (fibs['support_levels'] != null) ...[
            const Text(
              'Support Levels',
              style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold),
            ),
            ...(fibs['support_levels'] as List).map((level) =>
              _buildMetricRow('Support', _formatNumber(level)),
            ),
          ],
          if (fibs['resistance_levels'] != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Resistance Levels',
              style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
            ),
            ...(fibs['resistance_levels'] as List).map((level) =>
              _buildMetricRow('Resistance', _formatNumber(level)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnChainMetricsCard(AnalysisProvider provider) {
    return _buildCard(
      'On-Chain Metrics',
      Icons.link,
      Column(
        children: provider.onChainMetrics.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildWhaleActivityCard(AnalysisProvider provider) {
    return _buildCard(
      'Whale Activity',
      Icons.waves,
      Column(
        children: provider.whaleActivity.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildExchangeFlowCard(AnalysisProvider provider) {
    return _buildCard(
      'Exchange Flow',
      Icons.swap_horiz,
      Column(
        children: provider.exchangeFlow.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildDevelopmentCard(AnalysisProvider provider) {
    return _buildCard(
      'Development Activity',
      Icons.code,
      Column(
        children: provider.developmentMetrics.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildMarketSentimentCard(AnalysisProvider provider) {
    return _buildCard(
      'Market Sentiment',
      Icons.mood,
      Column(
        children: provider.marketSentiment.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildSocialMetricsCard(AnalysisProvider provider) {
    return _buildCard(
      'Social Metrics',
      Icons.group,
      Column(
        children: provider.socialMetrics.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildFearGreedCard(AnalysisProvider provider) {
    final fearGreed = provider.fearGreedIndex ?? 50;
    return _buildCard(
      'Fear & Greed Index',
      Icons.psychology,
      Column(
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: fearGreed / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getFearGreedColor(fearGreed),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fearGreed.toInt().toString(),
                          style: TextStyle(
                            color: _getFearGreedColor(fearGreed),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getFearGreedLabel(fearGreed),
                          style: const TextStyle(
                            color: Color(0xFF8A92B2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsCard(AnalysisProvider provider) {
    return _buildCard(
      'Risk Metrics',
      Icons.warning,
      Column(
        children: provider.riskMetrics.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value.toStringAsFixed(2));
        }).toList(),
      ),
    );
  }

  Widget _buildVolatilityCard(AnalysisProvider provider) {
    return _buildCard(
      'Volatility Analysis',
      Icons.show_chart,
      Column(
        children: provider.volatilityData.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), '${(entry.value * 100).toStringAsFixed(1)}%');
        }).toList(),
      ),
    );
  }

  Widget _buildLiquidityCard(AnalysisProvider provider) {
    return _buildCard(
      'Liquidity Analysis',
      Icons.water_drop,
      Column(
        children: provider.liquidityMetrics.entries.map((entry) {
          return _buildMetricRow(entry.key.replaceAll('_', ' ').toUpperCase(), _formatNumber(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildRiskWarningsCard(AnalysisProvider provider) {
    final warnings = provider.riskWarnings.entries.where((entry) => entry.value == true).toList();
    
    return _buildCard(
      'Risk Warnings',
      Icons.error,
      warnings.isEmpty
          ? const Text(
              'No active risk warnings',
              style: TextStyle(color: Color(0xFF00D4AA)),
            )
          : Column(
              children: warnings.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFFF6B6B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPriceForecastCard(AnalysisProvider provider) {
    return _buildCard(
      'Price Forecasts',
      Icons.trending_up,
      Column(
        children: provider.priceForecasts.entries.map((entry) {
          final forecast = entry.value as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildMetricRow('Price', '\$${_formatNumber(forecast['price'])}'),
                _buildMetricRow('Confidence', '${forecast['confidence']}%'),
                _buildMetricRow('Direction', forecast['direction'].toString().toUpperCase()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalyticalInsightsCard(AnalysisProvider provider) {
    return _buildCard(
      'Analytical Insights',
      Icons.lightbulb,
      Column(
        children: provider.analyticalInsights.map((insight) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF00D4AA), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(color: Color(0xFF8A92B2)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyEventsCard(AnalysisProvider provider) {
    return _buildCard(
      'Key Events',
      Icons.event,
      Column(
        children: provider.keyEvents.map((event) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFF00D4AA), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event,
                    style: const TextStyle(color: Color(0xFF8A92B2)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16213E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4AA), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A92B2), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) {
      if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
      if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
      if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
      if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'STRONG BUY':
        return const Color(0xFF00D4AA);
      case 'BUY':
        return const Color(0xFF4ECDC4);
      case 'HOLD':
        return const Color(0xFF8A92B2);
      case 'SELL':
        return const Color(0xFFFF6B6B);
      case 'STRONG SELL':
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFF8A92B2);
    }
  }

  Color _getSignalColor(String signal) {
    if (signal.contains('BUY')) return const Color(0xFF00D4AA);
    if (signal.contains('SELL')) return const Color(0xFFFF6B6B);
    return const Color(0xFF8A92B2);
  }

  Color _getFearGreedColor(double value) {
    if (value > 75) return const Color(0xFFFF4757);
    if (value > 55) return const Color(0xFFFF6B6B);
    if (value > 45) return const Color(0xFF8A92B2);
    if (value > 25) return const Color(0xFF4ECDC4);
    return const Color(0xFF00D4AA);
  }

  String _getFearGreedLabel(double value) {
    if (value > 75) return 'Extreme Greed';
    if (value > 55) return 'Greed';
    if (value > 45) return 'Neutral';
    if (value > 25) return 'Fear';
    return 'Extreme Fear';
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'HIGH RISK':
        return const Color(0xFFFF4757);
      case 'MEDIUM RISK':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF00D4AA);
    }
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility > 0.8) return const Color(0xFFFF4757);
    if (volatility > 0.5) return const Color(0xFFFF6B6B);
    return const Color(0xFF00D4AA);
  }

  Color _getLiquidityColor(double score) {
    if (score < 4) return const Color(0xFFFF4757);
    if (score < 7) return const Color(0xFFFF6B6B);
    return const Color(0xFF00D4AA);
  }
}
