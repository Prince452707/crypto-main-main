import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/cryptocurrency.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/widgets/error_widget.dart';

class OverviewTab extends StatefulWidget {
  final String symbol;
  final String cryptoId;

  const OverviewTab({
    Key? key,
    required this.symbol,
    required this.cryptoId,
  }) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Cryptocurrency? _cryptoData;
  bool _isLoading = true;
  String? _error;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _apiService.getCryptocurrency(widget.symbol);
      
      if (mounted) {
        setState(() {
          _cryptoData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingSpinner());
    }

    if (_error != null) {
      return Center(
        child: ErrorDisplayWidget(
          error: _error!,
          onRetry: _loadData,
        ),
      );
    }

    if (_cryptoData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildBasicInfoCard(),
          const SizedBox(height: 16),
          
          // Market Stats Card
          _buildMarketStatsCard(),
          const SizedBox(height: 16),
          
          // Supply Information Card
          _buildSupplyInfoCard(),
          const SizedBox(height: 16),
          
          // Price Performance Card
          _buildPricePerformanceCard(),
          const SizedBox(height: 16),
          
          // Description Card
          if (_cryptoData!.description != null && _cryptoData!.description!.isNotEmpty)
            _buildDescriptionCard(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_cryptoData!.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      _cryptoData!.imageUrl!,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              _cryptoData!.symbol.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cryptoData!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cryptoData!.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cryptoData!.rank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rank #${_cryptoData!.rank}',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Price',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _cryptoData!.formattedPrice,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '24h Change',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cryptoData!.isPriceUp 
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _cryptoData!.formattedPercentChange24h,
                    style: TextStyle(
                      color: _cryptoData!.isPriceUp 
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketStatsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Market Cap', _cryptoData!.formattedMarketCap),
            _buildStatRow('Volume (24h)', _cryptoData!.formattedVolume24h),
            if (_cryptoData!.high24h != null)
              _buildStatRow('24h High', '\$${_cryptoData!.high24h!.toStringAsFixed(2)}'),
            if (_cryptoData!.low24h != null)
              _buildStatRow('24h Low', '\$${_cryptoData!.low24h!.toStringAsFixed(2)}'),
            if (_cryptoData!.allTimeHigh != null)
              _buildStatRow('All Time High', '\$${_cryptoData!.allTimeHigh!.toStringAsFixed(2)}'),
            if (_cryptoData!.allTimeLow != null)
              _buildStatRow('All Time Low', '\$${_cryptoData!.allTimeLow!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supply Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_cryptoData!.circulatingSupply != null)
              _buildStatRow('Circulating Supply', _formatSupply(_cryptoData!.circulatingSupply!)),
            if (_cryptoData!.totalSupply != null)
              _buildStatRow('Total Supply', _formatSupply(_cryptoData!.totalSupply!)),
            if (_cryptoData!.maxSupply != null)
              _buildStatRow('Max Supply', _formatSupply(_cryptoData!.maxSupply!)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricePerformanceCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_cryptoData!.percentChange24h != null)
              _buildPerformanceRow('24h Change', _cryptoData!.percentChange24h!, AppTheme.warningOrange),
            if (_cryptoData!.percentChange7d != null)
              _buildPerformanceRow('7d Change', _cryptoData!.percentChange7d!, AppTheme.secondaryBlue),
            if (_cryptoData!.percentChange30d != null)
              _buildPerformanceRow('30d Change', _cryptoData!.percentChange30d!, AppTheme.accentGold),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About ${_cryptoData!.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _cryptoData!.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSupply(double supply) {
    if (supply >= 1e12) {
      return '${(supply / 1e12).toStringAsFixed(2)}T';
    } else if (supply >= 1e9) {
      return '${(supply / 1e9).toStringAsFixed(2)}B';
    } else if (supply >= 1e6) {
      return '${(supply / 1e6).toStringAsFixed(2)}M';
    } else if (supply >= 1e3) {
      return '${(supply / 1e3).toStringAsFixed(2)}K';
    } else {
      return supply.toStringAsFixed(0);
    }
  }
}
