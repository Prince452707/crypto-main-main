import 'package:flutter/material.dart';

class RealTimeStatusIndicator extends StatelessWidget {
  final String connectionStatus;
  final bool isDataFresh;
  final DateTime? lastUpdate;
  final VoidCallback? onRefresh;

  const RealTimeStatusIndicator({
    super.key,
    required this.connectionStatus,
    required this.isDataFresh,
    this.lastUpdate,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Icon(
                Icons.refresh,
                size: 16,
                color: _getStatusColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (connectionStatus) {
      case 'connected':
        return isDataFresh ? Colors.green : Colors.orange;
      case 'connecting':
      case 'reconnecting':
        return Colors.blue;
      case 'disconnected':
        return Colors.grey;
      case 'error':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (connectionStatus) {
      case 'connected':
        if (isDataFresh) {
          return 'Live Data';
        } else {
          return 'Connected';
        }
      case 'connecting':
        return 'Connecting...';
      case 'reconnecting':
        return 'Reconnecting...';
      case 'disconnected':
        return 'Offline';
      case 'error':
        return 'Error';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}
