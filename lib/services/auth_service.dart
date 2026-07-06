// ...existing code...
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'secure_storage_service.dart'; // 🔒 SECURITY FIX: Use secure storage for tokens
import 'google_auth_service.dart';

class AuthService {
  // Register Client
  static Future<AuthResult> registerClient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.registerClient,
        body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        },
      );

      if (response.success && response.rawResponse != null) {
        // Check if email verification is required
        final requiresVerification = response.rawResponse!['requires_verification'] as bool? ?? false;

        if (requiresVerification) {
          // Account created but needs email verification
          return AuthResult(
            success: true,
            message: 'Account created. Please verify your email',
            requiresVerification: true,
            email: email,
          );
        }

        // Normal registration (no verification required) - legacy support
        // Extract token and user data
        final token = response.rawResponse!['token'] as String?;
        final userData = response.rawResponse!['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          final user = User.fromJson(userData);

          // Save token, user data and login status
          // 🔒 SECURITY FIX: Save token in secure encrypted storage
          await SecureStorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          return AuthResult(
            success: true,
            message: 'Registration successful',
            user: user,
          );
        }
      }

      return AuthResult(success: false, error: 'Registration failed');
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Register Provider
  static Future<AuthResult> registerProvider({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? bio,
    String? profilePicturePath,
    String? identityDocumentPath,
    String? healthCertificatePath,
  }) async {
    try {
      final response = await ApiClient.postMultipart(
        ApiConfig.registerProvider,
        fields: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'bio': bio ?? '',
        },
        filePaths: {
          'profile_picture': profilePicturePath ?? '',
          'identity_document': identityDocumentPath ?? '',
          'health_certificate': healthCertificatePath ?? '',
        },
      );

      if (response.success && response.rawResponse != null) {
        // Check if email verification is required
        final requiresVerification = response.rawResponse!['requires_verification'] as bool? ?? false;

        if (requiresVerification) {
          // Account created but needs email verification
          return AuthResult(
            success: true,
            message: 'Account created. Please verify your email',
            requiresVerification: true,
            email: email,
          );
        }

        // Normal registration (no verification required) - legacy support
        // Extract token and user data
        final token = response.rawResponse!['token'] as String?;
        final userData = response.rawResponse!['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          final user = User.fromJson(userData);

          // Save token, user data and login status
          // 🔒 SECURITY FIX: Save token in secure encrypted storage
          await SecureStorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          return AuthResult(
            success: true,
            message: 'Registration successful',
            user: user,
          );
        }
      }

      return AuthResult(success: false, error: 'Registration failed');
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Login
  static Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {

      final response = await ApiClient.post(
        ApiConfig.login,
        body: {'email': email, 'password': password},
      );


      if (response.success && response.rawResponse != null) {
        // Extract token and user data
        final token = response.rawResponse!['token'] as String?;
        final userData = response.rawResponse!['user'] as Map<String, dynamic>?;


        if (token != null && userData != null) {
          final user = User.fromJson(userData);


          // Save token, user data and login status
          // 🔒 SECURITY FIX: Save token in secure encrypted storage
          await SecureStorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          // Handle Remember Me
          // 🔒 SECURITY FIX: Never save password in plain text!
          // We only save the email for convenience, not the password
          if (rememberMe) {
            await StorageService.setRememberMe(true);
            await StorageService.saveRememberedEmail(email);
            // ❌ REMOVED: saveRememberedPassword() - SECURITY RISK!
            // The token is already saved securely, no need to save password
          } else {
            await StorageService.clearRememberMe();
          }


          return AuthResult(
            success: true,
            message: 'Login successful',
            user: user,
          );
        } else {
        }
      } else {
      }

      return AuthResult(
        success: false,
        error: 'Login failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Send OTP
  static Future<AuthResult> sendOtp({
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.sendOtp,
        body: {'phone_number': phoneNumber},
      );

      if (response.success) {
        return AuthResult(
          success: true,
          message: 'Verification code sent to your phone',
        );
      }

      return AuthResult(
        success: false,
        error: 'Failed to send verification code',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Verify OTP and Login
  static Future<AuthResult> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    bool rememberMe = false,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.verifyOtp,
        body: {'phone_number': phoneNumber, 'otp_code': otpCode},
      );

      if (response.success && response.rawResponse != null) {
        final token = response.rawResponse!['token'] as String?;
        final userData = response.rawResponse!['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          final user = User.fromJson(userData);

          // Save token, user data and login status
          await SecureStorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          // Handle Remember Me - save phone number
          if (rememberMe) {
            await StorageService.setRememberMe(true);
            await StorageService.saveRememberedPhone(phoneNumber);
          } else {
            await StorageService.clearRememberMe();
          }

          return AuthResult(
            success: true,
            message: 'Login successful',
            user: user,
          );
        }
      }

      return AuthResult(
        success: false,
        error: 'Login failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<AuthResult> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout, needsAuth: true);

      // 🔒 SECURITY FIX: Clear token from secure storage
      await SecureStorageService.deleteAuthToken();
      await StorageService.clearAll();
      ApiClient.setAuthToken(null);

      return AuthResult(success: true, message: 'Logged out successfully');
    } catch (e) {
      // Even if server call fails, clear local data
      await SecureStorageService.deleteAuthToken();
      await StorageService.clearAll();
      ApiClient.setAuthToken(null);

      return AuthResult(success: true, message: 'Logged out');
    }
  }

  // Get Current User
  static Future<User?> getCurrentUser() async {
    try {
      final user = await StorageService.getUser();
      return user;
    } catch (e) {
      return null;
    }
  }

  // Check if Logged In
  static Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  // Get User from Server
  static Future<AuthResult> fetchCurrentUser() async {
    try {
      final response = await ApiClient.get<User>(
        ApiConfig.me,
        needsAuth: true,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await StorageService.saveUser(response.data!);

        return AuthResult(success: true, user: response.data);
      } else {
        return AuthResult(
          success: false,
          error: 'Failed to fetch user data',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Change Password
  static Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.changePassword,
        needsAuth: true,
        body: {'old_password': oldPassword, 'new_password': newPassword},
      );

      if (response.success) {
        return AuthResult(
          success: true,
          message: 'Password changed successfully',
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Password change failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Update Provider Profile
  static Future<AuthResult> updateProviderProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? profilePicturePath,
    String? identityDocumentPath,
    String? healthCertificatePath,
  }) async {
    try {
      final fields = <String, String>{};

      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (phoneNumber != null) fields['phone_number'] = phoneNumber;
      if (bio != null) fields['bio'] = bio;

      final filePaths = <String, String>{};
      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        filePaths['profile_picture'] = profilePicturePath;
      }
      if (identityDocumentPath != null && identityDocumentPath.isNotEmpty) {
        filePaths['identity_document'] = identityDocumentPath;
      }
      if (healthCertificatePath != null && healthCertificatePath.isNotEmpty) {
        filePaths['health_certificate'] = healthCertificatePath;
      }

      final response = await ApiClient.putMultipart(
        ApiConfig.updateProviderProfile,
        fields: fields,
        filePaths: filePaths,
        needsAuth: true,
      );

      if (response.success) {
        // Refresh user data after update
        await fetchCurrentUser();

        return AuthResult(
          success: true,
          message: 'Profile updated successfully',
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Profile update failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Initialize Auth (check saved token)
  // 🔒 SECURITY FIX: Load token from secure storage
  static Future<void> initialize() async {
    final token = await SecureStorageService.getAuthToken();
    if (token != null) {
      ApiClient.setAuthToken(token);
    }
  }

  // ===================== Password Reset (Code-based - 6 digits) =====================

  /// Send password reset code (6 digits) to email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.sendPasswordResetCode,
        body: {'email': email},
      );

      if (response.success) {
        return {
          'success': true,
          'message': 'Verification code sent to your email',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to send verification code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }

  /// Verify password reset code (6 digits)
  static Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.verifyPasswordResetCode,
        body: {'email': email, 'code': code},
      );

      if (response.success && response.rawResponse != null) {
        return {
          'success': true,
          'can_reset': response.rawResponse!['can_reset'] ?? true,
          'message': 'Code verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Invalid or expired code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }

  /// Reset password using code (6 digits)
  static Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordWithCode,
        body: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );

      if (response.success) {
        return {
          'success': true,
          'message': 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Password reset failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Google Sign-In
  static Future<AuthResult> signInWithGoogle({
    required String role, // 'CLIENT' or 'PROVIDER'
  }) async {
    try {
      final googleAccount = await GoogleAuthService.signInWithGoogle();

      if (googleAccount == null) {
        return AuthResult(
          success: false,
          error: 'Google sign-in failed',
        );
      }

      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        return AuthResult(
          success: false,
          error: 'Failed to get authentication data',
        );
      }

      final response = await ApiClient.post(
        ApiConfig.googleAuth,
        body: {
          'id_token': idToken,
          'access_token': accessToken,
          'role': role,
          'email': googleAccount.email,
          'first_name': googleAccount.displayName?.split(' ').first ?? '',
          'last_name': googleAccount.displayName?.split(' ').skip(1).join(' ') ?? '',
        },
      );

      if (response.success && response.rawResponse != null) {
        final token = response.rawResponse!['token'] as String?;
        final userData = response.rawResponse!['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          final user = User.fromJson(userData);

          await StorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          return AuthResult(
            success: true,
            message: 'Login successful',
            user: user,
          );
        }
      }

      String errorMessage = 'Login failed';

      if (response.rawResponse != null &&
          response.rawResponse!['existing_role'] != null) {
        errorMessage = 'This account is registered with a different role';
      }

      return AuthResult(
        success: false,
        error: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final String? error;
  final User? user;
  final bool requiresVerification;
  final String? email;

  AuthResult({
    required this.success,
    this.message,
    this.error,
    this.user,
    this.requiresVerification = false,
    this.email,
  });

  // Helper getter to get user data as Map
  Map<String, dynamic>? get userData => user?.toJson();
}
