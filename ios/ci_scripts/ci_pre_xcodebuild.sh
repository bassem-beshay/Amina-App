#!/bin/sh

# 🔧 Xcode Cloud Pre-Xcodebuild Script
# يتم تشغيله مباشرة قبل xcodebuild
# Script runs FROM: ios/ci_scripts/

set -e
set -x

echo "================================================"
echo "🚀 Pre-Xcodebuild Verification"
echo "================================================"

echo "📁 Current directory: $(pwd)"

# Navigate to Flutter project root (two levels up from ios/ci_scripts/)
cd ../..

echo "📁 Changed to: $(pwd)"

# Final check before building
echo "📋 Final verification before xcodebuild:"
echo ""

if [ -d "ios/Pods" ]; then
    echo "✅ ios/Pods directory exists"
else
    echo "⚠️ ios/Pods directory not found - checking from ios folder..."
    # Also check if we're already in ios folder
    if [ -d "Pods" ]; then
        echo "✅ Pods directory exists (in ios folder)"
    else
        echo "❌ ERROR: Pods directory NOT FOUND!"
        echo "   This means pod install failed or was not run"
        echo "   Directory contents:"
        ls -la
        exit 1
    fi
fi

if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ ios/Flutter/Generated.xcconfig exists"
elif [ -f "Flutter/Generated.xcconfig" ]; then
    echo "✅ Flutter/Generated.xcconfig exists (in ios folder)"
else
    echo "❌ ERROR: Generated.xcconfig NOT FOUND!"
    exit 1
fi

if [ -f "ios/Podfile.lock" ]; then
    echo "✅ ios/Podfile.lock exists"
elif [ -f "Podfile.lock" ]; then
    echo "✅ Podfile.lock exists (in ios folder)"
else
    echo "❌ ERROR: Podfile.lock NOT FOUND!"
    exit 1
fi

echo ""
echo "✅ All dependencies are in place"
echo "🎯 Ready for xcodebuild"
echo "================================================"
