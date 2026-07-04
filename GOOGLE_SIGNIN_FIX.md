# حل مشكلة فشل تسجيل الدخول عبر Google - Fix Google Sign-In Failure

## 🔴 المشكلة - The Problem
عند محاولة تسجيل الدخول عبر Google، تظهر رسالة "فشل تسجيل الدخول".

**السبب الرئيسي**: عدم إنشاء **Android OAuth Client** في Google Cloud Console.

---

## ✅ الحل السريع - Quick Fix

### الخطوة 1: إنشاء Android Debug OAuth Client

1. افتح [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=amina-platform)

2. اضغط **+ CREATE CREDENTIALS** (في الأعلى)

3. اختر **OAuth client ID**

4. في **Application type**، اختر **Android**

5. املأ البيانات التالية:

   ```
   Name: Amina Platform - Debug

   Package name: com.amina.platform

   SHA-1 certificate fingerprint:
   82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
   ```

6. اضغط **CREATE**

7. **انتظر 5-10 دقائق** حتى تنتشر التغييرات في خوادم Google

---

### الخطوة 2: تحديث google-services.json من Firebase

**طريقة أسهل (موصى بها)**:

1. افتح [Firebase Console](https://console.firebase.google.com/project/amina-platform)

2. اضغط على **⚙️ (الإعدادات)** → **Project settings**

3. في تبويب **General**، انزل لـ **Your apps**

4. اختر التطبيق Android (`com.amina.platform`)

5. اضغط **Download google-services.json**

6. استبدل الملف القديم:
   ```
   aminaapplication/android/app/google-services.json
   ```

---

### الخطوة 3: تنظيف وإعادة البناء

```bash
cd aminaapplication

# تنظيف المشروع
flutter clean

# حذف build folder
rm -rf android/build
rm -rf android/app/build

# تحديث dependencies
flutter pub get

# إعادة تشغيل التطبيق
flutter run
```

---

## 🔍 التحقق من الإعداد - Verify Setup

### 1. التحقق من SHA-1 (اختياري)

```bash
# للتحقق من SHA-1 الخاص بـ Debug keystore
keytool -list -v -keystore "C:\Users\Dell\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1"
```

**النتيجة المتوقعة:**
```
SHA1: 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
```

### 2. التحقق من OAuth Clients في Google Cloud Console

اذهب إلى: https://console.cloud.google.com/apis/credentials?project=amina-platform

يجب أن ترى **3 OAuth Clients**:
- ✅ Amina Platform - Debug (Android)
- ✅ Amina Platform - Web Client (Web application)
- ⏳ Amina Platform - Release (Android) - اختياري للآن

---

## 🐛 أخطاء شائعة وحلولها - Common Errors

### خطأ: "12500 Sign-in failed"
**السبب**: Android OAuth Client غير موجود أو SHA-1 خاطئ

**الحل**:
1. تحقق من إنشاء Android OAuth Client
2. تأكد من SHA-1 صحيح
3. انتظر 5-10 دقائق بعد إنشاء OAuth Client

---

### خطأ: "10 Developer Error"
**السبب**: Web Client ID خاطئ في Flutter code

**الحل**: تحقق من أن Web Client ID في `lib/services/google_auth_service.dart` صحيح:
```dart
static const String _webClientId = '752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com';
```

---

### خطأ: "Sign-in cancelled"
**السبب**: المستخدم ألغى العملية أو لم يكتمل الإعداد

**الحل**:
1. تأكد من إنشاء OAuth Clients
2. جرب مرة أخرى بعد 10 دقائق
3. حاول إلغاء تثبيت التطبيق وإعادة تثبيته

---

### النافذة تُغلق مباشرة بدون رسالة خطأ
**السبب**: Package name غير متطابق

**الحل**: تحقق من أن Package name في Google Cloud Console هو:
```
com.amina.platform
```

---

## 📱 اختبار بعد الإصلاح - Testing After Fix

1. **افتح التطبيق**
2. **اذهب لشاشة تسجيل الدخول**
3. **اضغط على زر Google Sign-In**
4. **اختر نوع الحساب** (عميل أو مقدم خدمة)
5. **اختر حساب Google**
6. **يجب أن يتم تسجيل الدخول بنجاح!** ✅

---

## ⚠️ ملاحظات مهمة

1. **التغييرات تأخذ وقت**: بعد إنشاء OAuth Client، انتظر 5-10 دقائق
2. **flutter clean مهم**: دائماً نفذ `flutter clean` بعد تغيير google-services.json
3. **حذف cache**: إذا لم تعمل، احذف build folder يدوياً
4. **إعادة تثبيت**: في الحالات الصعبة، احذف التطبيق من الجهاز وأعد تثبيته

---

## 🔗 روابط مفيدة

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials?project=amina-platform
- **Firebase Console**: https://console.firebase.google.com/project/amina-platform
- **Google Sign-In Docs**: https://developers.google.com/identity/sign-in/android/start

---

## 📝 قائمة التحقق السريعة - Quick Checklist

- [ ] إنشاء Android Debug OAuth Client في Google Cloud Console
- [ ] تحميل google-services.json الجديد من Firebase
- [ ] استبدال google-services.json القديم
- [ ] تنفيذ flutter clean
- [ ] حذف android/build و android/app/build
- [ ] تنفيذ flutter pub get
- [ ] تشغيل التطبيق
- [ ] الانتظار 5-10 دقائق إذا لم يعمل فوراً
- [ ] اختبار تسجيل الدخول عبر Google

---

## ✅ البيانات الحالية - Current Setup

| Item | Value |
|------|-------|
| **Package Name** | com.amina.platform |
| **Project ID** | amina-platform |
| **Project Number** | 752936570315 |
| **Web Client ID** | 752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com |
| **Debug SHA-1** | 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A |

---

**آخر تحديث**: 2025-10-27
**الحالة**: ✅ Web Client ID محدّث | ⏳ يحتاج Android OAuth Client
