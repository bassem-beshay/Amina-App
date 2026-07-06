import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'secure_storage_service.dart';  // 🔒 SECURITY: Import secure storage

class StorageService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRememberedEmail = 'remembered_email';

  // 🔒 SECURITY FIX: Auth Token moved to Secure Storage (encrypted)
  // Save Auth Token
  static Future<bool> saveAuthToken(String token) async {
    try {
      await SecureStorageService.saveAuthToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get Auth Token
  static Future<String?> getAuthToken() async {
    try {
      return await SecureStorageService.getAuthToken();
    } catch (e) {
      return null;
    }
  }

  // Save User Data
  // 🔒 SECURITY FIX: User data moved to Secure Storage (encrypted)
  static Future<bool> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await SecureStorageService.saveUserData(userJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get User Data
  // 🔒 SECURITY FIX: User data retrieved from Secure Storage (encrypted)
  static Future<User?> getUser() async {
    try {
      final userJson = await SecureStorageService.getUserData();
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Set Login Status
  static Future<bool> setLoggedIn(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyIsLoggedIn, value);
    } catch (e) {
      return false;
    }
  }

  // Check if Logged In
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clear All Data (Logout)
  // 🔒 SECURITY FIX: Also clear Secure Storage on logout
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear SharedPreferences
      await prefs.remove(_keyAuthToken);  // Note: Token is now in SecureStorage, this is legacy
      await prefs.remove(_keyUser);       // Note: User data is now in SecureStorage, this is legacy
      await prefs.setBool(_keyIsLoggedIn, false);

      // 🔒 SECURITY: Clear all secure storage (token + user data)
      await SecureStorageService.clearAll();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Save a generic key-value pair
  static Future<bool> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      return false;
    }
  }

  // Get a generic string value
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  // ==================== Remember Me Functions ====================

  // Save Remember Me status
  static Future<bool> setRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyRememberMe, value);
    } catch (e) {
      return false;
    }
  }

  // Get Remember Me status
  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      return false;
    }
  }

  // 🔒 SECURITY FIX: Remembered Email moved to Secure Storage (encrypted)
  // Save Remembered Email
  static Future<bool> saveRememberedEmail(String email) async {
    try {
      await SecureStorageService.saveRememberedEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get Remembered Email
  static Future<String?> getRememberedEmail() async {
    try {
      return await SecureStorageService.getRememberedEmail();
    } catch (e) {
      return null;
    }
  }

  // Save Remembered Phone
  static Future<bool> saveRememberedPhone(String phone) async {
    try {
      await SecureStorageService.saveRememberedPhone(phone);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get Remembered Phone
  static Future<String?> getRememberedPhone() async {
    try {
      return await SecureStorageService.getRememberedPhone();
    } catch (e) {
      return null;
    }
  }

  // Clear Remember Me data
  static Future<bool> clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      // 🔒 SECURITY: Also clear from SecureStorage
      await SecureStorageService.deleteRememberedEmail();
      await SecureStorageService.deleteRememberedPhone();
      return true;
    } catch (e) {
      return false;
    }
  }
}
