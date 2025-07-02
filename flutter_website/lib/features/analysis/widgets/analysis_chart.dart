import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/chart_data.dart' as chart;

class AnalysisChart extends StatelessWidget {
  final List<chart.ChartDataPoint> chartData;
  final String symbol;

  const AnalysisChart({
    super.key,
    required this.chartData,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Chart - ${symbol.toUpperCase()}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: chartData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No chart data available',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: null,
                          verticalInterval: null,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
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
                              interval: _getXInterval(),
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                                  final dataPoint = chartData[value.toInt()];
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      dataPoint.formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: null,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    '\$${_formatPrice(value)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        minX: 0,
                        maxX: chartData.length.toDouble() - 1,
                        minY: _getMinPrice(),
                        maxY: _getMaxPrice(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.price);
                            }).toList(),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.3),
                              ],
                            ),
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor.withOpacity(0.3),
                                  Theme.of(context).primaryColor.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinPrice() {
    if (chartData.isEmpty) return 0;
    return chartData.map((e) => e.price).reduce((a, b) => a < b ? a : b) * 0.95;
  }

  double _getMaxPrice() {
    if (chartData.isEmpty) return 100;
    return chartData.map((e) => e.price).reduce((a, b) => a > b ? a : b) * 1.05;
  }

  double _getXInterval() {
    if (chartData.length <= 10) return 1;
    return (chartData.length / 5).ceilToDouble();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else if (price >= 1) {
      return price.toStringAsFixed(0);
    } else {
      return price.toStringAsFixed(4);
    }
  }
}
