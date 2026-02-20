import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

class RatioBenchmarksResponse {
  final Map<String, double?> benchmarks;
  final Map<String, String> labels;
  final List<String> keysOrder;

  RatioBenchmarksResponse({
    required this.benchmarks,
    required this.labels,
    required this.keysOrder,
  });

  factory RatioBenchmarksResponse.fromJson(Map<String, dynamic> json) {
    Map<String, double?> benchmarks = {};
    if (json['benchmarks'] != null) {
      (json['benchmarks'] as Map<String, dynamic>).forEach((key, value) {
        benchmarks[key] = value != null ? (value as num).toDouble() : null;
      });
    }

    Map<String, String> labels = {};
    if (json['labels'] != null) {
      (json['labels'] as Map<String, dynamic>).forEach((key, value) {
        labels[key] = value.toString();
      });
    }

    List<String> keysOrder = [];
    if (json['keys_order'] != null) {
      keysOrder = List<String>.from(json['keys_order']);
    }

    return RatioBenchmarksResponse(
      benchmarks: benchmarks,
      labels: labels,
      keysOrder: keysOrder,
    );
  }
}

Future<RatioBenchmarksResponse> getRatioBenchmarks() async {
  final url = createApiUrl('api/ratio-benchmarks/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    return RatioBenchmarksResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch ratio benchmarks');
  }
}

Future<Map<String, dynamic>> updateRatioBenchmarks(
    Map<String, double?> benchmarks) async {
  final url = createApiUrl('api/ratio-benchmarks/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode({'benchmarks': benchmarks}),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to update ratio benchmarks');
  }
}
