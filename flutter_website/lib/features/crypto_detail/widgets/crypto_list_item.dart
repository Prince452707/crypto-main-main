import 'package:flutter/material.dart';
import '../../../core/models/cryptocurrency.dart';

class CryptoListItem extends StatelessWidget {
  final Cryptocurrency crypto;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showRank;

  const CryptoListItem({
    super.key,
    required this.crypto,
    this.onTap,
    this.trailing,
    this.showRank = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: _buildLeading(context),
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context),
        trailing: trailing ?? _buildTrailing(context),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showRank && crypto.rank != null)
          Text(
            '#${crypto.rank}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        const SizedBox(height: 4),
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: crypto.imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    crypto.imageUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(context),
                  ),
                )
              : _buildFallbackIcon(context),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Text(
      crypto.symbol.substring(0, crypto.symbol.length < 3 ? crypto.symbol.length : 3).toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            crypto.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          crypto.symbol.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Row(
      children: [
        if (crypto.marketCap != null) ...[
          Text(
            'MCap: ${_formatMarketCap(crypto.marketCap!)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (crypto.volume24h != null)
          Text(
            'Vol: ${_formatVolume(crypto.volume24h!)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (crypto.price != null)
          Text(
            '\$${crypto.price!.toStringAsFixed(crypto.price! < 1 ? 6 : 2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        if (crypto.percentChange24h != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: crypto.percentChange24h! >= 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${crypto.percentChange24h! >= 0 ? '+' : ''}${crypto.percentChange24h!.toStringAsFixed(2)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else if (marketCap >= 1e3) {
      return '\$${(marketCap / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${marketCap.toStringAsFixed(2)}';
    }
  }

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return '\$${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return '\$${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return '\$${(volume / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${volume.toStringAsFixed(2)}';
    }
  }
}
