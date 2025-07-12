import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';

class QuickStatsGrid extends StatelessWidget {
  final List<Cryptocurrency> marketData;
  final bool isLoading;

  const QuickStatsGrid({
    super.key,
    required this.marketData,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
          double childAspectRatio = constraints.maxWidth > 800 ? 1.6 : 1.4;
          
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
            children: List.generate(4, (index) => _buildShimmerLoadingCard(context)),
          );
        },
      );
    }

    final stats = _calculateStats();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust crossAxisCount based on screen width
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        double childAspectRatio = constraints.maxWidth > 800 ? 1.6 : 1.4;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              context,
              title: 'Total Market Cap',
              value: _formatCurrency(stats['totalMarketCap'] ?? 0),
              change: '${(stats['marketCapChange'] ?? 0) >= 0 ? '+' : ''}${stats['marketCapChange']?.toStringAsFixed(1) ?? '0.0'}%',
              isPositive: (stats['marketCapChange'] ?? 0) >= 0,
              icon: Icons.public,
            ),
            _buildStatCard(
              context,
              title: '24h Volume',
              value: _formatCurrency(stats['totalVolume'] ?? 0),
              change: '${(stats['volumeChange'] ?? 0) >= 0 ? '+' : ''}${stats['volumeChange']?.toStringAsFixed(1) ?? '0.0'}%',
              isPositive: (stats['volumeChange'] ?? 0) >= 0,
              icon: Icons.swap_horiz,
            ),
            _buildStatCard(
              context,
              title: 'Bitcoin Dominance',
              value: '${stats['btcDominance']?.toStringAsFixed(1) ?? '0.0'}%',
              change: '${(stats['btcDominanceChange'] ?? 0) >= 0 ? '+' : ''}${stats['btcDominanceChange']?.toStringAsFixed(1) ?? '0.0'}%',
              isPositive: (stats['btcDominanceChange'] ?? 0) >= 0,
              icon: Icons.currency_bitcoin,
            ),
            _buildStatCard(
              context,
              title: 'Active Cryptos',
              value: marketData.length.toString(),
              change: '+${marketData.where((c) => c.percentChange24h != null && c.percentChange24h! > 0).length}',
              isPositive: true,
              icon: Icons.account_balance_wallet,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon placeholder with shimmer
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300]?.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Change badge placeholder
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300]?.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Value placeholder
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300]?.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Title placeholder
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300]?.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats() {
    if (marketData.isEmpty) {
      return {
        'totalMarketCap': 0.0,
        'totalVolume': 0.0,
        'marketCapChange': 0.0,
        'volumeChange': 0.0,
        'btcDominance': 0.0,
        'btcDominanceChange': 0.0,
      };
    }

    double totalMarketCap = 0;
    double totalVolume = 0;
    double btcMarketCap = 0;
    double avgMarketCapChange = 0;
    int validMarketCapCount = 0;

    for (var crypto in marketData) {
      if (crypto.marketCap != null) {
        totalMarketCap += crypto.marketCap!;
        validMarketCapCount++;
        
        if (crypto.symbol.toLowerCase() == 'btc') {
          btcMarketCap = crypto.marketCap!;
        }
      }
      
      if (crypto.volume24h != null) {
        totalVolume += crypto.volume24h!;
      }
      
      if (crypto.percentChange24h != null) {
        avgMarketCapChange += crypto.percentChange24h!;
      }
    }

    if (validMarketCapCount > 0) {
      avgMarketCapChange /= validMarketCapCount;
    }

    double btcDominance = totalMarketCap > 0 ? (btcMarketCap / totalMarketCap) * 100 : 0;

    return {
      'totalMarketCap': totalMarketCap,
      'totalVolume': totalVolume,
      'marketCapChange': avgMarketCapChange,
      'volumeChange': avgMarketCapChange, // Using same as market cap for simplicity
      'btcDominance': btcDominance,
      'btcDominanceChange': 0.0, // Would need historical data
    };
  }

  String _formatCurrency(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(1)}T';
    } else if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
