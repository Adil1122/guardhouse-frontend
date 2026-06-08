import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  // Save user data as JSON
  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(userJson);
    await prefs.setString(_userKey, encoded);
  }

  // Get current user as JSON
  Future<Map<String, dynamic>?> getCurrentUserJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        return json.decode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear user data
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get auth token (alias for getToken)
  Future<String?> getAuthToken() async {
    return await getToken();
  }

  // Clear auth token (alias for remove)
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
