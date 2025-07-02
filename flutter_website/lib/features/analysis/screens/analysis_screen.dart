import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/analysis_chart.dart';
import '../widgets/analysis_insights.dart';
import '../widgets/analysis_search.dart';
import '../widgets/timeframe_selector.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Load default analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyzeSymbol('bitcoin');
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
                  const Icon(
                    Icons.analytics_outlined,
                    size: 32,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'AI Analysis',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 300,
                    child: AnalysisSearch(
                      onSymbolSelected: (symbol) {
                        provider.analyzeSymbol(symbol);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Current symbol info
              if (provider.currentAnalysis != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.currency_bitcoin,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectedSymbol.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Analysis Period: ${provider.selectedTimeframe}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Loading state
              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing cryptocurrency data...'),
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
                            provider.analyzeSymbol(provider.selectedSymbol);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Analysis content
              if (!provider.isLoading && provider.error == null && provider.currentAnalysis != null) ...[
                // Chart section
                AnalysisChart(
                  chartData: provider.chartData,
                  symbol: provider.selectedSymbol,
                ),
                const SizedBox(height: 24),

                // Insights section
                AnalysisInsights(
                  analysis: provider.currentAnalysis!,
                ),
              ],

              // Empty state
              if (!provider.isLoading && provider.error == null && provider.currentAnalysis == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for a cryptocurrency to get AI-powered analysis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
