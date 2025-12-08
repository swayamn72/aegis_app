import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class MobileApi {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch mobile-optimized current user profile (GET /mobile/me)
  // Returns parsed JSON map on success, throws Exception on error.
  static Future<Map<String, dynamic>> getMobileProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('$baseUrl/mobile/me');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      try {
        final body = json.decode(response.body);
        final msg = body is Map && body['message'] != null
            ? body['message'].toString()
            : response.body;
        throw Exception('Failed to fetch mobile profile: $msg');
      } catch (_) {
        throw Exception('Failed to fetch mobile profile: ${response.statusCode} ${response.body}');
      }
    }
  }

  /// Sync user profile - returns UserModel instead of raw JSON
  /// This is the preferred method to use with UserProvider
  static Future<UserModel> syncUserProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final uri = Uri.parse('$baseUrl/mobile/me');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      try {
        final body = json.decode(response.body);
        final msg = body is Map && body['message'] != null
            ? body['message'].toString()
            : response.body;
        throw Exception('Failed to sync profile: $msg');
      } catch (_) {
        throw Exception('Failed to sync profile: ${response.statusCode}');
      }
    }
  }
}
