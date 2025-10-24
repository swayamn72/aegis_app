import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Existing methods (signup, login, etc.)
  static Future<Map<String, dynamic>> signup(
      String email, String password, String username) async {
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

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
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

  // NEW: Update Profile
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/players/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to update profile',
          'errors': data['errors']
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // NEW: Upload Profile Picture
  static Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/players/upload-pfp'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'profilePicture',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to upload profile picture'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // Existing methods continue...
  static Future<Map<String, dynamic>> getConnections() async {
    try {
      final token = await getToken();
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

  static Future<Map<String, dynamic>> getTeam(String teamId) async {
    try {
      final token = await getToken();
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

  static Future<Map<String, dynamic>> getAllTournaments({
    int page = 1,
    int limit = 50,
    String? game,
    String? region,
    String? status,
    String? tier,
  }) async {
    try {
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
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch tournaments'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLiveTournaments({int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/tournaments/live').replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch live tournaments'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUpcomingTournaments({int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/tournaments/upcoming').replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch upcoming tournaments'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTournamentById(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch tournament details'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // Lightweight tournament summary for initial load
  static Future<Map<String, dynamic>> getTournamentSummary(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId/summary'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch tournament summary'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

// Full tournament details with mobile optimization
  static Future<Map<String, dynamic>> getTournamentDetails(
      String tournamentId, {
        bool includeMatches = false,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl/tournaments/$tournamentId').replace(
        queryParameters: {
          'mobile': 'true',
          'includeMatches': includeMatches.toString(),
        },
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? data['error'] ?? 'Failed to fetch tournament details'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

// Get matches with pagination
  static Future<Map<String, dynamic>> getTournamentMatches(
      String tournamentId, {
        int limit = 20,
        int offset = 0,
        String? status,
        String? phase,
      }) async {
    try {
      final queryParams = <String, String>{
        'mobile': 'true',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (phase != null) queryParams['phase'] = phase;

      final uri = Uri.parse('$baseUrl/matches/tournament/$tournamentId').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch matches'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

// Check registration status
  static Future<Map<String, dynamic>> checkTournamentRegistration(String tournamentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teams/registration-status/$tournamentId'),
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
          'message': data['message'] ?? 'Failed to check registration status'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }
}