import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyEmail = 'auth_email';
  static const _keyName = 'auth_name';
  static const _keyPassword = 'auth_password';
  static const _keyLoggedIn = 'auth_logged_in';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // Returns 'success' or an error message.
  Future<String> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final existingEmail = prefs.getString(_keyEmail);
    if (existingEmail != null && existingEmail == email) {
      return 'An account with this email already exists.';
    }

    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyLoggedIn, true);
    return 'success';
  }

  // Returns 'success' or an error message.
  Future<String> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final storedEmail = prefs.getString(_keyEmail);
    final storedPassword = prefs.getString(_keyPassword);

    if (storedEmail == null) {
      return 'No account found. Please create one first.';
    }

    if (storedEmail != email || storedPassword != password) {
      return 'Wrong email or password.';
    }

    await prefs.setBool(_keyLoggedIn, true);
    return 'success';
  }

  // Called after a successful Google Sign-In — no password is stored.
  Future<void> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyLoggedIn, true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }
}
