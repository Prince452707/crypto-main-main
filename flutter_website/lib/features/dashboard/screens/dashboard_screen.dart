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
        onRefresh: () => context.read<CryptoProvider>().refresh(),
        child: Consumer<CryptoProvider>(
          builder: (context, cryptoProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Quick Stats Grid
                  QuickStatsGrid(
                    marketData: cryptoProvider.marketData,
                    isLoading: cryptoProvider.isLoading,
                  ),
                  const SizedBox(height: 24),
              
              // Market Overview and Trending
              Row(
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

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s your crypto market overview.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
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
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
}
