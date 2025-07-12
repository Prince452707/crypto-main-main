import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../providers/crypto_provider.dart';
import '../widgets/market_overview_card.dart';
import '../widgets/trending_cryptos_card.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/top_movers_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CryptoProvider>().loadMarketData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<CryptoProvider>().refresh(force: true),
        child: Consumer<CryptoProvider>(
          builder: (context, cryptoProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with real-time status
                  _buildHeader(cryptoProvider),
                  const SizedBox(height: 24),
                  
                  // Quick Stats Grid
                  QuickStatsGrid(
                    marketData: cryptoProvider.marketData,
                    isLoading: cryptoProvider.isLoading,
                  ),
                  const SizedBox(height: 24),
              
              // Market Overview and Trending
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    // Stack vertically on smaller screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MarketOverviewCard(),
                        const SizedBox(height: 24),
                        const TrendingCryptosCard(),
                      ],
                    );
                  } else {
                    // Side by side on larger screens
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: MarketOverviewCard(),
                        ),
                        const SizedBox(width: 24),
                        const Expanded(
                          child: TrendingCryptosCard(),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Top Movers
              const TopMoversCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(CryptoProvider cryptoProvider) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _buildRealTimeIndicator(cryptoProvider),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s your crypto market overview.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _buildSystemStatus(cryptoProvider),
          ],
        ),
        const Spacer(),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildRealTimeIndicator(CryptoProvider cryptoProvider) {
    final realTimeService = cryptoProvider.realTimeService;
    final isHealthy = realTimeService.isHealthy;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isHealthy ? 'Real-time' : 'Limited',
            style: TextStyle(
              fontSize: 12,
              color: isHealthy ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(CryptoProvider cryptoProvider) {
    final realTimeService = cryptoProvider.realTimeService;
    final systemStatus = realTimeService.systemStatus;
    
    if (systemStatus.isEmpty) return const SizedBox.shrink();
    
    return Text(
      'Last update: ${_formatSystemTime(systemStatus)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }

  String _formatSystemTime(Map<String, dynamic> status) {
    if (status['lastRefresh'] != null) {
      try {
        final lastRefresh = DateTime.parse(status['lastRefresh']);
        final now = DateTime.now();
        final difference = now.difference(lastRefresh);
        
        if (difference.inMinutes < 1) return 'Just now';
        if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
        if (difference.inHours < 24) return '${difference.inHours}h ago';
        return '${difference.inDays}d ago';
      } catch (e) {
        return 'Unknown';
      }
    }
    return 'Unknown';
  }

  Widget _buildQuickActions() {
    return Consumer<CryptoProvider>(
      builder: (context, cryptoProvider, child) {
        return Row(
          children: [
            _buildActionButton(
              icon: FontAwesomeIcons.chartLine,
              label: 'Markets',
              onTap: () => context.go('/markets'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: FontAwesomeIcons.chartPie,
              label: 'Analysis',
              onTap: () => context.go('/analysis'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: FontAwesomeIcons.briefcase,
              label: 'Portfolio',
              onTap: () => context.go('/portfolio'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: FontAwesomeIcons.arrowsRotate,
              label: 'Refresh',
              onTap: () => cryptoProvider.refresh(force: true),
              isLoading: cryptoProvider.isLoading,
            ),
            const SizedBox(width: 12),
            _buildRealTimeToggle(cryptoProvider),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              FaIcon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeToggle(CryptoProvider cryptoProvider) {
    return Tooltip(
      message: cryptoProvider.realTimeEnabled 
          ? 'Disable real-time updates' 
          : 'Enable real-time updates',
      child: InkWell(
        onTap: () => cryptoProvider.toggleRealTimeMode(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cryptoProvider.realTimeEnabled
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cryptoProvider.realTimeEnabled
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: FaIcon(
            cryptoProvider.realTimeEnabled 
                ? FontAwesomeIcons.satellite
                : FontAwesomeIcons.satelliteDish,
            size: 16,
            color: cryptoProvider.realTimeEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
