import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

// Reuse PeriodWithRatiosData as it closely matches what dashboard needs (list of periods with some data)
// But Dashboard API might return a slightly different structure for "filtered" data vs list
// Based on React code: dashboard returns { data: { periods: [...], total_revenue, avg_profit_margin, growth_rate } }

class DashboardData {
  final List<DashboardPeriodData> periods;
  final double totalRevenue;
  final double totalProfit;
  final double avgProfitMargin;
  final double growthRate;

  DashboardData({
    required this.periods,
    required this.totalRevenue,
    required this.totalProfit,
    required this.avgProfitMargin,
    required this.growthRate,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var periodsList = (json['periods'] as List? ?? [])
        .map((p) => DashboardPeriodData.fromJson(p))
        .toList();

    return DashboardData(
      periods: periodsList,
      totalRevenue: _toDouble(json['total_revenue']),
      totalProfit: _toDouble(json['total_profit']), // React calc logic might imply this is needed or pre-calc
      avgProfitMargin: _toDouble(json['avg_profit_margin']),
      growthRate: _toDouble(json['growth_rate']),
    );
  }
}

class DashboardPeriodData {
  final int id;
  final String label;
  final String periodType;
  final String startDate;
  final String endDate;
  final bool isFinalized;
  final String createdAt;
  final double revenue;
  final double netProfit;

  DashboardPeriodData({
    required this.id,
    required this.label,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.isFinalized,
    required this.createdAt,
    required this.revenue,
    required this.netProfit,
  });

  factory DashboardPeriodData.fromJson(Map<String, dynamic> json) {
    // React Logic:
    // trading_account: p.trading_account || { sales: p.net_revenue || 0 }
    // profit_loss: p.profit_loss || { net_profit: p.net_profit || 0 }
    
    double rev = 0;
    if (json['trading_account'] != null) {
      rev = _toDouble(json['trading_account']['sales']);
    } else {
      rev = _toDouble(json['net_revenue']);
    }

    double prof = 0;
    if (json['profit_loss'] != null) {
      prof = _toDouble(json['profit_loss']['net_profit']);
    } else {
      prof = _toDouble(json['net_profit']);
    }

    return DashboardPeriodData(
      id: json['id'],
      label: json['label'],
      periodType: json['period_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isFinalized: json['is_finalized'],
      createdAt: json['created_at'],
      revenue: rev,
      netProfit: prof,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

Future<DashboardData?> getDashboardData() async {
  final url = createApiUrl('api/dashboard/?period=all');
  try {
    final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['data'] != null) {
        return DashboardData.fromJson(body['data']);
      }
    }
    return null;
  } catch (e) {
    print("Error fetching dashboard data: $e");
    return null;
  }
}
