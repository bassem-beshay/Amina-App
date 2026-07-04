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
            message: response.message ?? 'تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني',
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
            message: response.message ?? 'تم التسجيل بنجاح',
            user: user,
          );
        }
      }

      return AuthResult(success: false, error: response.error ?? 'فشل التسجيل');
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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
            message: response.message ?? 'تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني',
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
            message: response.message ?? 'تم التسجيل بنجاح',
            user: user,
          );
        }
      }

      return AuthResult(success: false, error: response.error ?? 'فشل التسجيل');
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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
            message: response.message ?? 'تم تسجيل الدخول بنجاح',
            user: user,
          );
        } else {
        }
      } else {
      }

      return AuthResult(
        success: false,
        error: response.error ?? 'فشل تسجيل الدخول',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Logout
  static Future<AuthResult> logout() async {
    try {
      // محاولة إرسال طلب logout للسيرفر
      await ApiClient.post(ApiConfig.logout, needsAuth: true);

      // حذف البيانات المحلية
      // 🔒 SECURITY FIX: Clear token from secure storage
      await SecureStorageService.deleteAuthToken();
      await StorageService.clearAll();
      ApiClient.setAuthToken(null);

      return AuthResult(success: true, message: 'تم تسجيل الخروج بنجاح');
    } catch (e) {
      // حتى لو فشل الاتصال، امسح البيانات المحلية
      await SecureStorageService.deleteAuthToken();
      await StorageService.clearAll();
      ApiClient.setAuthToken(null);

      return AuthResult(success: true, message: 'تم تسجيل الخروج');
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
          error: response.error ?? 'فشل جلب بيانات المستخدم',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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
          message: response.message ?? 'تم تغيير كلمة المرور بنجاح',
        );
      } else {
        return AuthResult(
          success: false,
          error: response.error ?? 'فشل تغيير كلمة المرور',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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
          message: response.message ?? 'تم تحديث الملف الشخصي بنجاح',
        );
      } else {
        return AuthResult(
          success: false,
          error: response.error ?? 'فشل تحديث الملف الشخصي',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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

  /// إرسال كود إعادة تعيين كلمة المرور (6 أرقام) إلى البريد الإلكتروني
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      // استخدام endpoint الكود (6 أرقام) بدلاً من الرابط
      final response = await ApiClient.post(
        ApiConfig.sendPasswordResetCode,
        body: {'email': email},
      );

      if (response.success) {
        return {
          'success': true,
          'message': response.message ?? 'تم إرسال كود التحقق إلى بريدك الإلكتروني',
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'فشل إرسال كود التحقق',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
      };
    }
  }

  /// التحقق من كود إعادة تعيين كلمة المرور (6 أرقام)
  static Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    try {
      // استخدام endpoint التحقق من الكود
      final response = await ApiClient.post(
        ApiConfig.verifyPasswordResetCode,
        body: {'email': email, 'code': code},
      );

      if (response.success && response.rawResponse != null) {
        return {
          'success': true,
          'can_reset': response.rawResponse!['can_reset'] ?? true,
          'message': response.message ?? 'الكود صحيح',
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'الكود غير صحيح أو منتهي الصلاحية',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
      };
    }
  }

  /// إعادة تعيين كلمة المرور باستخدام الكود (6 أرقام)
  static Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    try {
      // استخدام endpoint إعادة التعيين بالكود
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
          'message': response.message ?? 'تم إعادة تعيين كلمة المرور بنجاح',
        };
      } else {
        return {
          'success': false,
          'error': response.error ?? 'فشل إعادة تعيين كلمة المرور',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ في الاتصال: ${e.toString()}',
      };
    }
  }

  // Google Sign-In
  static Future<AuthResult> signInWithGoogle({
    required String role, // 'CLIENT' or 'PROVIDER'
  }) async {
    try {
      // تسجيل الدخول عبر Google
      final googleAccount = await GoogleAuthService.signInWithGoogle();

      if (googleAccount == null) {
        return AuthResult(
          success: false,
          error: 'فشل تسجيل الدخول عبر Google',
        );
      }

      // الحصول على بيانات المستخدم من Google
      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        return AuthResult(
          success: false,
          error: 'فشل الحصول على بيانات المصادقة',
        );
      }

      // إرسال البيانات إلى الـ backend
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

          // حفظ البيانات
          await StorageService.saveAuthToken(token);
          await StorageService.saveUser(user);
          await StorageService.setLoggedIn(true);
          ApiClient.setAuthToken(token);

          return AuthResult(
            success: true,
            message: response.message ?? 'تم تسجيل الدخول بنجاح',
            user: user,
          );
        }
      }

      // التحقق من رسائل الأخطاء الخاصة بتعارض الأدوار
      String errorMessage = response.error ?? 'فشل تسجيل الدخول';

      // إذا كانت الرسالة تحتوي على معلومات عن الدور الموجود
      if (response.rawResponse != null &&
          response.rawResponse!['existing_role'] != null) {
        errorMessage = response.error ?? 'هذا الحساب مسجل بدور مختلف';
      }

      return AuthResult(
        success: false,
        error: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
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
