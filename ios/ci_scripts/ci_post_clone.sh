#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs automatically after cloning the repository

set -x  # Print commands as they are executed

echo "=========================================="
echo "🚀 Amina iOS Build - Post-Clone Setup"
echo "=========================================="

# Xcode Cloud runs this script FROM: ios/ci_scripts/
# We need to navigate to Flutter project root (two levels up)
echo "📁 Current directory: $(pwd)"

# Go up two levels: ios/ci_scripts/ -> ios/ -> root/
cd ../..

echo "📁 Changed to: $(pwd)"

# Verify we're in the right place
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ ERROR: pubspec.yaml not found!"
    echo "Current directory: $(pwd)"
    echo "Directory contents:"
    ls -la
    exit 1
fi

echo "✅ Found pubspec.yaml - we're in the Flutter project root"

# Setup Flutter SDK
echo ""
echo "=========================================="
echo "📦 Setting up Flutter"
echo "=========================================="

# Clone Flutter if not found
if [ ! -d "flutter" ]; then
    echo "⚠️ Cloning Flutter SDK..."
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git flutter
fi

export PATH="$PWD/flutter/bin:$PATH"
echo "✅ Flutter added to PATH"

# Verify Flutter works
echo ""
echo "🔍 Verifying Flutter installation..."
flutter --version
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Flutter failed to run"
    exit 1
fi

echo ""
echo "✅ Flutter is ready!"

# Check CocoaPods
echo ""
echo "=========================================="
echo "📦 Checking CocoaPods"
echo "=========================================="

pod --version

# Install Flutter dependencies
echo ""
echo "=========================================="
echo "📦 Installing Flutter dependencies"
echo "=========================================="

echo "⏱️ Running flutter pub get..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ ERROR: flutter pub get failed"
    exit 1
fi

echo "✅ Flutter pub get completed successfully"

# Pre-cache iOS artifacts (required for pod install)
echo ""
echo "=========================================="
echo "📦 Pre-caching iOS Flutter artifacts"
echo "=========================================="

echo "⏱️ Running flutter precache --ios..."
flutter precache --ios
if [ $? -ne 0 ]; then
    echo "❌ ERROR: flutter precache --ios failed"
    exit 1
fi

echo "✅ iOS artifacts pre-cached successfully"

# Verify Flutter.xcframework exists
if [ ! -d "flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework" ]; then
    echo "⚠️ Flutter.xcframework not found in expected location, checking alternative..."
fi

# Verify Generated.xcconfig was created
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    exit 1
fi

echo "✅ Generated.xcconfig created successfully"

# Clean old CocoaPods installation
echo ""
echo "=========================================="
echo "🧹 Cleaning old CocoaPods installation"
echo "=========================================="

cd ios

# Remove old Pods
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock

echo "✅ Cleaned old CocoaPods files"

# Update CocoaPods repo
echo ""
echo "=========================================="
echo "🔄 Updating CocoaPods repo"
echo "=========================================="

pod repo update

# Install CocoaPods dependencies
echo ""
echo "=========================================="
echo "🔨 Installing CocoaPods dependencies"
echo "=========================================="
echo "⏳ This may take several minutes..."

# Run pod install and capture output
pod install 2>&1 | tee pod_install_output.txt
POD_EXIT_CODE=${PIPESTATUS[0]}

if [ $POD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ ERROR: pod install failed with exit code $POD_EXIT_CODE"
    echo ""
    echo "📋 Last 100 lines of pod install output:"
    tail -100 pod_install_output.txt
    exit 1
fi

echo "✅ pod install completed successfully"

# Verify installation
echo ""
echo "=========================================="
echo "✅ Verifying CocoaPods installation"
echo "=========================================="

if [ ! -d "Pods" ]; then
    echo "❌ ERROR: Pods directory was not created!"
    exit 1
fi

if [ ! -f "Podfile.lock" ]; then
    echo "❌ ERROR: Podfile.lock was not created!"
    exit 1
fi

echo "✅ Pods directory exists"
echo "✅ Podfile.lock exists"

# Go back to project root for final summary
cd ..

# Final summary
echo ""
echo "=========================================="
echo "✅ Post-Clone Setup Completed!"
echo "=========================================="
echo ""
echo "🎯 Ready for xcodebuild!"
echo "=========================================="

exit 0
