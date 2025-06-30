import 'chart_data_point.dart';
import 'crypto_details.dart';

class AnalysisResponse {
  final Map<String, String> analysis;
  final List<ChartDataPoint>? chartData;
  final CryptoDetails? details;
  final Map<String, dynamic>? teamData;
  final List<Map<String, String>>? newsData;

  AnalysisResponse({
    required this.analysis,
    this.chartData,
    this.details,
    this.teamData,
    this.newsData,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      analysis: Map<String, String>.from(json['analysis'] ?? {}),
      chartData: json['chartData'] != null
          ? (json['chartData'] as List)
              .map((item) => ChartDataPoint.fromJson(item))
              .toList()
          : null,
      details: json['details'] != null 
          ? CryptoDetails.fromJson(json['details'])
          : null,
      teamData: json['teamData'] as Map<String, dynamic>?,
      newsData: json['newsData'] != null
          ? (json['newsData'] as List)
              .map((item) => Map<String, String>.from(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'chartData': chartData?.map((item) => item.toJson()).toList(),
      'details': details?.toJson(),
      'teamData': teamData,
      'newsData': newsData,
    };
  }

  // Getter methods for specific analysis types
  String get generalAnalysis => analysis['general'] ?? 'No general analysis available';
  String get technicalAnalysis => analysis['technical'] ?? 'No technical analysis available';
  String get fundamentalAnalysis => analysis['fundamental'] ?? 'No fundamental analysis available';
  String get newsAnalysis => analysis['news'] ?? 'No news analysis available';
  String get sentimentAnalysis => analysis['sentiment'] ?? 'No sentiment analysis available';
  String get riskAnalysis => analysis['risk'] ?? 'No risk analysis available';
  String get predictionAnalysis => analysis['prediction'] ?? 'No prediction analysis available';

  bool get hasChartData => chartData != null && chartData!.isNotEmpty;
  bool get hasDetails => details != null;
  bool get hasTeamData => teamData != null && teamData!.isNotEmpty;
  bool get hasNewsData => newsData != null && newsData!.isNotEmpty;
}
