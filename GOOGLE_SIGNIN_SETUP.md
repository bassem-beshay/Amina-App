# دليل إعداد Google Sign-In للتطبيق

## المشكلة
فشل تسجيل الدخول عبر Google بسبب عدم وجود إعدادات صحيحة.

## ما تم إصلاحه تلقائياً

1. ✅ إضافة Google Services Plugin في ملف `android/build.gradle`
2. ✅ إضافة plugin في ملف `android/app/build.gradle`
3. ✅ إنشاء ملف `android/app/google-services.json` الأساسي

## الخطوات المطلوبة منك

### 1. تحديث Google Cloud Console

يجب عليك الذهاب إلى [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=amina-platform) وإضافة SHA-1 fingerprints:

#### للتطوير (Debug):
```
SHA1: 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
Package Name: com.amina.platform
```

#### للإنتاج (Release):
```
SHA1: 01:00:88:9F:63:55:AF:0A:B9:0B:6F:31:79:B5:15:CC:87:0F:82:77
Package Name: com.amina.platform
```

### 2. كيفية إضافة SHA-1 في Google Console

1. اذهب إلى: https://console.cloud.google.com/
2. اختر المشروع: **amina-platform**
3. من القائمة الجانبية → **APIs & Services** → **Credentials**
4. ابحث عن **OAuth 2.0 Client IDs**
5. اضغط على client ID الموجود أو أنشئ واحد جديد من نوع **Android**
6. أضف:
   - **Package name**: `com.amina.platform`
   - **SHA-1 certificate fingerprint**: الـ SHA-1 أعلاه (للـ Debug أولاً)
7. احفظ التغييرات
8. كرر العملية لإضافة الـ SHA-1 الخاص بـ Release

### 3. تنزيل google-services.json الصحيح

بعد إضافة SHA-1 في Google Console:

1. في نفس صفحة Credentials
2. اضغط على **Download google-services.json**
3. **استبدل** الملف الموجود في `android/app/google-services.json` بالملف الجديد المُحمَّل

### 4. التحقق من Web Client ID

تأكد أن الـ Web Client ID في ملف `lib/services/google_auth_service.dart` صحيح:

```dart
static const String _webClientId = '555232260685-ce8ebp1bd6dl3tj9rkd03ebt51l4tpf6.apps.googleusercontent.com';
```

يمكنك إيجاد الـ Web Client ID في Google Console تحت **OAuth 2.0 Client IDs**.

### 5. إعادة بناء التطبيق

بعد تحديث ملف `google-services.json`:

```bash
cd aminaapplication
flutter clean
flutter pub get
flutter run
```

## التحقق من نجاح الإعداد

1. شغل التطبيق
2. اختر "تسجيل الدخول عبر Google"
3. اختر نوع الحساب (عميل أو مقدم خدمة)
4. اختر حساب Gmail
5. يجب أن يتم تسجيل الدخول بنجاح

## استكشاف الأخطاء

### إذا ظهرت رسالة "فشل تسجيل الدخول":

1. **تحقق من SHA-1**: تأكد أنك أضفت SHA-1 الصحيح في Google Console
2. **تحقق من google-services.json**: تأكد أنك نزلت الملف الصحيح من Console
3. **تحقق من Package Name**: يجب أن يكون `com.amina.platform` في كل مكان
4. **أعد بناء التطبيق**: `flutter clean && flutter run`

### إذا ظهرت رسالة "API not enabled":

1. في Google Console → **APIs & Services** → **Library**
2. ابحث عن "Google Sign-In API" أو "People API"
3. اضغط Enable

### فحص Logs:

للتحقق من الأخطاء في وقت التشغيل:

```bash
flutter run
# ثم جرب تسجيل الدخول واقرأ الـ console output
```

## ملاحظات مهمة

- **للتطوير**: استخدم Debug SHA-1
- **للإنتاج**: يجب إضافة Release SHA-1 أيضاً
- الـ Web Client ID يجب أن يكون من نوع **Web application** في Google Console
- الـ Android Client ID يُنشأ تلقائياً عند إضافة SHA-1

## روابط مفيدة

- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/) (إذا كنت تستخدم Firebase)
- [Google Sign-In Plugin Docs](https://pub.dev/packages/google_sign_in)

## SHA-1 Fingerprints السريعة

للحصول على SHA-1 في أي وقت:

```bash
cd android
./gradlew signingReport
```

أو باستخدام keytool:

```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore ~/my-key.jks -alias my-key-alias
```
