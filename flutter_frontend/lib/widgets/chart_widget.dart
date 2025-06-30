import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/chart_data_point.dart';

class ChartWidget extends StatefulWidget {
  final List<ChartDataPoint> chartData;
  final String symbol;

  const ChartWidget({
    super.key,
    required this.chartData,
    required this.symbol,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
      return _buildNoDataWidget();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.glassMorphism,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppTheme.accentCyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.symbol} Price Chart',
                style: AppTheme.headingMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.chartData.length} points',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textTertiary.withOpacity(0.2),
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
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(value);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _getYAxisInterval(),
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return _buildLeftTitle(value);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppTheme.textTertiary.withOpacity(0.2),
                  ),
                ),
                minX: 0,
                maxX: widget.chartData.length.toDouble() - 1,
                minY: _getMinPrice(),
                maxY: _getMaxPrice(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(),
                    isCurved: true,
                    gradient: AppTheme.primaryGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentCyan.withOpacity(0.3),
                          AppTheme.accentCyan.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.cardBackground,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dataPoint = widget.chartData[spot.x.toInt()];
                        return LineTooltipItem(
                          '\$${dataPoint.price.toStringAsFixed(2)}\n${dataPoint.formattedDate}',
                          const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.glassMorphism,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Chart Data Available',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chart data for ${widget.symbol} is not available',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return widget.chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();
  }

  double _getMinPrice() {
    if (widget.chartData.isEmpty) return 0;
    final minPrice = widget.chartData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    return minPrice * 0.95; // Add 5% padding
  }

  double _getMaxPrice() {
    if (widget.chartData.isEmpty) return 100;
    final maxPrice = widget.chartData.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    return maxPrice * 1.05; // Add 5% padding
  }

  double _getXAxisInterval() {
    if (widget.chartData.length <= 10) return 1;
    return (widget.chartData.length / 5).ceilToDouble();
  }

  double _getYAxisInterval() {
    final range = _getMaxPrice() - _getMinPrice();
    return range / 5;
  }

  Widget _buildBottomTitle(double value) {
    final index = value.toInt();
    if (index < 0 || index >= widget.chartData.length) {
      return const SizedBox.shrink();
    }
    
    final dataPoint = widget.chartData[index];
    final date = dataPoint.dateTime;
    return SideTitleWidget(
      axisSide: AxisSide.bottom,
      child: Text(
        '${date.month}/${date.day}',
        style: TextStyle(
          color: AppTheme.textTertiary,
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
          color: AppTheme.textTertiary,
          fontSize: 10,
        ),
      ),
    );
  }
}
