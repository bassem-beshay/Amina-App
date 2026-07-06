import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // 🔒 SECURITY: Using AES-GCM instead of AES-CBC to prevent Padding Oracle attacks
  // AES-GCM provides authenticated encryption with built-in integrity checking
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // 🔐 SECURITY FIX: Use AES/GCM/NoPadding instead of default AES/CBC/PKCS7Padding
      // This prevents Padding Oracle attacks (OWASP M5: Insufficient Cryptography)
      // Reference: https://github.com/mogol/flutter_secure_storage/issues/526
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keyAuthToken = 'secure_auth_token';
  static const String _keyUserData = 'secure_user_data';  // 🔒 SECURITY: Store user data encrypted
  static const String _keyRememberedEmail = 'secure_remembered_email';  // 🔒 SECURITY: Store email encrypted
  static const String _keyRememberedPhone = 'secure_remembered_phone';  // 🔒 SECURITY: Store phone encrypted

  // ==================== Auth Token Functions ====================

  static Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAuthToken);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteAuthToken() async {
    try {
      await _storage.delete(key: _keyAuthToken);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== User Data Functions ====================
  // 🔒 SECURITY FIX: User data contains sensitive info and should be encrypted

  static Future<void> saveUserData(String userJson) async {
    try {
      await _storage.write(key: _keyUserData, value: userJson);
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _keyUserData);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: _keyUserData);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Remembered Email Functions ====================
  // 🔒 SECURITY FIX: Remembered email should be encrypted

  static Future<void> saveRememberedEmail(String email) async {
    try {
      await _storage.write(key: _keyRememberedEmail, value: email);
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getRememberedEmail() async {
    try {
      return await _storage.read(key: _keyRememberedEmail);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteRememberedEmail() async {
    try {
      await _storage.delete(key: _keyRememberedEmail);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Remembered Phone Functions ====================

  static Future<void> saveRememberedPhone(String phone) async {
    try {
      await _storage.write(key: _keyRememberedPhone, value: phone);
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getRememberedPhone() async {
    try {
      return await _storage.read(key: _keyRememberedPhone);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteRememberedPhone() async {
    try {
      await _storage.delete(key: _keyRememberedPhone);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Clear All ====================

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      rethrow;
    }
  }
}
