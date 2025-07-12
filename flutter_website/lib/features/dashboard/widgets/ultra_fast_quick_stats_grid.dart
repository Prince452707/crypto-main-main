import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';

class UltraFastQuickStatsGrid extends StatefulWidget {
  final List<Cryptocurrency> marketData;
  final bool isLoading;

  const UltraFastQuickStatsGrid({
    super.key,
    required this.marketData,
    required this.isLoading,
  });

  @override
  State<UltraFastQuickStatsGrid> createState() => _UltraFastQuickStatsGridState();
}

class _UltraFastQuickStatsGridState extends State<UltraFastQuickStatsGrid> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Pre-calculated stats to avoid recalculation
  Map<String, double>? _cachedStats;
  List<Cryptocurrency>? _lastMarketData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (!widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(UltraFastQuickStatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only recalculate if data actually changed
    if (widget.marketData != _lastMarketData) {
      _cachedStats = null; // Clear cache
      _lastMarketData = widget.marketData;
    }
    
    if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildInstantLoadingGrid(context);
    }

    // Use cached stats for instant rendering
    final stats = _getOptimizedStats();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
          final childAspectRatio = constraints.maxWidth > 800 ? 1.6 : 1.4;
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => _buildOptimizedStatCard(context, index, stats),
          );
        },
      ),
    );
  }

  Widget _buildInstantLoadingGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth > 800 ? 1.6 : 1.4;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _buildPulseLoadingCard(context),
        );
      },
    );
  }

  Widget _buildPulseLoadingCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]?.withOpacity(value * 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]?.withOpacity(value * 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300]?.withOpacity(value * 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300]?.withOpacity(value * 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedStatCard(BuildContext context, int index, Map<String, double> stats) {
    // Pre-defined card configurations for instant rendering
    final cardConfigs = [
      _CardConfig(
        title: 'Total Market Cap',
        value: _formatCurrency(stats['totalMarketCap'] ?? 0),
        change: '${(stats['marketCapChange'] ?? 0) >= 0 ? '+' : ''}${stats['marketCapChange']?.toStringAsFixed(1) ?? '0.0'}%',
        isPositive: (stats['marketCapChange'] ?? 0) >= 0,
        icon: Icons.public,
        color: Colors.blue,
      ),
      _CardConfig(
        title: '24h Volume',
        value: _formatCurrency(stats['totalVolume'] ?? 0),
        change: '${(stats['volumeChange'] ?? 0) >= 0 ? '+' : ''}${stats['volumeChange']?.toStringAsFixed(1) ?? '0.0'}%',
        isPositive: (stats['volumeChange'] ?? 0) >= 0,
        icon: Icons.swap_horiz,
        color: Colors.orange,
      ),
      _CardConfig(
        title: 'Bitcoin Dominance',
        value: '${stats['btcDominance']?.toStringAsFixed(1) ?? '0.0'}%',
        change: '${(stats['btcDominanceChange'] ?? 0) >= 0 ? '+' : ''}${stats['btcDominanceChange']?.toStringAsFixed(1) ?? '0.0'}%',
        isPositive: (stats['btcDominanceChange'] ?? 0) >= 0,
        icon: Icons.currency_bitcoin,
        color: Colors.amber,
      ),
      _CardConfig(
        title: 'Active Cryptos',
        value: widget.marketData.length.toString(),
        change: '+${widget.marketData.where((c) => c.percentChange24h != null && c.percentChange24h! > 0).length}',
        isPositive: true,
        icon: Icons.account_balance_wallet,
        color: Colors.green,
      ),
    ];

    final config = cardConfigs[index];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.1),
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
                  color: config.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  config.icon,
                  size: 20,
                  color: config.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (config.isPositive ? Colors.green : Colors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  config.change,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: config.isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            config.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: config.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            config.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Map<String, double> _getOptimizedStats() {
    // Return cached stats if available
    if (_cachedStats != null) {
      return _cachedStats!;
    }

    // Calculate and cache stats
    _cachedStats = _calculateOptimizedStats();
    return _cachedStats!;
  }

  Map<String, double> _calculateOptimizedStats() {
    if (widget.marketData.isEmpty) {
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

    // Optimized single-pass calculation
    for (final crypto in widget.marketData) {
      if (crypto.marketCap != null) {
        final marketCap = crypto.marketCap!;
        totalMarketCap += marketCap;
        validMarketCapCount++;
        
        if (crypto.symbol.toLowerCase() == 'btc') {
          btcMarketCap = marketCap;
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

    final btcDominance = totalMarketCap > 0 ? (btcMarketCap / totalMarketCap) * 100 : 0;

    return {
      'totalMarketCap': totalMarketCap,
      'totalVolume': totalVolume,
      'marketCapChange': avgMarketCapChange,
      'volumeChange': avgMarketCapChange,
      'btcDominance': btcDominance.toDouble(),
      'btcDominanceChange': 0.0,
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

class _CardConfig {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _CardConfig({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
}
