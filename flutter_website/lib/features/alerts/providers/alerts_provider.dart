import 'package:flutter/foundation.dart';
import '../models/price_alert.dart';

class AlertsProvider extends ChangeNotifier {
  
  List<PriceAlert> _alerts = [];
  List<PriceAlert> _triggeredAlerts = [];
  bool _isLoading = false;
  String? _error;
  
  List<PriceAlert> get alerts => _alerts;
  List<PriceAlert> get triggeredAlerts => _triggeredAlerts;
  List<PriceAlert> get activeAlerts => _alerts.where((alert) => alert.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get totalAlerts => _alerts.length;
  int get activeAlertsCount => activeAlerts.length;
  int get triggeredAlertsCount => _triggeredAlerts.length;

  AlertsProvider() {
    _loadAlertsFromStorage();
  }

  void _loadAlertsFromStorage() {
    // In a real app, load from local storage or backend
    // For now, start with empty alerts
    _alerts = [];
    _triggeredAlerts = [];
    notifyListeners();
  }

  Future<void> createAlert({
    required String symbol,
    required String coinName,
    required double targetPrice,
    required AlertType type,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final alert = PriceAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: symbol.toUpperCase(),
        coinName: coinName,
        targetPrice: targetPrice,
        type: type,
        isActive: true,
        createdAt: DateTime.now(),
        notes: notes,
      );

      _alerts.add(alert);
      
      // Save to storage/backend in real implementation
      _saveAlertsToStorage();
      
    } catch (e) {
      _error = 'Failed to create alert: $e';
      debugPrint('Error creating alert: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      _alerts.removeWhere((alert) => alert.id == alertId);
      _saveAlertsToStorage();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete alert: $e';
    }
  }

  Future<void> toggleAlert(String alertId) async {
    try {
      final index = _alerts.indexWhere((alert) => alert.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(
          isActive: !_alerts[index].isActive,
        );
        _saveAlertsToStorage();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle alert: $e';
    }
  }

  Future<void> checkAlerts(Map<String, double> currentPrices) async {
    try {
      final alertsToTrigger = <PriceAlert>[];
      
      for (final alert in activeAlerts) {
        final currentPrice = currentPrices[alert.symbol];
        if (currentPrice == null) continue;
        
        bool shouldTrigger = false;
        
        switch (alert.type) {
          case AlertType.above:
            shouldTrigger = currentPrice >= alert.targetPrice;
            break;
          case AlertType.below:
            shouldTrigger = currentPrice <= alert.targetPrice;
            break;
          case AlertType.percentageGain:
            // Would need historical price to calculate percentage
            break;
          case AlertType.percentageLoss:
            // Would need historical price to calculate percentage
            break;
        }
        
        if (shouldTrigger) {
          alertsToTrigger.add(alert);
        }
      }
      
      // Trigger alerts
      for (final alert in alertsToTrigger) {
        final triggeredAlert = alert.copyWith(
          isActive: false,
          triggeredAt: DateTime.now(),
        );
        
        _triggeredAlerts.add(triggeredAlert);
        _alerts.removeWhere((a) => a.id == alert.id);
        
        // In a real app, send notification here
        _showNotification(triggeredAlert, currentPrices[alert.symbol]!);
      }
      
      if (alertsToTrigger.isNotEmpty) {
        _saveAlertsToStorage();
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('Error checking alerts: $e');
    }
  }

  void _showNotification(PriceAlert alert, double currentPrice) {
    // In a real app, integrate with platform notifications
    debugPrint('ALERT TRIGGERED: ${alert.symbol} ${alert.type.displayName} $currentPrice');
  }

  void _saveAlertsToStorage() {
    // In a real app, save to local storage or backend
    debugPrint('Saving ${_alerts.length} alerts to storage');
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // In a real app, load from backend
      await Future.delayed(const Duration(milliseconds: 500));
      _loadAlertsFromStorage();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearTriggeredAlerts() {
    _triggeredAlerts.clear();
    notifyListeners();
  }

  List<PriceAlert> getAlertsForSymbol(String symbol) {
    return _alerts.where((alert) => 
      alert.symbol.toLowerCase() == symbol.toLowerCase()
    ).toList();
  }
}
