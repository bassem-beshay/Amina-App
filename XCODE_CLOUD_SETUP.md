# ☁️ Xcode Cloud Setup Guide - دليل إعداد Xcode Cloud

## 🎯 نظرة عامة

تم إنشاء سكريبتات Xcode Cloud الجاهزة لحل مشكلة Exit Code 65 تلقائياً.

---

## 📁 الملفات التي تم إنشاؤها

```
aminaapplication/
└── ios/
    └── ci_scripts/
        ├── ci_post_clone.sh       # يعمل بعد Clone الكود
        └── ci_pre_xcodebuild.sh   # يعمل قبل xcodebuild
```

**⚠️ مهم:** السكريبتات يجب أن تكون في `ios/ci_scripts/` (نفس مستوى .xcodeproj) وليس في root!

---

## 🔧 ما تفعله السكريبتات

### ci_post_clone.sh
يعمل **تلقائياً** بعد Clone الكود ويقوم بـ:

1. ✅ تثبيت/تحديث CocoaPods
2. ✅ تشغيل `flutter pub get` (إنشاء Generated.xcconfig)
3. ✅ تنظيف مجلد Pods القديم
4. ✅ تشغيل `pod install` (إنشاء مجلد Pods وملفات .xcfilelist)
5. ✅ التحقق من وجود جميع الملفات المطلوبة
6. ✅ طباعة معلومات مفصلة للـ debugging

### ci_pre_xcodebuild.sh
يعمل **تلقائياً** قبل xcodebuild ويقوم بـ:

1. ✅ التحقق النهائي من وجود مجلد Pods
2. ✅ التحقق من Generated.xcconfig
3. ✅ التحقق من Podfile.lock
4. ❌ إيقاف البناء إذا كان أي ملف مفقود

---

## 🚀 كيفية الاستخدام

### الخطوة 1: Push الكود إلى Git

```bash
cd aminaapplication

# ⚠️ مهم جداً: السكريبتات يجب أن تكون في ios/ci_scripts/
# تأكد من أن السكريبتات executable
chmod +x ios/ci_scripts/*.sh
git update-index --chmod=+x ios/ci_scripts/ci_post_clone.sh
git update-index --chmod=+x ios/ci_scripts/ci_pre_xcodebuild.sh

# أضف السكريبتات
git add ios/ci_scripts/

# Commit
git commit -m "Add Xcode Cloud scripts to fix Exit Code 65"

# Push
git push origin main
```

**ملاحظات مهمة:**
1. السكريبتات يجب أن تكون في `ios/ci_scripts/` (نفس مستوى .xcodeproj)
2. السكريبتات يجب أن تكون executable (permissions 755) في Git
3. إذا كانت في مكان خاطئ، Xcode Cloud سيقول "script not found"

### الخطوة 2: في Xcode Cloud

**لا تحتاج إلى فعل أي شيء!**

Xcode Cloud سيكتشف السكريبتات تلقائياً ويشغلها:

```
1. Configure macOS          ✅
2. Fetch source code        ✅
3. Post-Clone script        ✅ ← ci_post_clone.sh يعمل هنا
4. Resolve dependencies     ✅
5. Pre-Xcodebuild script    ✅ ← ci_pre_xcodebuild.sh يعمل هنا
6. Run xcodebuild archive   ✅ ← الآن سيعمل بنجاح!
```

---

## 📊 قبل وبعد

### ❌ قبل (Exit Code 65):

```
Run xcodebuild archive → ERROR Exit Code 65
├── Generated.xcconfig not found
├── Pods directory not found
└── .xcfilelist files not found
```

### ✅ بعد (Success):

```
Post-Clone script ✅
├── flutter pub get ✅
├── pod install ✅
└── Verify all files ✅

Run xcodebuild archive → SUCCESS! 🎉
```

---

## 🔍 كيفية التحقق من عمل السكريبتات

### في Xcode Cloud Build Logs:

ابحث عن:

```
Passed  Post-Clone script found at ci_scripts/ci_post_clone.sh
```

وسترى الـ output:

```
================================================
🚀 Amina iOS Build - Post-Clone Setup
================================================

📊 Environment Information:
   Working Directory: /Volumes/workspace/repository
   Xcode Version: 15.1.1
   ...

================================================
📦 Step 1: Installing/Updating CocoaPods
================================================
✅ CocoaPods installed

================================================
📦 Step 2: Getting Flutter dependencies
================================================
✅ Flutter pub get completed

================================================
🔨 Step 5: Installing CocoaPods dependencies
================================================
✅ pod install completed

================================================
✅ Post-Clone Setup Completed Successfully!
================================================
```

---

## 🐛 استكشاف الأخطاء

### الخطأ: "Post-Clone script not found"

**السبب:** الملف غير موجود في Git أو ليس executable

