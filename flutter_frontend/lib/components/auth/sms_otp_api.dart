import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../access/access.dart';

class SendOTPData {
  final String phoneNumber;

  SendOTPData({required this.phoneNumber});

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
      };
}

class VerifyOTPData {
  final String phoneNumber;
  final String otp;

  VerifyOTPData({required this.phoneNumber, required this.otp});

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'otp': otp,
      };
}

class SMSOTPResponse {
  final bool success;
  final String? status;
  final String? message;
  final dynamic data;
  final String? error;
  final dynamic details;
  final String? phoneNumber;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final int? remainingAttempts;
  final String? userRole;

  SMSOTPResponse({
    required this.success,
    this.status,
    this.message,
    this.data,
    this.error,
    this.details,
    this.phoneNumber,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.remainingAttempts,
    this.userRole,
  });
}

Future<SMSOTPResponse> sendSMSOTP(SendOTPData otpData) async {
  try {
    print('Attempting to send OTP with data: ${otpData.toJson()}');
    print('API URL: ${createApiUrl('sms-otp/send/')}');

    final response = await http.post(
      Uri.parse(createApiUrl('sms-otp/send/')),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(otpData.toJson()),
    );

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');

    final data = jsonDecode(response.body);
    print('Response data: $data');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SMSOTPResponse(
        success: true,
        data: data,
        message: data['message'] ?? 'OTP sent successfully',
        phoneNumber: data['phone_number'],
      );
    } else {
      return SMSOTPResponse(
        success: false,
        error: data['error'] ?? 'Failed to send OTP',
        details: data['error'],
      );
    }
  } catch (error) {
    print('Send OTP API Error: $error');
    return SMSOTPResponse(
      success: false,
      error: 'Network error occurred: $error',
      details: error.toString(),
    );
  }
}

Future<SMSOTPResponse> verifySMSOTP(VerifyOTPData verifyData) async {
  try {
    print('Attempting to verify OTP with data: ${verifyData.toJson()}');
    print('API URL: ${createApiUrl('sms-otp/verify/')}');

    final response = await http.post(
      Uri.parse(createApiUrl('sms-otp/verify/')),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(verifyData.toJson()),
    );

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');

    final data = jsonDecode(response.body);
    print('Response data: $data');

    if (response.statusCode >= 200 && response.statusCode < 300) {
       final prefs = await SharedPreferences.getInstance();
      // Store tokens in shared_preferences
      final accessToken = data['tokens'] != null ? data['tokens']['access'] : data['access_token'];
      final refreshToken = data['tokens'] != null ? data['tokens']['refresh'] : data['refresh_token'];

      if (accessToken != null) {
        await prefs.setString('access', accessToken);
        print('Access token stored in shared_preferences');
      }
      if (refreshToken != null) {
        await prefs.setString('refresh', refreshToken);
        print('Refresh token stored in shared_preferences');
      }

      // Decode JWT to get user role
      String userRole = 'admin'; // default
      if (accessToken != null) {
        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
          if (decodedToken.containsKey('role')) {
            userRole = decodedToken['role'];
          }
          print('Decoded user role from JWT: $userRole');
        } catch (error) {
          print('Error decoding JWT: $error');
          // fallback
          if (data['user'] != null && data['user']['role'] != null) {
             userRole = data['user']['role'];
          }
        }
      }
      
      return SMSOTPResponse(
        success: true,
        data: data,
        message: data['message'] ?? 'OTP verified successfully',
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: data['user'],
        userRole: userRole,
      );
    } else {
      return SMSOTPResponse(
        success: false,
        error: data['error'] ?? 'Failed to verify OTP',
        details: data['error'],
        remainingAttempts: data['remaining_attempts'],
      );
    }
  } catch (error) {
    print('Verify OTP API Error: $error');
    return SMSOTPResponse(
      success: false,
      error: 'Network error occurred: $error',
      details: error.toString(),
    );
  }
}
