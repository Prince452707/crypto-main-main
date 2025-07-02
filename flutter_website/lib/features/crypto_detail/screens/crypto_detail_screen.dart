import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analysis/providers/analysis_provider.dart';
import '../../../features/analysis/widgets/analysis_chart.dart';
import '../../../features/analysis/widgets/analysis_insights.dart';
import '../../../features/analysis/widgets/timeframe_selector.dart';

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
  @override
  void initState() {
    super.initState();
    // Load analysis for this symbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyzeSymbol(widget.symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
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
                    child: Icon(
                      Icons.currency_bitcoin,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cryptocurrency Analysis',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TimeframeSelector(
                    selectedTimeframe: provider.selectedTimeframe,
                    onTimeframeChanged: (timeframe) {
                      provider.changeTimeframe(timeframe);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Loading state
              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading cryptocurrency data...'),
                      ],
                    ),
                  ),
                ),

              // Error state
              if (provider.error != null)
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
                            'Error: ${provider.error}',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.analyzeSymbol(widget.symbol);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content
              if (!provider.isLoading && provider.error == null && provider.currentAnalysis != null) ...[
                // Price info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoCard(
                              context,
                              'Current Price',
                              provider.chartData.isNotEmpty
                                  ? '\$${provider.chartData.last.price.toStringAsFixed(2)}'
                                  : 'N/A',
                              Icons.attach_money,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildInfoCard(
                              context,
                              'Data Points',
                              provider.chartData.length.toString(),
                              Icons.data_usage,
                              Colors.green,
                            ),
                            const SizedBox(width: 16),
                            _buildInfoCard(
                              context,
                              'Period',
                              provider.selectedTimeframe.toUpperCase(),
                              Icons.access_time,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Chart section
                AnalysisChart(
                  chartData: provider.chartData,
                  symbol: widget.symbol,
                ),
                const SizedBox(height: 24),

                // Insights section
                AnalysisInsights(
                  analysis: provider.currentAnalysis!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
