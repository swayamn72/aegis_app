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

  static Future<Map<String, dynamic>> signup(String email, String password,
      String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'error': true,
          'message': jsonDecode(response.body)['message'] ?? 'Signup failed'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email,
      String password) async {
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

  static Future<Map<String, dynamic>> getTournaments({
    int page = 1,
    int limit = 50,
    String? game,
    String? region,
    String? status,
    String? tier,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (game != null && game.isNotEmpty) queryParams['game'] = game;
      if (region != null && region.isNotEmpty) queryParams['region'] = region;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (tier != null && tier.isNotEmpty) queryParams['tier'] = tier;

      final uri = Uri.parse('$baseUrl/tournaments/all').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'error': false,
          'tournaments': data['tournaments'],
          'liveTournaments': data['liveTournaments'],
          'upcomingTournaments': data['upcomingTournaments'],
          'pagination': data['pagination'],
        };
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch tournaments',
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }
}