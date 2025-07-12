import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget to display data freshness status for cryptocurrency data
class DataFreshnessIndicator extends StatelessWidget {
  final bool isFresh;
  final bool isRealData;
  final String? dataAge;
  final String? source;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  const DataFreshnessIndicator({
    super.key,
    required this.isFresh,
    required this.isRealData,
    this.dataAge,
    this.source,
    this.isRefreshing = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getTextColor(context),
              ),
            )
          else
            FaIcon(
              _getIcon(),
              size: 12,
              color: _getTextColor(context),
            ),
          const SizedBox(width: 4),
          Text(
            _getText(),
            style: TextStyle(
              fontSize: 11,
              color: _getTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: isRefreshing ? null : onRefresh,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  size: 10,
                  color: _getTextColor(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (isRefreshing) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    if (!isRealData) {
      return Colors.orange.withOpacity(0.1);
    }
    if (isFresh) {
      return Colors.green.withOpacity(0.1);
    }
    return Colors.grey.withOpacity(0.1);
  }

  Color _getBorderColor(BuildContext context) {
    if (isRefreshing) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.3);
    }
    if (!isRealData) {
      return Colors.orange.withOpacity(0.3);
    }
    if (isFresh) {
      return Colors.green.withOpacity(0.3);
    }
    return Colors.grey.withOpacity(0.3);
  }

  Color _getTextColor(BuildContext context) {
    if (isRefreshing) {
      return Theme.of(context).colorScheme.primary;
    }
    if (!isRealData) {
      return Colors.orange;
    }
    if (isFresh) {
      return Colors.green;
    }
    return Colors.grey;
  }

  IconData _getIcon() {
    if (!isRealData) {
      return FontAwesomeIcons.triangleExclamation;
    }
    if (isFresh) {
      return FontAwesomeIcons.check;
    }
    return FontAwesomeIcons.clock;
  }

  String _getText() {
    if (isRefreshing) {
      return 'Updating...';
    }
    if (!isRealData) {
      return 'Demo';
    }
    if (dataAge != null) {
      return dataAge!;
    }
    if (isFresh) {
      return 'Fresh';
    }
    return 'Stale';
  }
}

/// Widget to show system-wide real-time status
class SystemStatusIndicator extends StatelessWidget {
  final bool isHealthy;
  final Map<String, dynamic> systemStatus;
  final VoidCallback? onTap;

  const SystemStatusIndicator({
    super.key,
    required this.isHealthy,
    required this.systemStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHealthy ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHealthy ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isHealthy ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 11,
                color: isHealthy ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            FaIcon(
              FontAwesomeIcons.circleInfo,
              size: 10,
              color: isHealthy ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (systemStatus['status'] == 'UP' || systemStatus['status'] == 'healthy') {
      return 'Real-time';
    }
    if (systemStatus['status'] == 'DOWN') {
      return 'Offline';
    }
    return 'Limited';
  }
}
