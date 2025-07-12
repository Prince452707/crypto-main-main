import 'package:flutter/material.dart';

class AutoRefreshControls extends StatelessWidget {
  final bool autoRefreshEnabled;
  final Duration refreshInterval;
  final VoidCallback onToggleAutoRefresh;
  final Function(Duration) onIntervalChanged;
  final VoidCallback? onManualRefresh;
  final bool isLoading;

  const AutoRefreshControls({
    super.key,
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.onToggleAutoRefresh,
    required this.onIntervalChanged,
    this.onManualRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Real-time Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Auto-refresh toggle
            Row(
              children: [
                Switch.adaptive(
                  value: autoRefreshEnabled,
                  onChanged: (_) => onToggleAutoRefresh(),
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Refresh',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        autoRefreshEnabled 
                            ? 'Updates every ${refreshInterval.inSeconds}s'
                            : 'Manual refresh only',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Manual refresh button
                IconButton(
                  onPressed: isLoading ? null : onManualRefresh,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: Theme.of(context).primaryColor,
                        ),
                  tooltip: 'Manual refresh',
                ),
              ],
            ),
            
            // Refresh interval selector (only when auto-refresh is enabled)
            if (autoRefreshEnabled) ...[
              const SizedBox(height: 16),
              Text(
                'Refresh Interval',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildIntervalSelector(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(BuildContext context) {
    final intervals = [
      const Duration(seconds: 10),
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 2),
      const Duration(minutes: 5),
    ];

    return Wrap(
      spacing: 8,
      children: intervals.map((interval) {
        final isSelected = interval == refreshInterval;
        
        return FilterChip(
          label: Text(_formatInterval(interval)),
          selected: isSelected,
          onSelected: (_) => onIntervalChanged(interval),
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  String _formatInterval(Duration interval) {
    if (interval.inMinutes > 0) {
      return '${interval.inMinutes}m';
    } else {
      return '${interval.inSeconds}s';
    }
  }
}
