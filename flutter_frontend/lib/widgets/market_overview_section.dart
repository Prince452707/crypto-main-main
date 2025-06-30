import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MarketOverviewSection extends StatelessWidget {
  const MarketOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Section title
          Text(
            'Market Overview',
            style: AppTheme.headingLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Real-time insights into the cryptocurrency market',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Market stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: MediaQuery.of(context).size.width > 768 ? 2.5 : 3,
            children: [
              _buildMarketCard(
                'Total Market Cap',
                '\$2.1T',
                '+2.5%',
                Icons.account_balance_wallet,
                true,
              ),
              _buildMarketCard(
                '24h Volume',
                '\$89.2B',
                '-1.2%',
                Icons.bar_chart,
                false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Top cryptocurrencies
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassMorphism,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top Cryptocurrencies',
                      style: AppTheme.headingMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Crypto list
                _buildCryptoRow('Bitcoin', 'BTC', '\$43,250', '+2.45%', true),
                const SizedBox(height: 12),
                _buildCryptoRow('Ethereum', 'ETH', '\$2,580', '+1.85%', true),
                const SizedBox(height: 12),
                _buildCryptoRow('Cardano', 'ADA', '\$0.52', '-0.75%', false),
                const SizedBox(height: 12),
                _buildCryptoRow('Solana', 'SOL', '\$98.60', '+4.20%', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(
    String title,
    String value,
    String change,
    IconData icon,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassMorphism,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.successGreen : AppTheme.errorRed)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: AppTheme.bodySmall.copyWith(
                    color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoRow(
    String name,
    String symbol,
    String price,
    String change,
    bool isPositive,
  ) {
    return Row(
      children: [
        // Logo placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              symbol.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Name and symbol
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                symbol,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Price and change
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              change,
              style: AppTheme.bodySmall.copyWith(
                color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
