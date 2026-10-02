import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище JWT-токенов (access + refresh) между запусками приложения.
class TokenStorage {
  TokenStorage._();

  static const _accessKey = 'fs_access_token';
  static const _refreshKey = 'fs_refresh_token';
  static const _expiryKey = 'fs_access_expiry';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_expiryKey, expiresAt.toIso8601String());
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey) != null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_expiryKey);
  }
}
