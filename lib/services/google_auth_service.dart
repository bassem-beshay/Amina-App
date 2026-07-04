import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Web Client ID from Google Cloud Console
  // OAuth client created at: https://console.cloud.google.com/apis/credentials
  // Project: amina-platform (752936570315)
  // Updated: 2025-10-27
  static const String _webClientId = '752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com';

  // iOS Client ID - Created specifically for iOS app
  static const String _iosClientId = '752936570315-ht42rphdcb9vu99migdi1957t7r6diqb.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Add serverClientId for Android
    serverClientId: _webClientId,
    // Add clientId for iOS (uses CLIENT_ID from GoogleService-Info.plist if not provided)
    clientId: _iosClientId,
  );

  // تسجيل الدخول عبر Google
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      return null;
    }
  }

  // تسجيل الخروج من Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
    }
  }

  // الحصول على المستخدم الحالي
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  // التحقق من تسجيل الدخول
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
