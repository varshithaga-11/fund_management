import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../access/access.dart';

class UserRegister {
  final int? id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final bool isActive;
  final int? createdBy;
  final String? password;

  UserRegister({
    this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.isActive = true,
    this.createdBy,
    this.password,
  });

  factory UserRegister.fromJson(Map<String, dynamic> json) {
    return UserRegister(
      id: json['id'],
      username: json['username'] ?? 'Unknown',
      email: json['email'] ?? 'No Email',
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'] ?? 'employee', // Default to employee if null
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
      'created_by': createdBy,
    };
    if (includePassword && password != null) {
      data['password'] = password;
    }
    return data;
  }
}

Future<int?> getUserIdFromToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access');
  if (token != null && !JwtDecoder.isExpired(token)) {
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['user_id'];
  }
  return null;
}

Future<List<UserRegister>> getUserList({int? createdBy}) async {
  String path = 'api/usermanagement/';
  if (createdBy != null) {
    path += '?created_by=$createdBy';
  }
  
  final url = createApiUrl(path);
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => UserRegister.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}

Future<UserRegister> createUser(UserRegister user) async {
  final url = createApiUrl('app/usermanagement/');
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(user.toJson(includePassword: true)),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return UserRegister.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create user: ${response.body}');
  }
}

Future<UserRegister> getUserById(int id) async {
  final url = createApiUrl('api/usermanagement/$id/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    return UserRegister.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load user $id');
  }
}

Future<UserRegister> updateUser(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/usermanagement/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return UserRegister.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update user: ${response.body}');
  }
}

Future<void> deleteUser(int id) async {
  final url = createApiUrl('api/usermanagement/$id/');
  final response = await http.delete(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Failed to delete user');
  }
}
