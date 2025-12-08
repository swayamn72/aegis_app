import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _userProfileKey = 'user_profile';
  static const String _lastSyncKey = 'last_sync_time';

  /// Save user profile to local storage
  static Future<bool> saveUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(user.toJson());
      await prefs.setString(_userProfileKey, jsonString);
      await updateLastSyncTime();
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  /// Get user profile from local storage
  static Future<UserModel?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userProfileKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Clear user profile from local storage
  static Future<bool> clearUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_lastSyncKey);
      return true;
    } catch (e) {
      print('Error clearing user profile: $e');
      return false;
    }
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);

      if (timestamp == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Update last sync time to now
  static Future<bool> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastSyncKey, now);
      return true;
    } catch (e) {
      print('Error updating last sync time: $e');
      return false;
    }
  }

  /// Check if profile needs refresh (older than specified duration)
  static Future<bool> needsRefresh({Duration maxAge = const Duration(minutes: 5)}) async {
    final lastSync = await getLastSyncTime();

    if (lastSync == null) {
      return true;
    }

    return DateTime.now().difference(lastSync) > maxAge;
  }
}

