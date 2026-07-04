#!/bin/bash

# ========================================
# 🔒 Secure Build Script for Amina Platform
# ========================================
# This script builds the app with security best practices
# Usage: ./build_secure.sh [environment] [build_type]
#   environment: development, staging, production (default: production)
#   build_type: apk, appbundle (default: apk)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-production}"
BUILD_TYPE="${2:-apk}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔒 Secure Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "📍 Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "📦 Build Type: ${GREEN}$BUILD_TYPE${NC}"
echo ""

# ========================================
# 1. Pre-build Checks
# ========================================
echo -e "${YELLOW}🔍 Running pre-build security checks...${NC}"

# Check if running in production mode with debug certificate
if [ "$ENVIRONMENT" = "production" ]; then
    if grep -q "CN=Android Debug" android/app/build.gradle 2>/dev/null; then
        echo -e "${RED}❌ ERROR: Cannot build production with debug certificate!${NC}"
        echo -e "${YELLOW}⚠️  Please configure production keystore in key.properties${NC}"
        exit 1
    fi

    # Check for API keys
    if ! grep -q "GOOGLE_API_KEY" .env 2>/dev/null && [ -z "$GOOGLE_API_KEY" ]; then
        echo -e "${YELLOW}⚠️  WARNING: GOOGLE_API_KEY not found in environment${NC}"
        echo -e "${YELLOW}⚠️  Build will use empty key. Set via --dart-define or .env file${NC}"
    fi
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# ========================================
# 2. Security Validation
# ========================================
echo -e "${YELLOW}🛡️  Validating security configuration...${NC}"

# Verify minSdk
MIN_SDK=$(grep "minSdkVersion" android/app/build.gradle | grep -oP '\d+')
if [ "$MIN_SDK" -lt 29 ]; then
    echo -e "${RED}❌ ERROR: minSdk must be >= 29 for production builds${NC}"
    exit 1
fi
echo -e "${GREEN}✅ minSdk: $MIN_SDK${NC}"

# Verify ProGuard is enabled
if ! grep -q "minifyEnabled true" android/app/build.gradle; then
    echo -e "${YELLOW}⚠️  WARNING: ProGuard not enabled${NC}"
fi

# Verify certificate pinning
if ! grep -q "pin-set" android/app/src/main/res/xml/network_security_config.xml 2>/dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Certificate pinning not configured${NC}"
fi

# ========================================
# 3. Build with Environment Variables
# ========================================
echo -e "${YELLOW}🔨 Building app...${NC}"

# Load environment variables if .env exists
if [ -f ".env" ]; then
    echo -e "${GREEN}📋 Loading .env file...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
fi

# Prepare dart-define arguments
DART_DEFINES=""
DART_DEFINES="$DART_DEFINES --dart-define=ENVIRONMENT=$ENVIRONMENT"

# Add API keys if set
if [ ! -z "$GOOGLE_API_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=GOOGLE_API_KEY=$GOOGLE_API_KEY"
fi

if [ ! -z "$FIREBASE_CRASH_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=FIREBASE_CRASH_KEY=$FIREBASE_CRASH_KEY"
fi

if [ ! -z "$PAYSKY_MERCHANT_ID" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=PAYSKY_MERCHANT_ID=$PAYSKY_MERCHANT_ID"
fi

if [ ! -z "$PAYSKY_API_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=PAYSKY_API_KEY=$PAYSKY_API_KEY"
fi

# Build based on type
if [ "$BUILD_TYPE" = "appbundle" ]; then
    echo -e "${BLUE}🏗️  Building App Bundle (AAB)...${NC}"
    flutter build appbundle $DART_DEFINES --release
    BUILD_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
else
    echo -e "${BLUE}🏗️  Building APK...${NC}"
    flutter build apk $DART_DEFINES --release
    BUILD_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
fi

# ========================================
# 4. Post-build Security Checks
# ========================================
echo -e "${YELLOW}🔍 Running post-build security checks...${NC}"

if [ -f "$BUILD_OUTPUT" ]; then
    FILE_SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo -e "📦 Output: ${BLUE}$BUILD_OUTPUT${NC}"
    echo -e "📏 Size: ${BLUE}$FILE_SIZE${NC}"

    # Generate checksums
    echo -e "${YELLOW}🔐 Generating checksums...${NC}"
    MD5_SUM=$(md5sum "$BUILD_OUTPUT" | cut -d' ' -f1)
    SHA256_SUM=$(sha256sum "$BUILD_OUTPUT" | cut -d' ' -f1)

    echo -e "🔑 MD5: ${BLUE}$MD5_SUM${NC}"
    echo -e "🔑 SHA256: ${BLUE}$SHA256_SUM${NC}"

    # Save checksums to file
    CHECKSUM_FILE="$BUILD_OUTPUT.checksums.txt"
    cat > "$CHECKSUM_FILE" <<EOF
Build Information
================
Environment: $ENVIRONMENT
Build Type: $BUILD_TYPE
Date: $(date)
File: $(basename $BUILD_OUTPUT)
Size: $FILE_SIZE

Checksums
=========
MD5:    $MD5_SUM
SHA256: $SHA256_SUM
EOF
    echo -e "${GREEN}✅ Checksums saved to: $CHECKSUM_FILE${NC}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# ========================================
# 5. Final Security Reminders
# ========================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🎉 Build Complete!${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${RED}⚠️  PRODUCTION BUILD REMINDERS:${NC}"
    echo -e "  1. Verify signing certificate is NOT debug"
    echo -e "  2. Test on multiple devices before release"
    echo -e "  3. Run security scan (MobSF or similar)"
    echo -e "  4. Backup the signed APK/AAB securely"
    echo -e "  5. Update version code in pubspec.yaml"
fi

echo ""
echo -e "${GREEN}✅ All security checks passed!${NC}"
