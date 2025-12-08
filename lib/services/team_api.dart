import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeamApi{
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static Future<String?> getToken() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch team by id (GET /team/:id)
  // Returns parsed JSON map on success, null if 404, throws Exception on other errors.
  static Future<Map<String, dynamic>?> getTeamById(String id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/team/$id');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch team: ${response.statusCode} ${response.body}');
    }
  }

  // Create a new team (POST /teams)
  // payload keys: teamName (required), teamTag (optional), primaryGame, region, bio, logo
  // Returns parsed JSON map with created team on success (statusCode 201).
  static Future<Map<String, dynamic>> createTeam(Map<String, dynamic> payload) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/teams');

    // Normalize teamTag to uppercase if provided
    final bodyMap = Map<String, dynamic>.from(payload);
    if (bodyMap.containsKey('teamTag') && bodyMap['teamTag'] is String) {
      final tag = (bodyMap['teamTag'] as String).trim();
      if (tag.isNotEmpty) {
        bodyMap['teamTag'] = tag.toUpperCase();
      } else {
        bodyMap.remove('teamTag');
      }
    }

    // Remove null or empty string values to avoid backend validation issues
    bodyMap.removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(uri, headers: headers, body: json.encode(bodyMap));

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400) {
      // Return backend validation message if available
      try {
        final body = json.decode(response.body);
        final msg = body is Map && body['message'] != null ? body['message'].toString() : response.body;
        throw Exception('Validation error creating team: $msg');
      } catch (_) {
        throw Exception('Validation error creating team: ${response.body}');
      }
    } else {
      throw Exception('Failed to create team: ${response.statusCode} ${response.body}');
    }
  }



  // Accept a team invitation (POST /teams/invitations/:id/accept)
  // Returns parsed JSON map on success.
  static Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/teams/invitations/$invitationId/accept');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
      try {
        final body = json.decode(response.body);
        final msg = body is Map && body['message'] != null ? body['message'].toString() : response.body;
        throw Exception('Error accepting invitation: $msg');
      } catch (_) {
        throw Exception('Error accepting invitation: ${response.body}');
      }
    } else {
      throw Exception('Failed to accept invitation: ${response.statusCode} ${response.body}');
    }
  }

  // Decline a team invitation (POST /teams/invitations/:id/decline)
  // Returns parsed JSON map on success.
  static Future<Map<String, dynamic>> declineInvitation(String invitationId) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/teams/invitations/$invitationId/decline');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
      try {
        final body = json.decode(response.body);
        final msg = body is Map && body['message'] != null ? body['message'].toString() : response.body;
        throw Exception('Error declining invitation: $msg');
      } catch (_) {
        throw Exception('Error declining invitation: ${response.body}');
      }
    } else {
      throw Exception('Failed to decline invitation: ${response.statusCode} ${response.body}');
    }
  }
}