import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/analysis_response.dart';
import '../widgets/analysis_card.dart';
import '../widgets/chart_widget.dart';
import '../widgets/loading_animation.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  final int days;

  const AnalysisScreen({
    super.key,
    required this.symbol,
    required this.days,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnalysisResponse? _analysisData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService().getCryptoAnalysis(
        widget.symbol,
        days: widget.days,
      );

      setState(() {
        _analysisData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          '${widget.symbol} Analysis',
          style: AppTheme.headingMedium,
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalysis,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingAnimation());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_analysisData == null) {
      return _buildNoDataWidget();
    }

    return Column(
      children: [
        // Header with symbol info
        _buildHeader(),
        
        // Chart section
        if (_analysisData!.hasChartData)
          SizedBox(
            height: 300,
            child: ChartWidget(
              chartData: _analysisData!.chartData!,
              symbol: widget.symbol,
            ),
          ),
        
        // Analysis tabs
        _buildAnalysisTabs(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.glassMorphism,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                widget.symbol.substring(0, 3),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.symbol,
                  style: AppTheme.headingMedium,
                ),
                Text(
                  '${widget.days} Days Analysis',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI Powered',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTabs() {
    return Expanded(
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Technical'),
                Tab(text: 'Fundamental'),
                Tab(text: 'News'),
                Tab(text: 'Sentiment'),
                Tab(text: 'Risk'),
                Tab(text: 'Prediction'),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnalysisCard(
                  title: 'General Analysis',
                  content: _analysisData!.generalAnalysis,
                  icon: Icons.analytics,
                ),
                AnalysisCard(
                  title: 'Technical Analysis',
                  content: _analysisData!.technicalAnalysis,
                  icon: Icons.trending_up,
                ),
                AnalysisCard(
                  title: 'Fundamental Analysis',
                  content: _analysisData!.fundamentalAnalysis,
                  icon: Icons.account_balance,
                ),
                AnalysisCard(
                  title: 'News Analysis',
                  content: _analysisData!.newsAnalysis,
                  icon: Icons.newspaper,
                ),
                AnalysisCard(
                  title: 'Sentiment Analysis',
                  content: _analysisData!.sentimentAnalysis,
                  icon: Icons.psychology,
                ),
                AnalysisCard(
                  title: 'Risk Analysis',
                  content: _analysisData!.riskAnalysis,
                  icon: Icons.warning,
                ),
                AnalysisCard(
                  title: 'Price Prediction',
                  content: _analysisData!.predictionAnalysis,
                  icon: Icons.forest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: AppTheme.glassMorphism,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: AppTheme.glassMorphism,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.data_saver_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to fetch analysis data for ${widget.symbol}',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