**الحل:**
```bash
# تأكد من وجود الملف
ls -la ci_scripts/ci_post_clone.sh

# اجعله executable
chmod +x ci_scripts/ci_post_clone.sh

# Commit و Push
git add ci_scripts/ci_post_clone.sh
git commit -m "Make ci_post_clone.sh executable"
git push
```

### الخطأ: "pod: command not found"

**السبب:** CocoaPods غير مثبت على Xcode Cloud runner

**الحل:** السكريبت يقوم بتثبيت CocoaPods تلقائياً:
```bash
sudo gem install cocoapods || gem install cocoapods
```

إذا فشل، أضف في بداية `ci_post_clone.sh`:
```bash
export PATH="/usr/local/bin:$PATH"
gem install cocoapods --user-install
export PATH="$HOME/.gem/ruby/3.0.0/bin:$PATH"
```

### الخطأ: "Exit Code 65" لا يزال موجوداً

**الحل:**

1. **تحقق من Build Logs** في Xcode Cloud
2. **ابحث عن** `Post-Clone script` و `Pre-Xcodebuild script`
3. **تأكد من** أن السكريبتات تعمل وتنتهي بـ Success

إذا السكريبتات لم تعمل:
```bash
# تأكد من permissions
cd aminaapplication
chmod +x ci_scripts/*.sh

# تأكد من line endings (UNIX format)
dos2unix ci_scripts/*.sh  # إذا كنت على Windows

# Commit و Push
git add ci_scripts/
git commit -m "Fix ci_scripts permissions and line endings"
git push
```

---

## 📝 تخصيص السكريبتات

### إضافة خطوات إضافية

في `ci_post_clone.sh`:

```bash
# بعد pod install، أضف:

# مثال: نسخ ملفات تكوين خاصة
echo "📋 Copying custom configuration..."
cp config/firebase_prod.json ios/firebase.json

# مثال: تشغيل code generation
echo "🔨 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

# مثال: تحديث version number
echo "📊 Updating version..."
BUILD_NUMBER=$CI_BUILD_NUMBER
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" ios/Runner/Info.plist
```

### إضافة Environment Variables

في Xcode Cloud:
1. App Settings → Environment
2. أضف متغيرات مثل:
   - `FIREBASE_API_KEY`
   - `API_BASE_URL`
   - إلخ

واستخدمها في السكريبت:
```bash
echo "Using API URL: $API_BASE_URL"
```

---

## 🎯 ملاحظات مهمة

1. **Line Endings:**
   - السكريبتات يجب أن تكون بـ UNIX line endings (`LF`)
   - إذا كنت تعدل على Windows، استخدم editor يدعم LF

2. **Permissions:**
   - الملفات يجب أن تكون executable (`chmod +x`)
   - Git يحفظ الـ permissions

3. **Debugging:**
   - السكريبتات تطبع output مفصل
   - استخدم `set -x` لطباعة كل أمر يتم تشغيله

4. **Error Handling:**
   - `set -e` يوقف السكريبت عند أول خطأ
   - هذا يمنع xcodebuild من العمل إذا فشل setup

---

## 📚 مصادر إضافية

### Apple Documentation
- [Xcode Cloud Custom Scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Xcode Cloud Environment Variables](https://developer.apple.com/documentation/xcode/environment-variable-reference)

### Flutter on Xcode Cloud
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)

---

## ✅ Checklist

قبل Push:

- [x] السكريبتات موجودة في `ci_scripts/`
- [x] الملفات executable (`chmod +x`)
- [x] Line endings صحيحة (LF, not CRLF)
- [x] تم اختبار السكريبتات محلياً
- [x] Commit و Push إلى Git

في Xcode Cloud:

- [ ] Post-Clone script يعمل
- [ ] Pod install ينجح
- [ ] Pre-Xcodebuild script يعمل
- [ ] xcodebuild archive ينجح
- [ ] Build artifacts تُنشأ

---

## 🎉 النتيجة المتوقعة

بعد Push السكريبتات:

```
✅ Post-Clone script found at ci_scripts/ci_post_clone.sh
   ├── ✅ CocoaPods installed
   ├── ✅ flutter pub get completed
   ├── ✅ pod install completed
   └── ✅ All files verified

✅ Pre-Xcodebuild script found at ci_scripts/ci_pre_xcodebuild.sh
   └── ✅ Final verification passed

✅ Run xcodebuild archive
   └── ✅ BUILD SUCCEEDED! 🎉
```

---

## 📞 للمساعدة

إذا واجهت مشاكل:

1. **اقرأ Build Logs** في Xcode Cloud بعناية
2. **ابحث عن** الـ output من السكريبتات
3. **راجع** [IOS_BUILD_COMPLETE_GUIDE.md](../IOS_BUILD_COMPLETE_GUIDE.md)
4. **جرب البناء محلياً** باستخدام `prepare_ios_build.sh`

---

**🤖 Created with Claude Code**
**📅 Date: 2025-11-24**
**✅ Status: Ready for Xcode Cloud**
