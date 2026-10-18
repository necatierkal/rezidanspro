import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyAccessToken = 'rp_access_token';
  static const String keyRefreshToken = 'rp_refresh_token';
  static const String keyUserId = 'rp_user_id';
  static const String keyUserEmail = 'rp_user_email';
  static const String keyUserRole = 'rp_user_role';
  static const String keySelectedCommunityId = 'rp_selected_community_id';
  static const String keyThemeMode = 'rp_theme_mode'; // light, dark, system
  static const String keyLanguage = 'rp_language'; // tr, en
  static const String keyCustomServerUrl = 'rp_custom_server_url';
  static const String keyIsDemoMode = 'rp_is_demo_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Tokens & User
  String? get accessToken => _prefs.getString(keyAccessToken);
  String? get refreshToken => _prefs.getString(keyRefreshToken);
  int? get userId => _prefs.getInt(keyUserId);
  String? get userEmail => _prefs.getString(keyUserEmail);
  String? get userRole => _prefs.getString(keyUserRole);

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String email,
    required String role,
  }) async {
    await _prefs.setString(keyAccessToken, accessToken);
    await _prefs.setString(keyRefreshToken, refreshToken);
    await _prefs.setInt(keyUserId, userId);
    await _prefs.setString(keyUserEmail, email);
    await _prefs.setString(keyUserRole, role);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(keyAccessToken);
    await _prefs.remove(keyRefreshToken);
    await _prefs.remove(keyUserId);
    await _prefs.remove(keyUserEmail);
    await _prefs.remove(keyUserRole);
    await _prefs.remove(keySelectedCommunityId);
  }

  // Active Community
  int? get selectedCommunityId => _prefs.getInt(keySelectedCommunityId);
  Future<void> setSelectedCommunityId(int id) async {
    await _prefs.setInt(keySelectedCommunityId, id);
  }

  // Theme & Language
  String get themeMode => _prefs.getString(keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  String get language => _prefs.getString(keyLanguage) ?? 'tr';
  Future<void> setLanguage(String lang) async {
    await _prefs.setString(keyLanguage, lang);
  }

  // Custom Server & Offline Demo
  String? get customServerUrl => _prefs.getString(keyCustomServerUrl);
  Future<void> setCustomServerUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(keyCustomServerUrl);
    } else {
      await _prefs.setString(keyCustomServerUrl, url.trim());
    }
  }

  bool get isDemoMode => _prefs.getBool(keyIsDemoMode) ?? false;
  Future<void> setIsDemoMode(bool isDemo) async {
    await _prefs.setBool(keyIsDemoMode, isDemo);
  }
}
