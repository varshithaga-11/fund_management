import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';
import 'financial_statements_api.dart'; // Reuse models like RatioResultData

// Extended period data with ratio information from dashboard
class PeriodWithRatiosData {
  final int id;
  final String periodType;
  final String label;
  final String startDate;
  final String endDate;
  final bool isFinalized;
  final String? uploadedFile;
  final String? fileType;
  final String createdAt;
  final RatioResultData? ratios;

  PeriodWithRatiosData({
    required this.id,
    required this.periodType,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.isFinalized,
    this.uploadedFile,
    this.fileType,
    required this.createdAt,
    this.ratios,
  });

  factory PeriodWithRatiosData.fromJson(Map<String, dynamic> json) {
    return PeriodWithRatiosData(
      id: json['id'],
      periodType: json['period_type'],
      label: json['label'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isFinalized: json['is_finalized'],
      uploadedFile: json['uploaded_file'],
      fileType: json['file_type'],
      createdAt: json['created_at'],
      ratios: json['ratios'] != null ? RatioResultData.fromJson(json['ratios']) : null,
    );
  }
}

// Fetch periods with ratio data using optimized dashboard endpoint
Future<List<PeriodWithRatiosData>> getPeriodsWithRatios() async {
  final url = createApiUrl('api/dashboard/?period=all&include_ratios=true');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['data'] != null && data['data']['periods'] != null) {
      List<dynamic> periods = data['data']['periods'];
      return periods.map((p) => PeriodWithRatiosData.fromJson(p)).toList();
    }
    return [];
  }
  throw Exception('Failed to fetch periods with ratios');
}

Future<List<PeriodWithRatiosData>> getPeriodsList() async {
  return await getPeriodsWithRatios();
}

Future<List<Map<String, dynamic>>> getRatioTrends({String? category}) async {
  String url = createApiUrl('api/dashboard/?period=all&include_ratios=true');
  if (category != null) {
    url += '&category=${Uri.encodeComponent(category)}';
  }

  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['data'] != null && data['data']['periods'] != null) {
      List<dynamic> periods = data['data']['periods'];
      
      // Filter & Transform
      List<Map<String, dynamic>> trendData = periods
          .where((p) => p['ratios'] != null)
          .map((p) {
            Map<String, dynamic> ratios = p['ratios'];
            return {
              'period': p['id'],
              'period_label': p['label'],
               // Flatten ratios
              ...ratios
            };
          })
          .toList();
      
      return trendData;
    }
    return [];
  }
  throw Exception('Failed to fetch ratio trends');
}
