import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

class OtpResponse {
  final bool success;
  final String? message;
  final String? error;

  OtpResponse({required this.success, this.message, this.error});
}

class VerifyOtpResponse {
  final bool success;
  final String? message;
  final String? error;

  VerifyOtpResponse({required this.success, this.message, this.error});
}

class ResetPasswordResponse {
  final bool success;
  final String? message;
  final String? error;

  ResetPasswordResponse({required this.success, this.message, this.error});
}

Future<OtpResponse> sendOtp(String email) async {
  try {
    final response = await http.post(
      Uri.parse(createApiUrl('sendotp/')), // Adjusted path based on original file, removing leading slash if needed in createApiUrl logic, but here following TS
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body);
    return response.statusCode >= 200 && response.statusCode < 300
        ? OtpResponse(success: true, message: data['message'])
        : OtpResponse(success: false, error: data['message'] ?? "Failed to send OTP");
  } catch (err) {
    return OtpResponse(success: false, error: err.toString());
  }
}

Future<VerifyOtpResponse> verifyOtp(String email, String otp) async {
  try {
    final response = await http.post(
      Uri.parse(createApiUrl('verifyotp/')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300 || data['error'] != null) {
      return VerifyOtpResponse(
        success: false,
        error: data['error'] ?? data['message'] ?? "OTP verification failed",
      );
    }

    return VerifyOtpResponse(
      success: true,
      message: data['message'] ?? "OTP verified successfully",
    );
  } catch (err) {
    return VerifyOtpResponse(success: false, error: err.toString());
  }
}

Future<ResetPasswordResponse> resetPassword(
  String email,
  String otp,
  String newPassword,
  String confirmPassword,
) async {
  try {
    final response = await http.post(
      Uri.parse(createApiUrl('resetpassword/')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );

    final data = jsonDecode(response.body);

    return response.statusCode >= 200 && response.statusCode < 300
        ? ResetPasswordResponse(success: true, message: data['message'])
        : ResetPasswordResponse(success: false, error: data['error'] ?? "Reset failed");
  } catch (err) {
    return ResetPasswordResponse(success: false, error: err.toString());
  }
}
