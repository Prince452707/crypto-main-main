class AnalysisResponse {
  final Map<String, String> analysis;
  final List<ChartDataPoint> chartData;
  final String? timestamp;
  final String? analysisTimestamp;
  final String? dataTimestamp;

  const AnalysisResponse({
    required this.analysis,
    required this.chartData,
    this.timestamp,
    this.analysisTimestamp,
    this.dataTimestamp,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      analysis: Map<String, String>.from(json['analysis'] ?? {}),
      chartData: (json['chartData'] as List<dynamic>?)
              ?.map((item) => ChartDataPoint.fromJson(item))
              .toList() ??
          [],
      timestamp: json['timestamp'] as String?,
      analysisTimestamp: json['analysisTimestamp'] as String?,
      dataTimestamp: json['dataTimestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'chartData': chartData.map((item) => item.toJson()).toList(),
      'timestamp': timestamp,
      'analysisTimestamp': analysisTimestamp,
      'dataTimestamp': dataTimestamp,
    };
  }

  // Helper methods
  String? getAnalysis(String type) => analysis[type];
  
  bool hasAnalysis(String type) => analysis.containsKey(type) && analysis[type]!.isNotEmpty;
  
  List<String> get availableAnalysisTypes => analysis.keys.toList();
  
  bool get hasChartData => chartData.isNotEmpty;

  @override
  String toString() {
    return 'AnalysisResponse{analysis: ${analysis.keys}, chartData: ${chartData.length} points}';
  }
}

class ChartDataPoint {
  final int timestamp;
  final double value;

  const ChartDataPoint({
    required this.timestamp,
    required this.value,
  });

  factory ChartDataPoint.fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      return ChartDataPoint(
        timestamp: (json[0] as num).toInt(),
        value: (json[1] as num).toDouble(),
      );
    } else if (json is Map<String, dynamic>) {
      return ChartDataPoint(
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
      );
    }
    throw ArgumentError('Invalid ChartDataPoint JSON format');
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'value': value,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'ChartDataPoint{timestamp: $timestamp, value: $value}';
  }
}
