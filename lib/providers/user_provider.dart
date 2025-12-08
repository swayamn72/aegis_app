import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/mobile_api.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUser => _currentUser != null;

  // Quick accessors
  String? get username => _currentUser?.username;
  String? get email => _currentUser?.email;
  String? get profilePicture => _currentUser?.profilePicture;
  String? get primaryGame => _currentUser?.primaryGame;
  int? get aegisRating => _currentUser?.aegisRating;
  Team? get team => _currentUser?.team;
  bool get hasTeam => _currentUser?.team != null;

  /// Load user profile (from cache first, then API)
  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Load from local storage (instant display)
      if (!forceRefresh) {
        final cachedUser = await LocalStorageService.getUserProfile();
        if (cachedUser != null) {
          _currentUser = cachedUser;
          notifyListeners();
        }
      }

      // Step 2: Check if we need to refresh from API
      final needsRefresh = await LocalStorageService.needsRefresh();

      if (forceRefresh || needsRefresh || _currentUser == null) {
        // Fetch fresh data from API
        final userProfile = await MobileApi.syncUserProfile();
        _currentUser = userProfile;

        // Save to local storage
        await LocalStorageService.saveUserProfile(userProfile);

        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user profile: $e');

      // If we have cached data, keep showing it despite the error
      if (_currentUser == null) {
        // Only show error if we have no data at all
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile (after editing, etc.)
  Future<void> updateUserProfile(UserModel user) async {
    _currentUser = user;
    await LocalStorageService.saveUserProfile(user);
    notifyListeners();
  }

  /// Update specific user fields
  Future<void> updateUserFields(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    // Create updated user with new fields
    final updatedJson = {..._currentUser!.toJson(), ...updates};
    final updatedUser = UserModel.fromJson(updatedJson);

    await updateUserProfile(updatedUser);
  }

  /// Update team data
  Future<void> updateTeam(Team? team) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(team: team);
    await updateUserProfile(updatedUser);
  }

  /// Clear user profile (on logout)
  Future<void> clearUserProfile() async {
    _currentUser = null;
    _error = null;
    await LocalStorageService.clearUserProfile();
    notifyListeners();
  }

  /// Refresh profile from API
  Future<void> refresh() async {
    await loadUserProfile(forceRefresh: true);
  }

  /// Silent refresh (no loading state change)
  Future<void> silentRefresh() async {
    try {
      final userProfile = await MobileApi.syncUserProfile();
      _currentUser = userProfile;
      await LocalStorageService.saveUserProfile(userProfile);
      notifyListeners();
    } catch (e) {
      debugPrint('Silent refresh failed: $e');
      // Don't update error state for silent refresh
    }
  }
}

