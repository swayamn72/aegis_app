import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> get _mobileHeaders => {
    'Content-Type': 'application/json',
    'x-client-type': 'mobile',
  };

  // ============================================
  // CHAT USERS & CONNECTIONS
  // ============================================

  /// Get all users who have chat messages with the current user
  static Future<Map<String, dynamic>> getChatUsers() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/users/with-chats'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch chat users'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // DIRECT MESSAGES
  // ============================================

  /// Get messages between current user and another user (with pagination)
  /// Uses mobile-specific endpoint for pagination support
  static Future<Map<String, dynamic>> getMessages(
      String receiverId, {
        int limit = 50,
        String? before, // ISO timestamp for loading older messages
        String? after, // ISO timestamp for polling new messages
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (before != null) queryParams['before'] = before;
      if (after != null) queryParams['after'] = after;

      // Use mobile-specific endpoint for pagination
      final uri = Uri.parse('$baseUrl/chat/mobile/messages/$receiverId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'error': false,
          'messages': data['messages'] ?? [],
          'hasMore': data['hasMore'] ?? false,
          'nextCursor': data['nextCursor'],
        };
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch messages'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get system messages (notifications, invites, etc.)
  static Future<Map<String, dynamic>> getSystemMessages({
    int limit = 50,
    String? before,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (before != null) queryParams['before'] = before;

      final uri = Uri.parse('$baseUrl/chat/system')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'error': false,
          'messages': data is List ? data : (data['messages'] ?? []),
        };
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch system messages'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get unread message counts per conversation
  /// Uses mobile-specific endpoint
  static Future<Map<String, dynamic>> getUnreadCounts() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/mobile/unread-counts'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to fetch unread counts'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Mark messages as read from a specific sender
  /// Uses mobile-specific endpoint
  static Future<Map<String, dynamic>> markMessagesAsRead(
      String senderId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/mobile/mark-read/$senderId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to mark messages as read'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get all received messages (for inbox/notifications)
  static Future<Map<String, dynamic>> getReceivedMessages() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/received'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch received messages'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // TEAM INVITATIONS (Chat Context)
  // ============================================

  /// Get team invitations for display in chat
  static Future<Map<String, dynamic>> getChatInvitations() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/invitations/for-chat'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch invitations'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Accept team invitation from chat
  static Future<Map<String, dynamic>> acceptTeamInvitation(
      String invitationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/invitations/$invitationId/accept'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to accept invitation'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Decline team invitation from chat
  static Future<Map<String, dynamic>> declineTeamInvitation(
      String invitationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/invitations/$invitationId/decline'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to decline invitation'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // TOURNAMENT TEAM INVITATIONS
  // ============================================

  /// Get tournament invitations for current team
  static Future<Map<String, dynamic>> getTournamentInvitations() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-tournaments/my-team/invitations'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch tournament invitations'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Accept tournament invitation (captain only)
  static Future<Map<String, dynamic>> acceptTournamentInvitation(
      String tournamentId,
      String invitationId,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(
            '$baseUrl/team-tournaments/accept-invitation/$tournamentId/$invitationId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message':
          data['error'] ?? data['message'] ?? 'Failed to accept invitation'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Decline tournament invitation (captain only)
  static Future<Map<String, dynamic>> declineTournamentInvitation(
      String tournamentId,
      String invitationId,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(
            '$baseUrl/team-tournaments/decline-invitation/$tournamentId/$invitationId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ??
              data['message'] ??
              'Failed to decline invitation'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Check if team can register for tournament
  static Future<Map<String, dynamic>> checkTournamentRegistrationEligibility(
      String tournamentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-tournaments/can-register/$tournamentId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to check eligibility'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Register team for open tournament (captain only)
  static Future<Map<String, dynamic>> registerForTournament(
      String tournamentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-tournaments/register/$tournamentId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ??
              data['message'] ??
              'Failed to register for tournament'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Unregister team from tournament (captain only)
  static Future<Map<String, dynamic>> unregisterFromTournament(
      String tournamentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-tournaments/unregister/$tournamentId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? data['message'] ?? 'Failed to unregister'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get tournaments team is participating in
  static Future<Map<String, dynamic>> getMyTeamTournaments() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-tournaments/my-team/tournaments'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch team tournaments'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get open tournaments for registration
  static Future<Map<String, dynamic>> getOpenTournaments() async {
    try {
      final token = await getToken();

      final headers = {..._mobileHeaders};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-tournaments/open-tournaments'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch open tournaments'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // NOTIFICATION & REFERENCE MESSAGES
  // ============================================

  /// Send tournament reference to team captain
  static Future<Map<String, dynamic>> sendTournamentReference(
      String tournamentId,
      String captainId,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/tournament-reference/$tournamentId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'captainId': captainId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to send tournament reference'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Send notification message
  static Future<Map<String, dynamic>> sendNotification({
    required String receiverId,
    required String message,
    String? messageType,
    String? tournamentId,
    String? matchId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final body = <String, dynamic>{
        'receiverId': receiverId,
        'message': message,
      };

      if (messageType != null) body['messageType'] = messageType;
      if (tournamentId != null) body['tournamentId'] = tournamentId;
      if (matchId != null) body['matchId'] = matchId;

      final response = await http.post(
        Uri.parse('$baseUrl/chat/send-notification'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['message'] ?? 'Failed to send notification'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // TRYOUT CHATS
  // ============================================

  /// Get all tryout chats user is part of
  static Future<Map<String, dynamic>> getTryoutChats() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tryout-chats/my-chats'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch tryout chats'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get specific tryout chat with messages
  static Future<Map<String, dynamic>> getTryoutChat(
      String chatId, {
        int limit = 50,
        String? before,
        bool includeParticipants = true,
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'includeParticipants': includeParticipants.toString(),
      };
      if (before != null) queryParams['before'] = before;

      final uri = Uri.parse('$baseUrl/tryout-chats/$chatId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch tryout chat'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get recent messages from tryout chat (lightweight for polling)
  static Future<Map<String, dynamic>> getTryoutChatRecentMessages(
      String chatId, {
        int limit = 20,
        String? after,
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (after != null) queryParams['after'] = after;

      final uri =
      Uri.parse('$baseUrl/tryout-chats/$chatId/messages/recent')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'messages': data['messages'] ?? []};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch messages'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Post a message to tryout chat (HTTP fallback, prefer socket.io)
  static Future<Map<String, dynamic>> postTryoutMessage(
      String chatId,
      String message,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tryout-chats/$chatId/messages'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to post message'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// End tryout (team captain or applicant)
  static Future<Map<String, dynamic>> endTryout(
      String chatId,
      String reason,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tryout-chats/$chatId/end-tryout'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to end tryout'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Send team offer (team captain only)
  static Future<Map<String, dynamic>> sendTeamOffer(
      String chatId,
      String message,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tryout-chats/$chatId/send-offer'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to send team offer'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Accept team offer (applicant only)
  static Future<Map<String, dynamic>> acceptTeamOffer(String chatId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tryout-chats/$chatId/accept-offer'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to accept team offer'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Reject team offer (applicant only)
  static Future<Map<String, dynamic>> rejectTeamOffer(
      String chatId, {
        String? reason,
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tryout-chats/$chatId/reject-offer'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to reject team offer'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // TEAM APPLICATIONS
  // ============================================

  /// Get team applications (captain only) - Summary view for mobile
  static Future<Map<String, dynamic>> getTeamApplicationsSummary(
      String teamId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-applications/team/$teamId/summary'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch applications summary'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get team applications (captain only) - Full details
  static Future<Map<String, dynamic>> getTeamApplications(
      String teamId, {
        bool includeDetails = true,
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final uri = Uri.parse('$baseUrl/team-applications/team/$teamId')
          .replace(queryParameters: {
        'includeDetails': includeDetails.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch applications'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Start tryout for an application (captain only)
  static Future<Map<String, dynamic>> startTryout(String applicationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-applications/$applicationId/start-tryout'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to start tryout'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Reject team application (captain only)
  static Future<Map<String, dynamic>> rejectApplication(
      String applicationId,
      String reason,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-applications/$applicationId/reject'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to reject application'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Accept player to team (captain only)
  static Future<Map<String, dynamic>> acceptPlayer(
      String applicationId,
      String notes,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-applications/$applicationId/accept'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'notes': notes}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to accept player'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get player's own applications
  static Future<Map<String, dynamic>> getMyApplications() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/team-applications/my-applications'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch applications'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Apply to a team
  static Future<Map<String, dynamic>> applyToTeam(
      String teamId, {
        required String message,
        required List<String> appliedRoles,
      }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/team-applications/apply/$teamId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'appliedRoles': appliedRoles,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to submit application'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Withdraw application
  static Future<Map<String, dynamic>> withdrawApplication(
      String applicationId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/team-applications/$applicationId'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to withdraw application'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get teams that are recruiting
  static Future<Map<String, dynamic>> getRecruitingTeams({
    String? game,
    String? region,
    String? role,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final token = await getToken();

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };
      if (game != null) queryParams['game'] = game;
      if (region != null) queryParams['region'] = region;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse('$baseUrl/team-applications/recruiting-teams')
          .replace(queryParameters: queryParams);

      final headers = {..._mobileHeaders};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch recruiting teams'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get players looking for teams
  static Future<Map<String, dynamic>> getPlayersLookingForTeam({
    String? game,
    String? region,
    String? role,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final token = await getToken();

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };
      if (game != null) queryParams['game'] = game;
      if (region != null) queryParams['region'] = region;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse('$baseUrl/team-applications/looking-for-team')
          .replace(queryParameters: queryParams);

      final headers = {..._mobileHeaders};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch players'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // RECRUITMENT APPROACHES
  // ============================================

  /// Get recruitment approaches for current player
  static Future<Map<String, dynamic>> getRecruitmentApproaches() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/recruitment/my-approaches'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch recruitment approaches'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Accept recruitment approach
  static Future<Map<String, dynamic>> acceptRecruitmentApproach(
      String approachId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/recruitment/approach/$approachId/accept'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to accept approach'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Reject recruitment approach
  static Future<Map<String, dynamic>> rejectRecruitmentApproach(
      String approachId,
      String reason,
      ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': true, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/recruitment/approach/$approachId/reject'),
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to reject approach'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ============================================
  // TOURNAMENT DETAILS (for chat references)
  // ============================================

  /// Get tournament details by ID
  static Future<Map<String, dynamic>> getTournamentDetails(
      String tournamentId) async {
    try {
      final token = await getToken();

      final headers = {..._mobileHeaders};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data};
      } else {
        return {
          'error': true,
          'message': data['error'] ?? 'Failed to fetch tournament details'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }
}