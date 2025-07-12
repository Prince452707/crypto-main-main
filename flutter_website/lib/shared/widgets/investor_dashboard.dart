import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/dashboard/providers/crypto_provider.dart';
import '../../../features/portfolio/providers/portfolio_provider.dart';
import '../../../features/alerts/providers/alerts_provider.dart';
import '../../../features/watchlist/providers/watchlist_provider.dart';
import '../../../features/analysis/providers/analysis_provider.dart';

class InvestorDashboard extends StatefulWidget {
  const InvestorDashboard({super.key});

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

class _InvestorDashboardState extends State<InvestorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    context.read<CryptoProvider>().loadMarketData();
    context.read<WatchlistProvider>().refreshCurrentWatchlist();
    context.read<AlertsProvider>().loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildPortfolioOverview(),
            const SizedBox(height: 24),
            _buildActiveAlerts(),
            const SizedBox(height: 24),
            _buildWatchlist(),
            const SizedBox(height: 24),
            _buildMarketSentiment(),
            const SizedBox(height: 24),
            _buildTradingSignals(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crypto Investment Dashboard',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete trading and investment analytics',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.marketData.isEmpty) {
          return const _LoadingCard();
        }

        final totalMarketCap = provider.marketData.fold<double>(
          0, (sum, crypto) => sum + (crypto.marketCap ?? 0)
        );
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Market Cap',
                        '\$${_formatNumber(totalMarketCap)}',
                        Icons.account_balance,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Active Cryptos',
                        '${provider.marketData.length}',
                        Icons.currency_bitcoin,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioOverview() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final totalValue = provider.totalValue;
        final totalProfit = provider.totalProfit;
        final profitPercentage = provider.totalProfitPercentage;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to portfolio screen
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Value',
                        '\$${_formatNumber(totalValue)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Total P&L',
                        '${totalProfit >= 0 ? '+' : ''}\$${_formatNumber(totalProfit)}',
                        Icons.trending_up,
                        totalProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'P&L %',
                        '${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(2)}%',
                        Icons.percent,
                        profitPercentage >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveAlerts() {
    return Consumer<AlertsProvider>(
      builder: (context, provider, _) {
        final activeAlerts = provider.activeAlerts;
        final triggeredAlerts = provider.triggeredAlerts;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price Alerts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to alerts screen
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Alert'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Active Alerts',
                        '${activeAlerts.length}',
                        Icons.notifications_active,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Triggered Today',
                        '${triggeredAlerts.length}',
                        Icons.notification_important,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (triggeredAlerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recent Triggered Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...triggeredAlerts.take(3).map((alert) => 
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.trending_up,
                        color: _getAlertTypeColor(alert.type),
                      ),
                      title: Text('${alert.symbol} ${_getAlertTypeName(alert.type)}'),
                      subtitle: Text('Target: \$${alert.targetPrice}'),
                      trailing: Text(
                        '${alert.triggeredAt?.hour}:${alert.triggeredAt?.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchlist() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        final watchlist = provider.selectedWatchlist;
        final watchlistData = provider.selectedWatchlistData;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      watchlist?.name ?? 'Watchlist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to watchlist screen
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (watchlistData.isEmpty)
                  const Text('No items in watchlist')
                else
                  ...watchlistData.take(5).map((item) => 
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: item.isPositive ? Colors.green : Colors.red,
                        child: Text(
                          item.symbol.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('${item.name} (${item.symbol})'),
                      subtitle: Text('\$${_formatNumber(item.currentPrice)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.changePercent24h >= 0 ? '+' : ''}${item.changePercent24h.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: item.isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_formatNumber(item.change24h)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketSentiment() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        final fearGreedIndex = provider.fearGreedIndex ?? 50;
        final sentiment = provider.marketSentiment;
        
        String sentimentText;
        Color sentimentColor;
        
        if (fearGreedIndex > 75) {
          sentimentText = 'Extreme Greed';
          sentimentColor = Colors.red;
        } else if (fearGreedIndex > 55) {
          sentimentText = 'Greed';
          sentimentColor = Colors.orange;
        } else if (fearGreedIndex > 45) {
          sentimentText = 'Neutral';
          sentimentColor = Colors.grey;
        } else if (fearGreedIndex > 25) {
          sentimentText = 'Fear';
          sentimentColor = Colors.blue;
        } else {
          sentimentText = 'Extreme Fear';
          sentimentColor = Colors.green;
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Sentiment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Fear & Greed Index',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          CircularProgressIndicator(
                            value: fearGreedIndex / 100,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(sentimentColor),
                            strokeWidth: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fearGreedIndex.toInt().toString(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sentimentColor,
                            ),
                          ),
                          Text(
                            sentimentText,
                            style: TextStyle(color: sentimentColor),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildStatItem(
                            'Bullish',
                            '${sentiment['bullish_percentage'] ?? 0}%',
                            Icons.trending_up,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildStatItem(
                            'Bearish',
                            '${sentiment['bearish_percentage'] ?? 0}%',
                            Icons.trending_down,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradingSignals() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        final signals = provider.signals;
        final recommendation = provider.investmentRecommendation;
        
        Color recommendationColor;
        IconData recommendationIcon;
        
        switch (recommendation) {
          case 'STRONG BUY':
            recommendationColor = Colors.green.shade700;
            recommendationIcon = Icons.trending_up;
            break;
          case 'BUY':
            recommendationColor = Colors.green;
            recommendationIcon = Icons.trending_up;
            break;
          case 'HOLD':
            recommendationColor = Colors.grey;
            recommendationIcon = Icons.pause;
            break;
          case 'SELL':
            recommendationColor = Colors.red;
            recommendationIcon = Icons.trending_down;
            break;
          case 'STRONG SELL':
            recommendationColor = Colors.red.shade700;
            recommendationIcon = Icons.trending_down;
            break;
          default:
            recommendationColor = Colors.grey;
            recommendationIcon = Icons.help;
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trading Signals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: recommendationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: recommendationColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(recommendationIcon, color: recommendationColor, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Signal',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            recommendation,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: recommendationColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (signals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Technical Indicators',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...signals.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSignalColor(entry.value).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: _getSignalColor(entry.value),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getSignalColor(String signal) {
    if (signal.contains('BUY')) return Colors.green;
    if (signal.contains('SELL')) return Colors.red;
    return Colors.grey;
  }

  String _formatNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }

  Color _getAlertTypeColor(dynamic alertType) {
    final typeString = alertType.toString();
    if (typeString.contains('above') || typeString.contains('percentageGain')) {
      return Colors.green;
    }
    return Colors.red;
  }

  String _getAlertTypeName(dynamic alertType) {
    final typeString = alertType.toString().split('.').last;
    switch (typeString) {
      case 'above':
        return 'Price Above';
      case 'below':
        return 'Price Below';
      case 'percentageGain':
        return 'Percentage Gain';
      case 'percentageLoss':
        return 'Percentage Loss';
      default:
        return typeString;
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
