import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';

class CryptoPriceCard extends StatelessWidget {
  final Cryptocurrency? crypto;
  final bool isLoading;
  final DateTime? lastUpdate;

  const CryptoPriceCard({
    super.key,
    this.crypto,
    required this.isLoading,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard(context);
    }

    if (crypto == null) {
      return _buildErrorCard(context);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCryptoIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crypto!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        crypto!.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (crypto!.rank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${crypto!.rank}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Price information
            _buildPriceSection(context),
            
            const SizedBox(height: 16),
            
            // Market stats
            _buildMarketStats(context),
            
            if (lastUpdate != null) ...[
              const SizedBox(height: 12),
              _buildLastUpdateInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: crypto!.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                crypto!.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(context),
              ),
            )
          : _buildDefaultIcon(context),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
      Icons.currency_bitcoin,
      color: Theme.of(context).primaryColor,
      size: 24,
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final hasPrice = crypto!.price != null && crypto!.price! > 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          hasPrice ? '\$${crypto!.price!.toStringAsFixed(2)}' : 'Price Unavailable',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasPrice ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        if (!hasPrice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Rate Limited',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (crypto!.percentChange24h != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getChangeColor(crypto!.percentChange24h!).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  crypto!.percentChange24h! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: _getChangeColor(crypto!.percentChange24h!),
                ),
                const SizedBox(width: 4),
                Text(
                  '${crypto!.percentChange24h!.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getChangeColor(crypto!.percentChange24h!),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMarketStats(BuildContext context) {
    return Row(
      children: [
        if (crypto!.marketCap != null)
          Expanded(
            child: _buildStatItem(
              context,
              'Market Cap',
              _formatCurrency(crypto!.marketCap!),
              Icons.account_balance_wallet,
            ),
          ),
        if (crypto!.volume24h != null)
          Expanded(
            child: _buildStatItem(
              context,
              '24h Volume',
              _formatCurrency(crypto!.volume24h!),
              Icons.bar_chart,
            ),
          ),
        if (crypto!.high24h != null && crypto!.low24h != null)
          Expanded(
            child: _buildStatItem(
              context,
              '24h Range',
              '\$${crypto!.low24h!.toStringAsFixed(2)} - \$${crypto!.high24h!.toStringAsFixed(2)}',
              Icons.trending_up,
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo(BuildContext context) {
    final timeSinceUpdate = DateTime.now().difference(lastUpdate!);
    String timeText;
    
    if (timeSinceUpdate.inSeconds < 60) {
      timeText = '${timeSinceUpdate.inSeconds}s ago';
    } else if (timeSinceUpdate.inMinutes < 60) {
      timeText = '${timeSinceUpdate.inMinutes}m ago';
    } else {
      timeText = '${timeSinceUpdate.inHours}h ago';
    }
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          'Last updated $timeText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Loading real-time data...'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Failed to load cryptocurrency data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChangeColor(double change) {
    return change >= 0 ? Colors.green : Colors.red;
  }

  String _formatCurrency(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
