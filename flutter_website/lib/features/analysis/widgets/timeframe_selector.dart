import 'package:flutter/material.dart';

class TimeframeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final Function(String) onTimeframeChanged;

  const TimeframeSelector({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  static const List<Map<String, String>> timeframes = [
    {'value': '1d', 'label': '1D'},
    {'value': '7d', 'label': '7D'},
    {'value': '30d', 'label': '30D'},
    {'value': '90d', 'label': '90D'},
    {'value': '1y', 'label': '1Y'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: timeframes.map((timeframe) {
          final isSelected = selectedTimeframe == timeframe['value'];
          return GestureDetector(
            onTap: () => onTimeframeChanged(timeframe['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timeframe['label']!,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
