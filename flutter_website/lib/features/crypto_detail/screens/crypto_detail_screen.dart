import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analysis/providers/analysis_provider.dart';
import '../../../features/analysis/widgets/analysis_chart.dart';
import '../../../features/analysis/widgets/analysis_insights.dart';
import '../../../features/analysis/widgets/timeframe_selector.dart';
import '../providers/realtime_crypto_provider.dart';
import '../widgets/realtime_status_indicator.dart';
import '../widgets/crypto_price_card.dart';
import '../widgets/auto_refresh_controls.dart';

class CryptoDetailScreen extends StatefulWidget {
  final String symbol;

  const CryptoDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late RealTimeCryptoProvider _realTimeProvider;
  String _selectedTimeframe = '7d';

  @override
  void initState() {
    super.initState();
    _realTimeProvider = RealTimeCryptoProvider();
    
    // Start real-time tracking for this symbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _realTimeProvider.startTracking(widget.symbol);
      
      // Also load analysis data
      context.read<AnalysisProvider>().analyzeSymbol(widget.symbol);
    });
  }

  @override
  void dispose() {
    _realTimeProvider.stopTracking();
    _realTimeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _realTimeProvider),
      ],
      child: Consumer2<RealTimeCryptoProvider, AnalysisProvider>(
        builder: (context, realTimeProvider, analysisProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with real-time status
                _buildHeader(context, realTimeProvider),
                const SizedBox(height: 24),

                // Real-time price card
                CryptoPriceCard(
                  crypto: realTimeProvider.currentCrypto,
                  isLoading: realTimeProvider.isLoading,
                  lastUpdate: realTimeProvider.getLastUpdateTime(),
                ),
                const SizedBox(height: 16),

                // Show fallback message if data is limited
                if (realTimeProvider.currentCrypto != null && 
                    realTimeProvider.currentCrypto!.price == 0.0)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Limited data available due to API rate limits. Real-time features may be reduced.',
                              style: TextStyle(color: Colors.amber.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (realTimeProvider.currentCrypto != null && 
                    realTimeProvider.currentCrypto!.price == 0.0)
                  const SizedBox(height: 16),

                // Auto-refresh controls
                AutoRefreshControls(
                  autoRefreshEnabled: realTimeProvider.autoRefreshEnabled,
                  refreshInterval: realTimeProvider.refreshInterval,
                  onToggleAutoRefresh: realTimeProvider.toggleAutoRefresh,
                  onIntervalChanged: realTimeProvider.setRefreshInterval,
                  onManualRefresh: realTimeProvider.forceRefresh,
                  isLoading: realTimeProvider.isLoading,
                ),
                const SizedBox(height: 24),

                // Chart section with timeframe selector
                if (realTimeProvider.chartData.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Price Chart',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TimeframeSelector(
                                selectedTimeframe: _selectedTimeframe,
                                onTimeframeChanged: (timeframe) {
                                  setState(() {
                                    _selectedTimeframe = timeframe;
                                  });
                                  realTimeProvider.updateChartTimeframe(timeframe);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnalysisChart(
                            chartData: realTimeProvider.chartData,
                            symbol: widget.symbol,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Analysis section (from existing provider)
                if (analysisProvider.currentAnalysis != null)
                  AnalysisInsights(
                    analysis: analysisProvider.currentAnalysis!,
                  ),

                // Error states
                if (realTimeProvider.error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Real-time Error: ${realTimeProvider.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              realTimeProvider.forceRefresh();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (analysisProvider.error != null)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning_outlined, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Analysis Error: ${analysisProvider.error}',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              analysisProvider.analyzeSymbol(widget.symbol);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RealTimeCryptoProvider provider) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: provider.currentCrypto?.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    provider.currentCrypto!.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.currency_bitcoin,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                )
              : Icon(
                  Icons.currency_bitcoin,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.currentCrypto?.name ?? widget.symbol.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Real-time Analysis',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        RealTimeStatusIndicator(
          connectionStatus: provider.connectionStatus,
          isDataFresh: provider.isDataFresh(),
          lastUpdate: provider.getLastUpdateTime(),
          onRefresh: () {
            provider.forceRefresh();
            provider.checkConnection();
          },
        ),
      ],
    );
  }
}
