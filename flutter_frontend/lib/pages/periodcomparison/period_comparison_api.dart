import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

// Lightweight period data for listing
class PeriodListData {
  final int id;
  final String periodType;
  final String label;
  final String startDate;
  final String endDate;
  final bool? isFinalized;
  final String? uploadedFile;
  final String? fileType;
  final String? createdAt;

  PeriodListData({
    required this.id,
    required this.periodType,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.isFinalized,
    this.uploadedFile,
    this.fileType,
    this.createdAt,
  });

  factory PeriodListData.fromJson(Map<String, dynamic> json) {
    return PeriodListData(
      id: json['id'],
      periodType: json['period_type'],
      label: json['label'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isFinalized: json['is_finalized'],
      uploadedFile: json['uploaded_file'],
      fileType: json['file_type'],
      createdAt: json['created_at'],
    );
  }
}

class RatioComparison {
  final double? period1;
  final double? period2;
  final double? difference;
  final double? percentageChange;

  RatioComparison({
    this.period1,
    this.period2,
    this.difference,
    this.percentageChange,
  });

  factory RatioComparison.fromJson(Map<String, dynamic> json) {
    return RatioComparison(
      period1: _toDouble(json['period1']),
      period2: _toDouble(json['period2']),
      difference: _toDouble(json['difference']),
      percentageChange: _toDouble(json['percentage_change']),
    );
  }
}

class PeriodComparisonData {
  final String period1;
  final String period2;
  final Map<String, RatioComparison> ratios;

  PeriodComparisonData({
    required this.period1,
    required this.period2,
    required this.ratios,
  });

  factory PeriodComparisonData.fromJson(Map<String, dynamic> json) {
    Map<String, RatioComparison> ratios = {};
    if (json['ratios'] != null) {
      (json['ratios'] as Map<String, dynamic>).forEach((key, value) {
        ratios[key] = RatioComparison.fromJson(value);
      });
    }
    return PeriodComparisonData(
      period1: json['period1'],
      period2: json['period2'],
      ratios: ratios,
    );
  }
}

class PeriodComparisonResponse {
  final String status;
  final int responseCode;
  final PeriodComparisonData data;

  PeriodComparisonResponse({
    required this.status,
    required this.responseCode,
    required this.data,
  });

  factory PeriodComparisonResponse.fromJson(Map<String, dynamic> json) {
    return PeriodComparisonResponse(
      status: json['status'],
      responseCode: json['response_code'],
      data: PeriodComparisonData.fromJson(json['data']),
    );
  }
}

class RawPeriodComparisonResponse {
  final String status;
  final int responseCode;
  final Map<String, dynamic> data;

  RawPeriodComparisonResponse({
    required this.status,
    required this.responseCode,
    required this.data,
  });

  factory RawPeriodComparisonResponse.fromJson(Map<String, dynamic> json) {
    return RawPeriodComparisonResponse(
      status: json['status'],
      responseCode: json['response_code'],
      data: json['data'],
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value);
  return null;
}

// Fetch all periods
Future<List<PeriodListData>> getPeriodsList() async {
  final url = createApiUrl('api/financial-periods/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final dynamic body = jsonDecode(response.body);
    List<dynamic> data = [];
    
    if (body is Map && body.containsKey('data') && body['data'] is List) {
      data = body['data'];
    } else if (body is List) {
      data = body;
    } else if (body is Map && body.containsKey('results') && body['results'] is List) {
      data = body['results'];
    } else {
      throw Exception('Invalid response structure');
    }
    
    return data.map((json) => PeriodListData.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch period list');
  }
}

// Compare periods for a company using period IDs (optimized)
Future<RawPeriodComparisonResponse> comparePeriodsById(int period1Id, int period2Id) async {
  final url = createApiUrl('api/period-comparison-by-id/?period_id1=$period1Id&period_id2=$period2Id');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    return RawPeriodComparisonResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to compare periods: ${response.body}');
  }
}

// Helper to transform raw data to structured response
PeriodComparisonResponse transformRawComparisonData(
    RawPeriodComparisonResponse rawData, String period1Label, String period2Label) {
  
  if (rawData.data['period_1'] == null || rawData.data['period_2'] == null || rawData.data['difference'] == null) {
      throw Exception('Invalid raw data structure');
  }

  final period1 = rawData.data['period_1'];
  final period2 = rawData.data['period_2'];
  final difference = rawData.data['difference'];

  final ratioFields = [
    'stock_turnover', 'gross_profit_ratio', 'net_profit_ratio',
    'net_own_funds', 'own_fund_to_wf', 'deposits_to_wf', 'borrowings_to_wf',
    'loans_to_wf', 'investments_to_wf', 'earning_assets_to_wf', 'interest_tagged_funds_to_wf',
    'cost_of_deposits', 'yield_on_loans', 'yield_on_investments', 'credit_deposit_ratio',
    'avg_cost_of_wf', 'avg_yield_on_wf', 'misc_income_to_wf', 'interest_exp_to_interest_income',
    'gross_fin_margin', 'operating_cost_to_wf', 'net_fin_margin', 'risk_cost_to_wf', 'net_margin',
    'capital_turnover_ratio',
    'per_employee_deposit', 'per_employee_loan', 'per_employee_contribution', 'per_employee_operating_cost',
    'working_fund'
  ];

  Map<String, RatioComparison> ratios = {};
  
  for (var field in ratioFields) {
    final p1Value = _toDouble(period1[field]);
    final p2Value = _toDouble(period2[field]);
    
    final diffObj = difference[field];
    final diffValue = diffObj != null ? _toDouble(diffObj['value']) : null;
    final percentChange = diffObj != null ? _toDouble(diffObj['percentage_change']) : null;

    ratios[field] = RatioComparison(
      period1: p1Value,
      period2: p2Value,
      difference: diffValue,
      percentageChange: percentChange,
    );
  }

  return PeriodComparisonResponse(
    status: rawData.status,
    responseCode: rawData.responseCode,
    data: PeriodComparisonData(
      period1: period1Label,
      period2: period2Label,
      ratios: ratios,
    ),
  );
}
