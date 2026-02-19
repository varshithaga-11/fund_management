import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../access/access.dart';

class LoginCredentials {
  final String username;
  final String password;

  LoginCredentials({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class LoginResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final String? error;
  final dynamic details;
  final String? userRole;

  LoginResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.details,
    this.userRole,
  });
}

Future<LoginResponse> loginUser(LoginCredentials credentials) async {
  try {
    final response = await http.post(
      Uri.parse(createApiUrl('api/login/')),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(credentials.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && data['tokens'] != null && data['tokens']['access'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', data['tokens']['access']);
      await prefs.setString('refresh', data['tokens']['refresh']);

      String userRole = 'user'; // Default
      if (data['tokens']['userRole'] != null) {
        userRole = data['tokens']['userRole'];
      } else {
        try {
           Map<String, dynamic> decodedToken = JwtDecoder.decode(data['tokens']['access']);
           if (decodedToken.containsKey('role')) {
             userRole = decodedToken['role'];
           }
        } catch (e) {
          print('Error decoding token: $e');
        }
      }
      
      await prefs.setString('userRole', userRole);

      return LoginResponse(
        success: true,
        data: data,
        message: data['message'] ?? 'Login successful',
        userRole: userRole,
      );
    } else {
      return LoginResponse(
        success: false,
        error: data['message'] ?? 'Invalid credentials',
        details: data,
      );
    }
  } catch (error) {
    print('Login API Error: $error');
    return LoginResponse(
      success: false,
      error: 'Network error occurred',
      details: error.toString(),
    );
  }
}
