import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Centralized API Service
class ApiService {
  // Base URL - change this once when deploying
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  // Get saved token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // GET Profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/players/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch profile'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // GET Connections
  static Future<Map<String, dynamic>> getConnections() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/connections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {'error': true, 'message': 'Failed to fetch connections'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // GET Team by ID
  static Future<Map<String, dynamic>> getTeam(String teamId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {'error': true, 'message': 'Failed to fetch team'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Login failed. Try again.'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }
}
