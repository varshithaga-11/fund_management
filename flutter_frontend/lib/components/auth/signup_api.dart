import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

class UserData {
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final String passwordConfirm;
  final String role;

  UserData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'username': username,
        'password': password,
        'password_confirm': passwordConfirm,
        'role': role,
      };
}

class ApiResponse {
  final bool success;
  final String? status;
  final String? message;
  final dynamic data;
  final String? error;
  final dynamic details;

  ApiResponse({
    required this.success,
    this.status,
    this.message,
    this.data,
    this.error,
    this.details,
  });
}

Future<ApiResponse> registerUser(UserData userData) async {
  try {
    print('Attempting to register user with data: ${userData.toJson()}');
    print('API URL: ${createApiUrl('api/register/')}');

    final response = await http.post(
      Uri.parse(createApiUrl('api/register/')),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData.toJson()),
    );

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');

    final data = jsonDecode(response.body);
    print('Response data: $data');

    if (response.statusCode >= 200 && response.statusCode < 300 && data['status'] == 'success') {
      return ApiResponse(
        success: true,
        data: data,
        message: data['message'] ?? 'User registered successfully',
      );
    } else {
      return ApiResponse(
        success: false,
        error: data['message'] ?? 'Registration failed',
        details: data['message'],
      );
    }
  } catch (error) {
    print('Registration API Error: $error');
    return ApiResponse(
      success: false,
      error: 'Network error occurred: $error',
      details: error.toString(),
    );
  }
}
