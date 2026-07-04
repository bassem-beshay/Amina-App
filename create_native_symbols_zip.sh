#!/bin/bash

# 📦 Script to create Native Debug Symbols ZIP for Google Play Console
# This script collects all native libraries (.so files) with debug symbols
# and packages them in the format required by Google Play Console

echo "🔍 Creating Native Debug Symbols package for Google Play Console..."
echo ""

# Define paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/app/intermediates"
OUTPUT_DIR="$PROJECT_ROOT/build/native_symbols"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIP_FILE="$PROJECT_ROOT/build/native_symbols_${TIMESTAMP}.zip"

# Create output directory
mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*

echo "📁 Copying native libraries with debug symbols..."

# Copy merged native libs (unstripped - contains debug symbols)
if [ -d "$BUILD_DIR/merged_native_libs/release/mergeReleaseNativeLibs/out/lib" ]; then
    echo "   ✅ Found merged native libs (with debug symbols)"
    cp -r "$BUILD_DIR/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"/* "$OUTPUT_DIR/"
fi

# Check if files were copied
if [ ! "$(ls -A $OUTPUT_DIR)" ]; then
    echo "   ❌ ERROR: No native libraries found!"
    echo "   Please build the app first using: flutter build appbundle --release"
    exit 1
fi

echo ""
echo "📊 Native libraries found:"
find "$OUTPUT_DIR" -name "*.so" -type f | while read file; do
    size=$(du -h "$file" | cut -f1)
    echo "   - $(basename $(dirname $file))/$(basename $file) ($size)"
done

echo ""
echo "📦 Creating ZIP archive..."

# Create ZIP file
cd "$OUTPUT_DIR/.."
zip -r "$(basename $ZIP_FILE)" "$(basename $OUTPUT_DIR)" > /dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ ZIP created successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Native Debug Symbols Package Ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📄 File: $ZIP_FILE"
    echo "📏 Size: $(du -h "$ZIP_FILE" | cut -f1)"
    echo ""
    echo "📤 Upload Instructions:"
    echo "   1. Go to Google Play Console"
    echo "   2. Select your app → App Bundle Explorer"
    echo "   3. Select the version you just uploaded"
    echo "   4. Click 'Downloads' tab"
    echo "   5. Under 'Native debug symbols', click 'Upload'"
    echo "   6. Upload: $(basename $ZIP_FILE)"
    echo ""
    echo "🔗 More info: https://support.google.com/googleplay/android-developer/answer/9848633"
    echo ""
else
    echo "   ❌ ERROR: Failed to create ZIP file!"
    exit 1
fi
