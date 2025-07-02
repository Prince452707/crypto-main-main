import 'package:flutter/material.dart';
import '../../../core/models/analysis_response.dart';

class AnalysisInsights extends StatelessWidget {
  final AnalysisResponse analysis;

  const AnalysisInsights({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final analysisEntries = analysis.analysis.entries.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Analysis timestamp if available
        if (analysis.analysisTimestamp != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Analysis generated: ${analysis.analysisTimestamp}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),

        // Analysis cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: analysisEntries.length,
          itemBuilder: (context, index) {
            final entry = analysisEntries[index];
            return _buildAnalysisCard(
              context,
              entry.key,
              entry.value,
              _getAnalysisIcon(entry.key),
              _getAnalysisColor(entry.key),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatTitle(title),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTitle(String title) {
    // Convert camelCase or snake_case to readable title
    return title
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ')
        .trim();
  }

  IconData _getAnalysisIcon(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
      case 'technical_analysis':
        return Icons.trending_up;
      case 'fundamental':
      case 'fundamental_analysis':
        return Icons.analytics;
      case 'sentiment':
      case 'market_sentiment':
        return Icons.psychology;
      case 'risk':
      case 'risk_assessment':
        return Icons.warning;
      case 'price':
      case 'price_prediction':
        return Icons.show_chart;
      case 'summary':
      case 'executive_summary':
        return Icons.summarize;
      case 'recommendation':
        return Icons.thumbs_up_down;
      case 'volatility':
        return Icons.equalizer;
      default:
        return Icons.insights;
    }
  }

  Color _getAnalysisColor(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
      case 'technical_analysis':
        return Colors.blue;
      case 'fundamental':
      case 'fundamental_analysis':
        return Colors.green;
      case 'sentiment':
      case 'market_sentiment':
        return Colors.purple;
      case 'risk':
      case 'risk_assessment':
        return Colors.orange;
      case 'price':
      case 'price_prediction':
        return Colors.indigo;
      case 'summary':
      case 'executive_summary':
        return Colors.teal;
      case 'recommendation':
        return Colors.amber;
      case 'volatility':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
