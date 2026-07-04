# 🏗️ Secure Build Guide - Amina Platform

## Quick Start

### Development Build
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Production Build
```bash
# Using secure build script (recommended)
./build_secure.sh production apk

# Or manually with Flutter
flutter build apk \
  --dart-define=ENVIRONMENT=production \
  --dart-define=GOOGLE_API_KEY=your_key \
  --dart-define=PAYSKY_MERCHANT_ID=your_merchant_id \
  --dart-define=PAYSKY_API_KEY=your_api_key \
  --release
```

---

## 📋 Prerequisites

### 1. Flutter SDK
```bash
flutter --version
# Should be >= 3.0.0
```

### 2. Android SDK
- Build Tools: 35.0.0
- Target SDK: 35
- Min SDK: 29 (Android 10)

### 3. Signing Keys (Production Only)
Generate production keystore:
```bash
keytool -genkey -v -keystore ~/amina-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias amina-key-alias
```

Create `android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=amina-key-alias
storeFile=/path/to/amina-release-key.jks
```

---

## 🔐 Environment Configuration

### Method 1: Using .env File (Recommended)
```bash
# Copy example file
cp .env.example .env

# Edit with your values
nano .env

# Build will automatically load .env
./build_secure.sh production apk
```

### Method 2: Using Command Line Arguments
```bash
flutter build apk \
  --dart-define=ENVIRONMENT=production \
  --dart-define=GOOGLE_API_KEY=$GOOGLE_API_KEY \
  --dart-define=PAYSKY_MERCHANT_ID=$PAYSKY_MERCHANT_ID \
  --dart-define=PAYSKY_API_KEY=$PAYSKY_API_KEY \
  --release
```

### Method 3: Using Environment Variables
```bash
export GOOGLE_API_KEY="your_key"
export PAYSKY_MERCHANT_ID="your_merchant_id"
export PAYSKY_API_KEY="your_api_key"

./build_secure.sh production apk
```

---

## 📦 Build Types

### 1. APK (For Direct Distribution)
```bash
# Development
flutter build apk --dart-define=ENVIRONMENT=development

# Production
./build_secure.sh production apk
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 2. App Bundle (For Google Play)
```bash
./build_secure.sh production appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### 3. Split APKs by ABI
```bash
flutter build apk --split-per-abi \
  --dart-define=ENVIRONMENT=production \
  --release
```
Generates:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

---

## 🔍 Build Verification

### 1. Check APK Signature
```bash
# Linux/Mac
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check signing scheme
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

### 2. Verify Security Configuration
```bash
# Extract APK
unzip -l app-release.apk

# Check network security config
unzip -p app-release.apk res/xml/network_security_config.xml

# Verify ProGuard was applied (classes should be obfuscated)
unzip -p app-release.apk classes.dex | strings | grep "com.amina" | head -20
```

### 3. Test on Device
```bash
# Install and test
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat | grep "Amina"
```

---

## 🛡️ Security Checklist

Before releasing to production:

- [ ] **Keystore**: Using production keystore (not debug)
- [ ] **API Keys**: All keys configured via environment variables
- [ ] **Certificate**: SSL certificate valid and not expired
- [ ] **Pinning**: Certificate pins updated in `network_security_config.xml`
- [ ] **Version**: Version code incremented in `pubspec.yaml`
- [ ] **minSdk**: Set to 29 (Android 10) or higher
- [ ] **ProGuard**: Enabled and tested
- [ ] **Logging**: Disabled in production builds
- [ ] **Testing**: Tested on multiple devices (ARM32, ARM64, x86_64)
- [ ] **Permissions**: Only necessary permissions requested

---

## 🚀 Release Process

### 1. Update Version
```yaml
# pubspec.yaml
version: 1.0.47+47  # Increment both version name and code
```

### 2. Build Production Release
```bash
# Clean build
flutter clean
flutter pub get

# Build AAB for Google Play
./build_secure.sh production appbundle

# Build APK for direct distribution
./build_secure.sh production apk
```

### 3. Run Security Scan
```bash
# Using MobSF or similar
# Upload build/app/outputs/bundle/release/app-release.aab
# Review security report
```

### 4. Test Release Build
```bash
# Install on test device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Test critical flows:
# - User registration/login
# - Service booking
# - Payment processing
# - Real-time chat
# - Push notifications
```

### 5. Upload to Google Play Console
1. Go to: https://play.google.com/console
2. Select Amina Platform app
3. Production → Create new release
4. Upload `app-release.aab`
5. Fill release notes
6. Submit for review

---

## 🐛 Troubleshooting

### Build Fails with "Debug Certificate" Error
```bash
# Solution: Configure production keystore
# Create android/key.properties with production credentials
```

### "Missing API Key" Errors
```bash
# Solution: Set environment variables
export GOOGLE_API_KEY="your_key"
./build_secure.sh production apk
```

### ProGuard Removes Required Classes
```bash
# Solution: Add keep rules to proguard-rules.pro
-keep class com.your.package.** { *; }
```

### Certificate Pinning Fails
```bash
# Solution: Update certificate pin in network_security_config.xml
# Get new pin:
openssl s_client -servername amina.bdcbiz.com \
  -connect amina.bdcbiz.com:443 < /dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

---

## 📊 Build Optimization

### Reduce App Size
```bash
# Enable code shrinking
# Already enabled in build.gradle:
# minifyEnabled true
# shrinkResources true

# Split APKs by ABI
flutter build apk --split-per-abi --release

# Result: 3 smaller APKs instead of 1 large universal APK
```

### Improve Performance
```bash
# Build with profile mode for testing
flutter build apk --profile

# Build with release optimizations
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

---

## 📚 Additional Resources

- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [ProGuard in Android](https://developer.android.com/studio/build/shrink-code)
- [Network Security Configuration](https://developer.android.com/training/articles/security-config)

---

**Last Updated**: 2025-01-19
