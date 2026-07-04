# 🔍 Xcode Cloud Troubleshooting - حل مشاكل Xcode Cloud

## ❓ المشكلة: "Post-Clone script not found"

### السبب المحتمل #1: السكريبتات في مكان خاطئ ⭐ (الأكثر شيوعاً!)

**الأعراض:**
```
Post-Clone script not found at ci_scripts/ci_post_clone.sh
```

**السبب:**
Xcode Cloud يبحث عن `ci_scripts/` بالنسبة لموقع `.xcodeproj`!

إذا كان `.xcodeproj` في `ios/Runner.xcodeproj`، يجب أن تكون السكريبتات في `ios/ci_scripts/`

**التحقق:**
```bash
# تحقق من موقع xcodeproj
find . -name "*.xcodeproj"
# النتيجة: ./ios/Runner.xcodeproj

# تحقق من موقع ci_scripts
find . -name "ci_scripts" -type d
# يجب أن تكون: ./ios/ci_scripts (✅ صحيح)
# وليس: ./ci_scripts (❌ خطأ!)
```

**الحل:**
```bash
# إذا كانت السكريبتات في المكان الخاطئ:
git mv ci_scripts ios/
git commit -m "Fix: Move ci_scripts to ios/ directory"
git push origin main
```

### السبب المحتمل #2: Permissions خاطئة

**الأعراض:**
```
Post-Clone script not found at ci_scripts/ci_post_clone.sh
```

**الحل:**
```bash
cd aminaapplication

# تأكد من أن الملفات executable
chmod +x ios/ci_scripts/*.sh

# حدّث Git index
git update-index --chmod=+x ios/ci_scripts/ci_post_clone.sh
git update-index --chmod=+x ios/ci_scripts/ci_pre_xcodebuild.sh

# تحقق من الـ permissions في Git
git ls-tree HEAD ios/ci_scripts/
# يجب أن تظهر: 100755 (وليس 100644)

# Commit و Push
git add ios/ci_scripts/
git commit -m "Fix: Make ci_scripts executable"
git push origin main
```

### السبب المحتمل #3: الملفات غير موجودة في الـ branch الصحيح

**التحقق:**
```bash
# تأكد من أنك على الـ branch الصحيح
git branch
# يجب أن يكون: * main

# تحقق من وجود الملفات في المكان الصحيح
git ls-files ios/ci_scripts/
# يجب أن يظهر الملفان

# تحقق من آخر commit
git log --oneline -1
```

### السبب المحتمل #4: Xcode Cloud يستخدم branch مختلف

**الحل:**
1. اذهب إلى Xcode Cloud settings
2. تحقق من الـ branch المستخدم في Workflow
3. تأكد أنه يستخدم `main` (أو الـ branch الذي يحتوي على السكريبتات في `ios/ci_scripts/`)

---

## ❓ المشكلة: السكريبت يعمل لكن لا يزال Exit Code 65

### الأعراض:
```
✅ Post-Clone script found
... (السكريبت يعمل)
❌ Run xcodebuild archive - Exit Code 65
```

### التشخيص:

ابحث في logs عن:
1. هل `pod install` اكتمل بنجاح؟
2. هل ظهرت رسالة "✅ Post-Clone Setup Completed!"؟
3. هل تم إنشاء مجلد `Pods/`؟

### الحلول:

#### الحل #1: Flutter ليس في PATH

**الأعراض في Logs:**
```
flutter: command not found
```

**الحل:** أضف في بداية `ci_post_clone.sh`:
```bash
# Add Flutter to PATH
export PATH="$PATH:/Users/builder/flutter/bin"
```

#### الحل #2: CocoaPods فشل في التثبيت

**الأعراض في Logs:**
```
pod: command not found
```

**الحل:** السكريبت يحاول تثبيت CocoaPods تلقائياً، لكن إذا فشل:
```bash
# في ci_post_clone.sh، غيّر:
sudo gem install cocoapods --no-document || gem install cocoapods --no-document

# إلى:
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
gem install cocoapods --user-install --no-document
```

#### الحل #3: pod install فشل

**الأعراض في Logs:**
```
[!] Error installing pods
```

