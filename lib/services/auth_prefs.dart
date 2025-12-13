import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _keyUserId = 'userId';
  static const _keyUserEmail = 'userEmail';

  static Future<void> saveUser({
    required String id,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyUserId);
    final email = prefs.getString(_keyUserEmail);
    if (id != null && email != null) {
      return {'id': id, 'email': email};
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
  }
}
