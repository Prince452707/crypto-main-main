import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/cryptocurrency.dart';
import '../../../../core/theme/app_theme.dart';

class DetailsTab extends StatefulWidget {
  final Cryptocurrency crypto;

  const DetailsTab({
    Key? key,
    required this.crypto,
  }) : super(key: key);

  @override
  State<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$');
  final NumberFormat _percentFormatter = NumberFormat('#,##0.00');
  final NumberFormat _integerFormatter = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Detailed Information',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Basic Information
          _buildSection(
            title: '📊 Basic Information',
            children: [
              _buildDetailRow('Name', widget.crypto.name),
              _buildDetailRow('Symbol', widget.crypto.symbol.toUpperCase()),
              if (widget.crypto.price != null)
                _buildDetailRow('Current Price', _currencyFormatter.format(widget.crypto.price!)),
              if (widget.crypto.rank != null)
                _buildDetailRow('Market Cap Rank', '#${widget.crypto.rank}'),
              if (widget.crypto.totalSupply != null && widget.crypto.totalSupply! > 0)
                _buildDetailRow('Total Supply', _integerFormatter.format(widget.crypto.totalSupply!)),
              if (widget.crypto.circulatingSupply != null && widget.crypto.circulatingSupply! > 0)
                _buildDetailRow('Circulating Supply', _integerFormatter.format(widget.crypto.circulatingSupply!)),
              if (widget.crypto.maxSupply != null && widget.crypto.maxSupply! > 0)
                _buildDetailRow('Max Supply', _integerFormatter.format(widget.crypto.maxSupply!)),
            ],
          ),

          // Market Data
          _buildSection(
            title: '💹 Market Data',
            children: [
              if (widget.crypto.marketCap != null)
                _buildDetailRow('Market Cap', _currencyFormatter.format(widget.crypto.marketCap!)),
              if (widget.crypto.fullyDilutedMarketCap != null && widget.crypto.fullyDilutedMarketCap! > 0)
                _buildDetailRow('Fully Diluted Market Cap', _currencyFormatter.format(widget.crypto.fullyDilutedMarketCap!)),
              if (widget.crypto.volume24h != null && widget.crypto.volume24h! > 0)
                _buildDetailRow('24h Volume', _currencyFormatter.format(widget.crypto.volume24h!)),
              if (widget.crypto.high24h != null && widget.crypto.high24h! > 0)
                _buildDetailRow('24h High', _currencyFormatter.format(widget.crypto.high24h!)),
              if (widget.crypto.low24h != null && widget.crypto.low24h! > 0)
                _buildDetailRow('24h Low', _currencyFormatter.format(widget.crypto.low24h!)),
              if (widget.crypto.allTimeHigh != null && widget.crypto.allTimeHigh! > 0)
                _buildDetailRow('All-Time High', _currencyFormatter.format(widget.crypto.allTimeHigh!)),
              if (widget.crypto.allTimeLow != null && widget.crypto.allTimeLow! > 0)
                _buildDetailRow('All-Time Low', _currencyFormatter.format(widget.crypto.allTimeLow!)),
            ],
          ),

          // Price Changes
          _buildSection(
            title: '📈 Price Performance',
            children: [
              if (widget.crypto.percentChange24h != null)
                _buildPercentageRow('24h Change', widget.crypto.percentChange24h!),
              if (widget.crypto.percentChange7d != null)
                _buildPercentageRow('7d Change', widget.crypto.percentChange7d!),
              if (widget.crypto.percentChange30d != null)
                _buildPercentageRow('30d Change', widget.crypto.percentChange30d!),
              if (widget.crypto.percentChange1h != null)
                _buildPercentageRow('1h Change', widget.crypto.percentChange1h!),
              if (widget.crypto.athChangePercentage != null)
                _buildPercentageRow('ATH Change', widget.crypto.athChangePercentage!),
              if (widget.crypto.priceChange24h != null)
                _buildDetailRow('24h Price Change', _currencyFormatter.format(widget.crypto.priceChange24h!)),
            ],
          ),

          // Market Cap Changes (if available)
          _buildSection(
            title: '🏢 Market Cap Performance',
            children: [
              // Note: These fields don't exist in the current model, so we'll skip them
              const Text('Market cap change data not available in current model'),
            ],
          ),

          // Historical Data
          if (widget.crypto.allTimeHighDate != null || widget.crypto.allTimeLowDate != null)
            _buildSection(
              title: '📅 Historical Milestones',
              children: [
                if (widget.crypto.allTimeHighDate != null)
                  _buildDetailRow('ATH Date', widget.crypto.allTimeHighDate!),
                if (widget.crypto.allTimeLowDate != null)
                  _buildDetailRow('ATL Date', widget.crypto.allTimeLowDate!),
              ],
            ),

          // Additional Information
          _buildSection(
            title: '🔍 Additional Details',
            children: [
              if (widget.crypto.lastUpdated != null)
                _buildDetailRow('Last Updated', widget.crypto.lastUpdated!),
              _buildDetailRow('Coin ID', widget.crypto.id),
              if (widget.crypto.imageUrl != null && widget.crypto.imageUrl!.isNotEmpty)
                _buildImageRow('Logo', widget.crypto.imageUrl!),
              if (widget.crypto.description != null && widget.crypto.description!.isNotEmpty)
                _buildDetailRow('Description', widget.crypto.description!),
              if (widget.crypto.category != null && widget.crypto.category!.isNotEmpty)
                _buildDetailRow('Category', widget.crypto.category!),
            ],
          ),

          // Quick Actions
          _buildSection(
            title: '⚡ Quick Actions',
            children: [
              _buildActionButtons(),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageRow(String label, double percentage) {
    final theme = Theme.of(context);
    final isPositive = percentage >= 0;
    final color = isPositive ? AppTheme.successGreen : AppTheme.errorRed;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${_percentFormatter.format(percentage)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String imageUrl) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(widget.crypto.symbol.toUpperCase()),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Symbol'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(widget.crypto.price?.toString() ?? 'N/A'),
                icon: const Icon(Icons.attach_money),
                label: const Text('Copy Price'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _searchOnCoinGecko(widget.crypto.id),
                icon: const Icon(Icons.search),
                label: const Text('View on CoinGecko'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareDetails(),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _searchOnCoinGecko(String coinId) {
    final url = 'https://www.coingecko.com/en/coins/$coinId';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareDetails() {
    final details = '''
${widget.crypto.name} (${widget.crypto.symbol.toUpperCase()})
Current Price: ${widget.crypto.price != null ? _currencyFormatter.format(widget.crypto.price!) : 'N/A'}
Market Cap: ${widget.crypto.marketCap != null ? _currencyFormatter.format(widget.crypto.marketCap!) : 'N/A'}
24h Change: ${widget.crypto.percentChange24h != null ? '${widget.crypto.percentChange24h! >= 0 ? '+' : ''}${_percentFormatter.format(widget.crypto.percentChange24h!)}%' : 'N/A'}
Rank: ${widget.crypto.rank != null ? '#${widget.crypto.rank}' : 'N/A'}
    ''';
    
    // Note: flutter/services doesn't have Share.share, you'd need to add the share package
    // For now, we'll just copy to clipboard
    _copyToClipboard(details);
  }
}
