import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/chart_data.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/widgets/error_widget.dart';

class ChartTab extends StatefulWidget {
  final String symbol;
  final String cryptoId;

  const ChartTab({
    Key? key,
    required this.symbol,
    required this.cryptoId,
  }) : super(key: key);

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  List<ChartDataPoint> _chartData = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 30;
  final ApiService _apiService = ApiService();

  final List<int> _dayOptions = [1, 7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _apiService.getChartDataPoints(widget.symbol, _selectedDays);
      
      if (mounted) {
        setState(() {
          _chartData = data;
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

  void _onDaysChanged(int days) {
    setState(() {
      _selectedDays = days;
    });
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time Period Selector
        _buildTimePeriodSelector(),
        const SizedBox(height: 16),
        
        // Chart Content
        Expanded(
          child: _buildChartContent(),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _dayOptions.map((days) {
          final isSelected = days == _selectedDays;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onDaysChanged(days),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  days == 1 ? '1D' : 
                  days == 7 ? '1W' :
                  days == 30 ? '1M' :
                  days == 90 ? '3M' : '1Y',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return const Center(child: LoadingSpinner());
    }

    if (_error != null) {
      return Center(
        child: ErrorDisplayWidget(
          error: _error!,
          onRetry: _loadChartData,
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No chart data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Chart data for ${widget.symbol} is not available for the selected period.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
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
            // Chart Header
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.symbol.toUpperCase()} Price Chart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_chartData.length} points',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Price Stats Row
            _buildPriceStatsRow(),
            const SizedBox(height: 20),
            
            // Chart
            Expanded(
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStatsRow() {
    if (_chartData.isEmpty) return const SizedBox.shrink();
    
    final firstPrice = _chartData.first.price;
    final lastPrice = _chartData.last.price;
    final highPrice = _chartData.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final lowPrice = _chartData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final priceChange = lastPrice - firstPrice;
    final priceChangePercent = (priceChange / firstPrice) * 100;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Current',
            '\$${lastPrice.toStringAsFixed(2)}',
            priceChangePercent >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Change',
            '${priceChangePercent >= 0 ? '+' : ''}${priceChangePercent.toStringAsFixed(2)}%',
            priceChangePercent >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'High',
            '\$${highPrice.toStringAsFixed(2)}',
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Low',
            '\$${lowPrice.toStringAsFixed(2)}',
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final spots = _chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final minPrice = _chartData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = _chartData.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxPrice - minPrice) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getXAxisInterval(),
              getTitlesWidget: (value, meta) => _buildBottomTitle(value),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxPrice - minPrice) / 4,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => _buildLeftTitle(value),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: minPrice * 0.98,
        maxY: maxPrice * 1.02,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.secondaryBlue,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.3),
                  AppTheme.primaryBlue.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataPoint = _chartData[spot.x.toInt()];
                return LineTooltipItem(
                  '\$${dataPoint.price.toStringAsFixed(2)}\n${_formatDate(dataPoint.timestamp)}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _getXAxisInterval() {
    if (_chartData.length <= 10) return 1;
    return (_chartData.length / 5).ceilToDouble();
  }

  Widget _buildBottomTitle(double value) {
    final index = value.toInt();
    if (index < 0 || index >= _chartData.length) {
      return const SizedBox.shrink();
    }
    
    final dataPoint = _chartData[index];
    final date = DateTime.fromMillisecondsSinceEpoch(dataPoint.timestamp);
    
    return SideTitleWidget(
      axisSide: AxisSide.bottom,
      child: Text(
        '${date.month}/${date.day}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
    return SideTitleWidget(
      axisSide: AxisSide.left,
      child: Text(
        '\$${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.month}/${date.day}/${date.year}';
  }
}
