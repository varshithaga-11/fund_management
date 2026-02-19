import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Const for API_URL. Adjust as needed for your environment.
// For Android emulator, use 10.0.2.2. For iOS/Web, use localhost or 127.0.0.1.
const String API_URL = "http://127.0.0.1:8000/"; 

String createApiUrl(String path) {
  return "$API_URL$path";
}

Future<Map<String, String>> getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access');
  String? refreshToken = prefs.getString('refresh');
  
  print("access token $accessToken");
  print("refresh token $refreshToken");

  if (isAccessTokenExpired(accessToken)) {
    try {
      final newAccessToken = await refreshAccessToken(refreshToken);
      accessToken = newAccessToken;
      await prefs.setString('access', newAccessToken);
    } catch (e) {
      print("Error refreshing token: $e");
      // Handle error, maybe clear tokens or redirect to login
    }
  }

  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };
}

Future<Map<String, String>> getAuthHeadersFile() async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access');
  String? refreshToken = prefs.getString('refresh');

  if (isAccessTokenExpired(accessToken)) {
    try {
      final newAccessToken = await refreshAccessToken(refreshToken);
      accessToken = newAccessToken;
      await prefs.setString('access', newAccessToken);
    } catch (e) {
      print("Error refreshing token: $e");
    }
  }

  return {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $accessToken',
  };
}

bool isAccessTokenExpired(String? accessToken) {
  if (accessToken == null) {
    return true;
  }

  try {
    return JwtDecoder.isExpired(accessToken);
  } catch (error) {
    return true;
  }
}

Future<String> refreshAccessToken(String? refreshToken) async {
  if (refreshToken == null) {
    throw Exception('No refresh token available');
  }

  try {
    final refreshUrl = Uri.parse(createApiUrl('api/token/refresh/'));
    
    final response = await http.post(
      refreshUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh': refreshToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh access token');
    }

    final data = jsonDecode(response.body);
    final createAccessToken = data['access']; 

    if (createAccessToken == null) {
      throw Exception('No access token received in response');
    }
    
    return createAccessToken;
  } catch (error) {
    rethrow;
  }
}
