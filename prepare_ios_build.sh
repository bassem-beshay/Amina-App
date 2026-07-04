#!/bin/bash

# 🔧 Amina iOS Build Preparation Script
# هذا السكريبت يحضر المشروع لعمل Build على iOS

set -e  # Stop on any error

echo "🚀 بدء تحضير مشروع Amina للبيلد على iOS..."
echo "================================================"

# التأكد من أننا في المجلد الصحيح
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ خطأ: يجب تشغيل السكريبت من داخل مجلد aminaapplication"
    exit 1
fi

# الخطوة 1: تنظيف البيلد القديم
echo ""
echo "🧹 الخطوة 1: تنظيف البيلد القديم..."
flutter clean

# الخطوة 2: الحصول على dependencies
echo ""
echo "📦 الخطوة 2: تحميل Flutter dependencies..."
flutter pub get

# الخطوة 3: التحقق من وجود مجلد iOS
if [ ! -d "ios" ]; then
    echo "❌ خطأ: مجلد ios غير موجود"
    exit 1
fi

# الخطوة 4: تنظيف CocoaPods القديم
echo ""
echo "🗑️  الخطوة 3: تنظيف CocoaPods القديم..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# الخطوة 5: تثبيت CocoaPods
echo ""
echo "🔨 الخطوة 4: تثبيت CocoaPods dependencies..."
echo "⏳ هذه الخطوة قد تستغرق عدة دقائق..."

# التحقق من تثبيت CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ خطأ: CocoaPods غير مثبت"
    echo "📝 لتثبيت CocoaPods، قم بتشغيل: sudo gem install cocoapods"
    exit 1
fi

# تحديث repo وتثبيت الـ pods
pod repo update
pod install --verbose

cd ..

# الخطوة 6: التحقق من نجاح التثبيت
echo ""
echo "✅ الخطوة 5: التحقق من نجاح التثبيت..."
if [ -d "ios/Pods" ]; then
    echo "✅ تم تثبيت CocoaPods بنجاح"
else
    echo "❌ فشل تثبيت CocoaPods"
    exit 1
fi

if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ تم إنشاء Generated.xcconfig بنجاح"
else
    echo "❌ فشل إنشاء Generated.xcconfig"
    exit 1
fi

# الخطوة 7: عرض معلومات المشروع
echo ""
echo "================================================"
echo "✅ تم تحضير المشروع بنجاح!"
echo "================================================"
echo ""
echo "📋 معلومات المشروع:"
echo "   • Bundle ID: com.amina.app"
echo "   • Development Team: 9F54T23LQ6"
echo "   • iOS Deployment Target: 13.0+"
echo ""
echo "🎯 الخطوات التالية:"
echo ""
echo "   للبيلد من Command Line:"
echo "   ------------------------"
echo "   flutter build ios --release"
echo ""
echo "   للبيلد من Xcode:"
echo "   ----------------"
echo "   1. افتح ios/Runner.xcworkspace (وليس .xcodeproj)"
echo "   2. اختر الجهاز أو Simulator"
echo "   3. اختر Product > Archive"
echo ""
echo "   للبيلد على CI/CD:"
echo "   -----------------"
echo "   استخدم الملفات التي تم إنشاؤها:"
echo "   • codemagic.yaml - لـ Codemagic"
echo "   • .github/workflows/ios.yml - لـ GitHub Actions"
echo "   • bitrise.yml - لـ Bitrise"
echo ""
echo "================================================"
