import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/analysis_response.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/widgets/error_widget.dart';

class AIInsightsTab extends StatefulWidget {
  final String symbol;
  final String cryptoId;

  const AIInsightsTab({
    Key? key,
    required this.symbol,
    required this.cryptoId,
  }) : super(key: key);

  @override
  State<AIInsightsTab> createState() => _AIInsightsTabState();
}

class _AIInsightsTabState extends State<AIInsightsTab> with TickerProviderStateMixin {
  AnalysisResponse? _analysisData;
  bool _isLoading = true;
  String? _error;
  final AIService _aiService = AIService();
  
  late TabController _analysisTabController;
  
  final List<AnalysisType> _analysisTypes = [
    AnalysisType.general,
    AnalysisType.technical,
    AnalysisType.fundamental,
    AnalysisType.sentiment,
    AnalysisType.risk,
    AnalysisType.prediction,
  ];

  @override
  void initState() {
    super.initState();
    _analysisTabController = TabController(length: _analysisTypes.length, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _analysisTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analysis = await _aiService.getCryptoAnalysis(widget.symbol);
      
      if (mounted) {
        setState(() {
          _analysisData = analysis;
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
    return Column(
      children: [
        // Header with Refresh Button
        _buildHeader(),
        
        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'AI-Powered Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!_isLoading)
            IconButton(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Analysis',
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingSpinner(size: 48),
            const SizedBox(height: 16),
            Text(
              'Analyzing ${widget.symbol.toUpperCase()}...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: ErrorDisplayWidget(
          error: _error!,
          onRetry: _loadAnalysis,
          title: 'Analysis Failed',
        ),
      );
    }

    if (_analysisData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Analysis Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to generate analysis for ${widget.symbol.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Analysis Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _analysisTabController,
            isScrollable: true,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            tabs: _analysisTypes.map((type) {
              return Tab(text: _getAnalysisTypeLabel(type));
            }).toList(),
          ),
        ),
        
        // Analysis Content
        Expanded(
          child: TabBarView(
            controller: _analysisTabController,
            children: _analysisTypes.map((type) {
              return _buildAnalysisCard(type);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(AnalysisType type) {
    final analysis = _getAnalysisForType(type);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAnalysisTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAnalysisTypeIcon(type),
                      color: _getAnalysisTypeColor(type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getAnalysisTypeTitle(type),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 12,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Analysis Content
              Expanded(
                child: SingleChildScrollView(
                  child: analysis.isNotEmpty
                      ? _buildAnalysisContent(analysis)
                      : _buildEmptyAnalysis(type),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisContent(String analysis) {
    return SelectableText(
      analysis,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildEmptyAnalysis(AnalysisType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getAnalysisTypeLabel(type)} analysis available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analysis data may not be available for this cryptocurrency.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getAnalysisForType(AnalysisType type) {
    if (_analysisData?.analysis == null) return '';
    
    switch (type) {
      case AnalysisType.general:
        return _analysisData!.analysis['general'] ?? '';
      case AnalysisType.technical:
        return _analysisData!.analysis['technical'] ?? '';
      case AnalysisType.fundamental:
        return _analysisData!.analysis['fundamental'] ?? '';
      case AnalysisType.sentiment:
        return _analysisData!.analysis['sentiment'] ?? '';
      case AnalysisType.risk:
        return _analysisData!.analysis['risk'] ?? '';
      case AnalysisType.prediction:
        return _analysisData!.analysis['prediction'] ?? '';
    }
  }

  String _getAnalysisTypeLabel(AnalysisType type) {
    switch (type) {
      case AnalysisType.general:
        return 'General';
      case AnalysisType.technical:
        return 'Technical';
      case AnalysisType.fundamental:
        return 'Fundamental';
      case AnalysisType.sentiment:
        return 'Sentiment';
      case AnalysisType.risk:
        return 'Risk';
      case AnalysisType.prediction:
        return 'Prediction';
    }
  }

  String _getAnalysisTypeTitle(AnalysisType type) {
    switch (type) {
      case AnalysisType.general:
        return 'General Market Analysis';
      case AnalysisType.technical:
        return 'Technical Analysis';
      case AnalysisType.fundamental:
        return 'Fundamental Analysis';
      case AnalysisType.sentiment:
        return 'Market Sentiment';
      case AnalysisType.risk:
        return 'Risk Assessment';
      case AnalysisType.prediction:
        return 'Price Prediction';
    }
  }

  IconData _getAnalysisTypeIcon(AnalysisType type) {
    switch (type) {
      case AnalysisType.general:
        return Icons.analytics;
      case AnalysisType.technical:
        return Icons.trending_up;
      case AnalysisType.fundamental:
        return Icons.account_balance;
      case AnalysisType.sentiment:
        return Icons.psychology;
      case AnalysisType.risk:
        return Icons.warning;
      case AnalysisType.prediction:
        return Icons.insights;
    }
  }

  Color _getAnalysisTypeColor(AnalysisType type) {
    switch (type) {
      case AnalysisType.general:
        return AppTheme.primaryBlue;
      case AnalysisType.technical:
        return AppTheme.successGreen;
      case AnalysisType.fundamental:
        return AppTheme.secondaryBlue;
      case AnalysisType.sentiment:
        return AppTheme.warningOrange;
      case AnalysisType.risk:
        return AppTheme.errorRed;
      case AnalysisType.prediction:
        return AppTheme.accentGold;
    }
  }
}

enum AnalysisType {
  general,
  technical,
  fundamental,
  sentiment,
  risk,
  prediction,
}
