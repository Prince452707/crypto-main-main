import 'package:flutter/material.dart';
import '../providers/portfolio_provider.dart';

class PortfolioList extends StatelessWidget {
  final PortfolioProvider provider;

  const PortfolioList({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Holdings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.items.length} assets',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text('Asset', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('Buy Price', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('Current Price', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('Value', style: TextStyle(fontWeight: FontWeight.w600))),
                  const Expanded(flex: 2, child: Text('P&L', style: TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 48), // Actions column
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Portfolio items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _buildPortfolioItem(context, item, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(BuildContext context, PortfolioItem item, int index) {
    final isProfit = item.profit >= 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Asset
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.currency_bitcoin,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.symbol.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(item.amount),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Buy Price
          Expanded(
            flex: 2,
            child: Text(
              '\$${_formatPrice(item.buyPrice)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Current Price
          Expanded(
            flex: 2,
            child: Text(
              '\$${_formatPrice(item.currentPrice ?? item.buyPrice)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Value
          Expanded(
            flex: 2,
            child: Text(
              '\$${_formatPrice(item.totalValue)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          
          // P&L
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${_formatPrice(item.profit)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  '${item.profitPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _editItem(context, item, index);
                  break;
                case 'delete':
                  _deleteItem(context, index);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount >= 1) {
      return amount.toStringAsFixed(2);
    } else {
      return amount.toStringAsFixed(6);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(2)}K';
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }

  void _editItem(BuildContext context, PortfolioItem item, int index) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _deleteItem(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to remove this asset from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeItem(index);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
