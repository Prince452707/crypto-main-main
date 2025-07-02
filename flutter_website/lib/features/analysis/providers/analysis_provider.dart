import 'package:flutter/foundation.dart';
import '../../../core/models/analysis_response.dart';
import '../../../core/models/chart_data.dart' as chart;
import '../../../core/services/api_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  AnalysisResponse? _currentAnalysis;
  List<chart.ChartDataPoint> _chartData = [];
  String _selectedSymbol = 'bitcoin';
  String _selectedTimeframe = '7d';
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  AnalysisResponse? get currentAnalysis => _currentAnalysis;
  List<chart.ChartDataPoint> get chartData => _chartData;
  String get selectedSymbol => _selectedSymbol;
  String get selectedTimeframe => _selectedTimeframe;
  
  Future<void> analyzeSymbol(String symbol) async {
    _isLoading = true;
    _error = null;
    _selectedSymbol = symbol;
    notifyListeners();
    
    try {
      _currentAnalysis = await _apiService.getAnalysis(symbol);
      await _loadChartData(symbol, _selectedTimeframe);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> changeTimeframe(String timeframe) async {
    if (_selectedTimeframe == timeframe) return;
    
    _selectedTimeframe = timeframe;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadChartData(_selectedSymbol, timeframe);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadChartData(String symbol, String timeframe) async {
    try {
      // Convert timeframe to days for the API call
      int days;
      switch (timeframe) {
        case '1d':
          days = 1;
          break;
        case '7d':
          days = 7;
          break;
        case '30d':
          days = 30;
          break;
        case '90d':
          days = 90;
          break;
        case '1y':
          days = 365;
          break;
        default:
          days = 7;
      }
      _chartData = await _apiService.getChartDataPoints(symbol, days);
    } catch (e) {
      // Handle chart data error separately from analysis error
      debugPrint('Chart data error: $e');
    }
  }
  
  void clearAnalysis() {
    _currentAnalysis = null;
    _chartData = [];
    _error = null;
    notifyListeners();
  }
}
