import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api';
  static String? _authToken;

  // Initialize auth token from storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Try both key names for compatibility
    _authToken = prefs.getString('access') ?? prefs.getString('access_token');
  }

  // Set auth token and persist it
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access', token);
    await prefs.setString('access_token', token); // For backward compatibility
  }

  // Get headers with auth
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load dashboard data: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching dashboard: $e';
    }
  }

  // Financial periods
  static Future<List<dynamic>> getFinancialPeriods() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/periods/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : data['results'] ?? [];
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load periods: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching periods: $e';
    }
  }

  // Profit and loss data
  static Future<Map<String, dynamic>> getProfitLossData({
    int? periodId,
    String? year,
  }) async {
    try {
      String url = '$_baseUrl/profit-loss/';
      final params = <String, String>{};
      if (periodId != null) params['period_id'] = periodId.toString();
      if (year != null) params['year'] = year;

      if (params.isNotEmpty) {
        url += '?${Uri(queryParameters: params).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load P&L data: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching P&L data: $e';
    }
  }

  // Ratio results
  static Future<List<dynamic>> getRatioResults({int? periodId}) async {
    try {
      String url = '$_baseUrl/ratio-results/';
      if (periodId != null) {
        url += '?period_id=$periodId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : data['results'] ?? [];
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load ratios: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching ratios: $e';
    }
  }

  // Period comparison
  static Future<Map<String, dynamic>> getPeriodComparison() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/period-comparison/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load comparison: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching comparison: $e';
    }
  }

  // Operational metrics
  static Future<List<dynamic>> getOperationalMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/operational-metrics/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : data['results'] ?? [];
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load metrics: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching metrics: $e';
    }
  }

  // Balance sheet data
  static Future<Map<String, dynamic>> getBalanceSheetData({
    int? periodId,
  }) async {
    try {
      String url = '$_baseUrl/balance-sheets/';
      if (periodId != null) {
        url += '?period_id=$periodId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to load balance sheet: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching balance sheet: $e';
    }
  }

  // Export data to CSV
  static Future<String> exportToCSV({
    required String dataType,
    int? periodId,
  }) async {
    try {
      final params = {
        'format': 'csv',
        if (periodId != null) 'period_id': periodId.toString(),
      };

      final uri = Uri.parse('$_baseUrl/$dataType/')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to export CSV: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error exporting CSV: $e';
    }
  }

  // Export data to Excel
  static Future<List<int>> exportToExcel({
    required String dataType,
    int? periodId,
  }) async {
    try {
      final params = {
        'format': 'xlsx',
        if (periodId != null) 'period_id': periodId.toString(),
      };

      final uri = Uri.parse('$_baseUrl/$dataType/')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to export Excel: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error exporting Excel: $e';
    }
  }

  // Export data to PDF
  static Future<List<int>> exportToPDF({
    required String dataType,
    int? periodId,
  }) async {
    try {
      final params = {
        'format': 'pdf',
        if (periodId != null) 'period_id': periodId.toString(),
      };

      final uri = Uri.parse('$_baseUrl/$dataType/')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized';
      } else {
        throw 'Failed to export PDF: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error exporting PDF: $e';
    }
  }
}
