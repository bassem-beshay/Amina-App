// 🔒 SECURITY: Environment Configuration
// This file manages sensitive configuration and API keys
// ⚠️ IMPORTANT: Never commit actual API keys to version control!
//
// For production builds, use environment variables or secure key storage
// such as AWS Secrets Manager, Google Secret Manager, or similar services.

class EnvConfig {
  // ========================================
  // 🔐 Environment Selection
  // ========================================
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  // ========================================
  // 🌐 API Configuration
  // ========================================
  static String get baseUrl {
    switch (environment) {
      case 'development':
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000', // Android Emulator
        );
      case 'staging':
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging.amina.bdcbiz.com',
        );
      case 'production':
      default:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://amina.bdcbiz.com',
        );
    }
  }

  static String get wsUrl {
    switch (environment) {
      case 'development':
        return const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'ws://10.0.2.2:8000',
        );
      case 'staging':
        return const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'wss://staging.amina.bdcbiz.com',
        );
      case 'production':
      default:
        return const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'wss://amina.bdcbiz.com',
        );
    }
  }

  // ========================================
  // 🔐 API Keys (Never hardcode in production!)
  // ========================================
  // TODO: Replace with secure key management service
  // For production: Use Google Secret Manager or AWS Secrets Manager

  static String get googleApiKey {
    // ⚠️ WARNING: This is a placeholder. Do NOT commit real keys!
    // In production, fetch from secure backend or use Google Secret Manager
    return const String.fromEnvironment(
      'GOOGLE_API_KEY',
      defaultValue: '', // Empty in code - must be provided at build time
    );
  }

  static String get firebaseCrashReportingKey {
    return const String.fromEnvironment(
      'FIREBASE_CRASH_KEY',
      defaultValue: '', // Empty in code - must be provided at build time
    );
  }

  // ========================================
  // 🔐 Payment Gateway Configuration
  // ========================================
  static String get payskyMerchantId {
    return const String.fromEnvironment(
      'PAYSKY_MERCHANT_ID',
      defaultValue: '', // Must be provided at build time
    );
  }

  static String get payskyApiKey {
    return const String.fromEnvironment(
      'PAYSKY_API_KEY',
      defaultValue: '', // Must be provided at build time
    );
  }

  // ========================================
  // 📱 App Configuration
  // ========================================
  static const String appName = 'Amina Platform';
  static const String packageName = 'com.amina.platform';

  // ========================================
  // 🛡️ Security Settings
  // ========================================
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: false, // Disabled by default for security
  );

  static const bool enableDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );

  // Certificate pinning configuration
  static const bool enableCertificatePinning = bool.fromEnvironment(
    'ENABLE_CERT_PINNING',
    defaultValue: true, // Always enabled for production
  );

  // ========================================
  // 🔍 Validation Methods
  // ========================================
  static bool validateConfiguration() {
    if (isProduction) {
      // In production, ensure all critical keys are set
      final missingKeys = <String>[];

      if (googleApiKey.isEmpty) missingKeys.add('GOOGLE_API_KEY');
      if (payskyMerchantId.isEmpty) missingKeys.add('PAYSKY_MERCHANT_ID');
      if (payskyApiKey.isEmpty) missingKeys.add('PAYSKY_API_KEY');

      if (missingKeys.isNotEmpty) {
        throw Exception(
          '🔒 SECURITY ERROR: Missing required environment variables for production:\n'
          '${missingKeys.join(", ")}\n\n'
          'Build with: flutter build apk --dart-define=ENVIRONMENT=production '
          '--dart-define=GOOGLE_API_KEY=xxx --dart-define=PAYSKY_MERCHANT_ID=xxx ...',
        );
      }
    }
    return true;
  }

  // ========================================
  // 📊 Configuration Summary
  // ========================================
  static String get configSummary {
    return '''
🔧 Environment Configuration:
  📍 Environment: $environment
  🌐 Base URL: $baseUrl
  🔌 WebSocket URL: $wsUrl
  🔐 Certificate Pinning: ${enableCertificatePinning ? 'Enabled ✅' : 'Disabled ⚠️'}
  📝 Logging: ${enableLogging ? 'Enabled' : 'Disabled'}
  🐛 Debug Mode: ${enableDebugMode ? 'Enabled' : 'Disabled'}
''';
  }
}
