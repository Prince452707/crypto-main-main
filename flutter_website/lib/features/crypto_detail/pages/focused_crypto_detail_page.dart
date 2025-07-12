import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/crypto_detail.dart';
import '../providers/focused_crypto_provider.dart';

class FocusedCryptoDetailPage extends StatefulWidget {
  final String cryptoId;
  
  const FocusedCryptoDetailPage({
    Key? key,
    required this.cryptoId,
  }) : super(key: key);

  @override
  State<FocusedCryptoDetailPage> createState() => _FocusedCryptoDetailPageState();
}

class _FocusedCryptoDetailPageState extends State<FocusedCryptoDetailPage> {
  late FocusedCryptoProvider _provider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    _provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
    
    // Load data if not already loaded for this crypto
    if (!_provider.isCryptoSelected(widget.cryptoId)) {
      _provider.loadFocusedCryptoData(widget.cryptoId);
    }
    
    // Update rate limit status
    _provider.updateRateLimitStatus();
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<FocusedCryptoProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isRefreshing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.refresh),
                onPressed: provider.isRefreshing ? null : () {
                  provider.refreshCurrentCrypto();
                },
                tooltip: 'Refresh Data',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
              switch (value) {
                case 'clear_cache':
                  provider.clearCurrentCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cache cleared')),
                  );
                  break;
                case 'rate_limits':
                  _showRateLimitDialog();
                  break;
                case 'force_refresh':
                  provider.loadFocusedCryptoData(widget.cryptoId, forceRefresh: true);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'force_refresh',
                child: Text('Force Refresh'),
              ),
              PopupMenuItem(
                value: 'clear_cache',
                child: Text('Clear Cache'),
              ),
              PopupMenuItem(
                value: 'rate_limits',
                child: Text('Rate Limits'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FocusedCryptoProvider>(
        builder: (context, provider, _) {
          if (!_isInitialized) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          if (provider.isLoading && provider.selectedCrypto == null) {
            return _buildLoadingState();
          }

          if (provider.selectedCrypto != null) {
            return _buildCryptoDetailView(provider.selectedCrypto!);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading cryptocurrency data...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Aggregating data from multiple sources',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FocusedCryptoProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 8),
            Text(
              provider.formattedError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.loadFocusedCryptoData(widget.cryptoId, forceRefresh: true);
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Unable to find data for this cryptocurrency',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoDetailView(CryptoDetail crypto) {
    return RefreshIndicator(
      onRefresh: () async {
        await _provider.refreshCurrentCrypto();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(crypto),
            SizedBox(height: 24),
            _buildPriceSection(crypto),
            SizedBox(height: 24),
            _buildMarketDataSection(crypto),
            SizedBox(height: 24),
            _buildSupplySection(crypto),
            SizedBox(height: 24),
            _buildAdditionalInfoSection(crypto),
            SizedBox(height: 24),
            _buildDataSourcesSection(crypto),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(CryptoDetail crypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: crypto.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        crypto.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.currency_bitcoin, size: 30);
                        },
                      ),
                    )
                  : Icon(Icons.currency_bitcoin, size: 30),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    crypto.symbol,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (crypto.marketCapRank != null) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rank #${crypto.marketCapRank}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(CryptoDetail crypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  crypto.formattedPrice,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: crypto.isPriceUp ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    crypto.formattedPriceChange,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (crypto.priceChange24h != null) ...[
              SizedBox(height: 8),
              Text(
                '${crypto.priceChange24h! >= 0 ? '+' : ''}\$${crypto.priceChange24h!.toStringAsFixed(4)} (24h)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDataSection(CryptoDetail crypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildDataRow('Market Cap', crypto.formattedMarketCap),
            _buildDataRow('Volume (24h)', crypto.formattedVolume),
            if (crypto.fullyDilutedValuation != null)
              _buildDataRow('Fully Diluted Valuation', 
                  '\$${crypto.fullyDilutedValuation!.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplySection(CryptoDetail crypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supply Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            if (crypto.circulatingSupply != null)
              _buildDataRow('Circulating Supply', 
                  '${crypto.circulatingSupply!.toStringAsFixed(0)} ${crypto.symbol}'),
            if (crypto.totalSupply != null)
              _buildDataRow('Total Supply', 
                  '${crypto.totalSupply!.toStringAsFixed(0)} ${crypto.symbol}'),
            if (crypto.maxSupply != null)
              _buildDataRow('Max Supply', 
                  '${crypto.maxSupply!.toStringAsFixed(0)} ${crypto.symbol}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(CryptoDetail crypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            if (crypto.ath != null)
              _buildDataRow('All-Time High', '\$${crypto.ath!.toStringAsFixed(2)}'),
            if (crypto.atl != null)
              _buildDataRow('All-Time Low', '\$${crypto.atl!.toStringAsFixed(2)}'),
            if (crypto.lastUpdated != null)
              _buildDataRow('Last Updated', 
                  '${crypto.lastUpdated!.toLocal().toString().split('.')[0]}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourcesSection(CryptoDetail crypto) {
    if (crypto.dataSources == null || crypto.dataSources!.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: crypto.dataSources!.map((source) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  source,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRateLimitDialog() {
    final provider = Provider.of<FocusedCryptoProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate Limit Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.rateLimitStatus != null) ...[
              Text('Current rate limiting status from backend:'),
              SizedBox(height: 8),
              Text(
                provider.rateLimitStatus!['rateLimitStatus'] ?? 'No data available',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Text('Rate limit status not available'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              provider.updateRateLimitStatus();
            },
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
