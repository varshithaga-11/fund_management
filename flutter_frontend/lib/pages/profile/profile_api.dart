import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../access/access.dart';

class UserProfileData {
  final String firstName;
  final String lastName;
  final String username;
  final String email;

  UserProfileData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
    };
  }
  
  UserProfileData copyWith({
      String? firstName,
      String? lastName,
      String? username,
      String? email,
  }) {
    return UserProfileData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }
}

Future<String?> getUserIdFromToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access');
  if (token == null) return null;
  try {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    return decodedToken['user_id'].toString();
  } catch (e) {
    return null;
  }
}

Future<UserProfileData> getUserProfile() async {
  final userId = await getUserIdFromToken();
  if (userId == null) throw Exception('User is not logged in');

  final url = createApiUrl('api/profile/$userId/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    return UserProfileData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load profile');
  }
}

Future<UserProfileData> updateUserProfile(UserProfileData data) async {
  final userId = await getUserIdFromToken();
  if (userId == null) throw Exception('User is not logged in');

  final url = createApiUrl('api/profile/$userId/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data.toJson()),
  );

  if (response.statusCode == 200) {
    return UserProfileData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update profile: ${response.body}');
  }
}