**الحل:** أضف retry logic في السكريبت:
```bash
# محاولة pod install مع retry
MAX_ATTEMPTS=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt $ATTEMPT of $MAX_ATTEMPTS..."
    if pod install --verbose; then
        echo "✅ pod install succeeded"
        break
    else
        echo "⚠️ pod install failed, retrying..."
        ATTEMPT=$((ATTEMPT + 1))
        sleep 5
    fi
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "❌ pod install failed after $MAX_ATTEMPTS attempts"
    exit 1
fi
```

---

## ❓ المشكلة: Generated.xcconfig not found

### السبب:
`flutter pub get` لم يعمل أو فشل

### الحل:

تحقق من Flutter في logs:
```
flutter pub get
```

إذا فشل، أضف debugging:
```bash
# في ci_post_clone.sh
echo "Flutter version:"
flutter --version

echo "Flutter doctor:"
flutter doctor -v

echo "Running flutter pub get..."
flutter pub get

echo "Checking Generated.xcconfig:"
ls -la ios/Flutter/Generated.xcconfig
cat ios/Flutter/Generated.xcconfig
```

---

## ❓ المشكلة: Pods directory not created

### السبب:
`pod install` فشل بصمت

### الحل:

أضف verification أكثر تفصيلاً:
```bash
# بعد pod install
cd ios

if [ ! -d "Pods" ]; then
    echo "❌ ERROR: Pods directory not created!"
    echo "Listing ios directory:"
    ls -la
    echo "Checking Podfile:"
    cat Podfile
    echo "Checking pod install output:"
    pod install --verbose
    exit 1
fi
```

---

## 🔧 السكريبت المُحسّن (للحالات الصعبة)

إذا استمرت المشاكل، استخدم هذا السكريبت البديل:

```bash
#!/bin/sh
set -e
set -x

echo "=========================================="
echo "🚀 Xcode Cloud Build - Debug Version"
echo "=========================================="

# Environment info
echo "Environment:"
echo "  PWD: $(pwd)"
echo "  USER: $(whoami)"
echo "  HOME: $HOME"
echo "  PATH: $PATH"

# Check Flutter
if command -v flutter &> /dev/null; then
    echo "✅ Flutter found"
    flutter --version
else
    echo "❌ Flutter not found in PATH"
    echo "Searching for Flutter..."
    find /Users -name "flutter" -type f 2>/dev/null | head -5
    exit 1
fi

# Check CocoaPods
if command -v pod &> /dev/null; then
    echo "✅ CocoaPods found"
    pod --version
else
    echo "Installing CocoaPods..."
    export GEM_HOME="$HOME/.gem"
    export PATH="$GEM_HOME/bin:$PATH"
    gem install cocoapods --user-install --no-document
    pod --version
fi

# Flutter pub get
echo "Running flutter pub get..."
flutter pub get

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Generated.xcconfig not created"
    ls -la ios/Flutter/
    exit 1
fi
echo "✅ Generated.xcconfig created"

# Pod install
cd ios
echo "Running pod install..."
pod install --verbose

if [ ! -d "Pods" ]; then
    echo "❌ Pods not created"
    ls -la
    exit 1
fi
echo "✅ Pods created"

echo "=========================================="
echo "✅ Setup completed successfully!"
echo "=========================================="
```

---

## 📝 Checklist للتشخيص

قبل طلب المساعدة، تحقق من:

- [ ] السكريبتات موجودة في `ci_scripts/`
- [ ] الـ permissions صحيحة (`100755` في Git)
- [ ] تم commit و push السكريبتات
- [ ] Xcode Cloud يستخدم الـ branch الصحيح
- [ ] راجعت build logs بالكامل
- [ ] وجدت رسالة "Post-Clone script found" في logs
- [ ] Flutter موجود في PATH
- [ ] CocoaPods مثبت
- [ ] `flutter pub get` نجح
- [ ] `pod install` نجح
- [ ] مجلد `Pods/` تم إنشاؤه

---

## 📞 للمساعدة الإضافية

إذا لم تحل المشكلة:

1. **احفظ Build Logs كاملة** من Xcode Cloud
2. **ابحث عن:**
   - أول خطأ يظهر
   - رسائل `❌ ERROR`
   - أي `command not found`
   - أي `permission denied`
3. **شارك:**
   - الخطأ الكامل
   - آخر 50 سطر من logs
   - نسخة macOS المستخدمة
   - نسخة Xcode

---

**🤖 Created with Claude Code**
**📅 Updated: 2025-11-24**
