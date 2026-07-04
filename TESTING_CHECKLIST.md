# قائمة اختبار تسجيل الدخول عبر Google - Google Sign-In Testing Checklist

## ✅ الإعداد الحالي - Current Setup

### تم الانتهاء من:
- ✅ Web Client ID محدّث في الكود: `752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com`
- ✅ google_auth_service.dart محدّث
- ✅ Flutter dependencies محدّثة
- ✅ الكود خالي من الأخطاء (flutter analyze passed)

### ⏳ يتبقى:
- ⏳ إنشاء Android Debug OAuth Client في Google Cloud Console
- ⏳ تحميل google-services.json جديد من Firebase
- ⏳ اختبار تسجيل الدخول

---

## 🎯 خطوات الاختبار - Testing Steps

### الخطوة 1: إنشاء Android OAuth Client (إذا لم يتم بعد)

1. افتح: https://console.cloud.google.com/apis/credentials?project=amina-platform

2. ابحث عن "Amina Platform - Debug" في قائمة OAuth 2.0 Client IDs

3. **إذا لم تجده**، أنشئه الآن:
   - اضغط **+ CREATE CREDENTIALS** → **OAuth client ID**
   - Application type: **Android**
   - Name: **Amina Platform - Debug**
   - Package name: **com.amina.platform**
   - SHA-1: **82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A**
   - اضغط **CREATE**

4. **انتظر 5-10 دقائق** لتفعيل التغييرات

---

### الخطوة 2: تحديث google-services.json

#### الطريقة الموصى بها (من Firebase):

1. افتح: https://console.firebase.google.com/project/amina-platform/settings/general

2. تحت **Your apps**، اختر التطبيق Android

3. اضغط **Download google-services.json**

4. استبدل الملف في:
   ```
   aminaapplication/android/app/google-services.json
   ```

---

### الخطوة 3: تنظيف وإعادة البناء

قم بتنفيذ الأوامر التالية:

```bash
cd aminaapplication

# تنظيف المشروع
flutter clean

# حذف build folders
rmdir /s /q android\build
rmdir /s /q android\app\build

# تحديث dependencies
flutter pub get

# بناء التطبيق
flutter build apk --debug

# أو تشغيل مباشرة
flutter run
```

---

### الخطوة 4: اختبار تسجيل الدخول

#### في التطبيق:

1. **افتح التطبيق** على جهازك/الإيميوليتر

2. **اذهب لشاشة تسجيل الدخول**

3. **اضغط على زر "تسجيل الدخول عبر Google"**

4. **اختر نوع الحساب**: عميل أو مقدم خدمة

5. **اختر حساب Gmail** من القائمة

6. **النتائج المتوقعة**:
   - ✅ يفتح نافذة اختيار حساب Google
   - ✅ يعرض حساباتك المسجلة
   - ✅ بعد الاختيار، يتم تسجيل الدخول بنجاح
   - ✅ يتم التوجيه للشاشة المناسبة (Customer/Provider Home)

---

## 🐛 استكشاف الأخطاء - Troubleshooting

### خطأ: "PlatformException(sign_in_failed, ...)"

**الأسباب المحتملة**:
1. Android OAuth Client غير موجود
2. SHA-1 fingerprint غير صحيح
3. Package name غير مطابق

**الحل**:
```bash
# تحقق من SHA-1
keytool -list -v -keystore "C:\Users\Dell\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# يجب أن يكون:
# SHA1: 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
```

---

### خطأ: "12500 Sign-in failed"

**السبب**: Android OAuth Client غير موجود أو تم إنشاؤه للتو (يحتاج وقت)

**الحل**:
1. تأكد من إنشاء Android OAuth Client
2. انتظر 10-15 دقيقة
3. جرب مرة أخرى

---

### خطأ: "10 Developer Error"

**السبب**: Web Client ID خاطئ في الكود

**الحل**: تحقق من الملف `lib/services/google_auth_service.dart`:
```dart
static const String _webClientId = '752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com';
```

---

### النافذة تُغلق فوراً بدون رسالة

**السبب**:
1. المستخدم لديه حسابات Google متعددة
2. تم إلغاء العملية
3. مشكلة في الإعدادات

**الحل**:
1. جرب حذف التطبيق وإعادة تثبيته
2. امسح cache: Settings → Apps → Amina Platform → Clear Cache
3. جرب حساب Google مختلف

---

## 🔍 التحقق من الإعدادات - Verify Settings

### ملف google_auth_service.dart

```dart
class GoogleAuthService {
  // يجب أن يكون Web Client ID:
  static const String _webClientId = '752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: _webClientId,
  );
}
```

✅ **تم التحقق**: هذا الإعداد صحيح!

---

### ملف google-services.json

يجب أن يحتوي على:

```json
{
  "project_info": {
    "project_number": "752936570315",
    "project_id": "amina-platform"
  },
  "client": [
    {
      "oauth_client": [
        {
          "client_id": "752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com",
          "client_type": 3
        },
        {
          "client_id": "752936570315-XXXXX.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.amina.platform",
            "certificate_hash": "82a7461cbdc4819f84c2118a1a4ba67b95770b0a"
          }
        }
      ]
    }
  ]
}
```

⚠️ **ملاحظة**: الملف الحالي يحتوي فقط على Web Client (client_type: 3). يحتاج إضافة Android Client (client_type: 1) عن طريق تحميل النسخة الجديدة من Firebase.

---

## 📱 معلومات الجهاز - Device Information

### للاختبار على Android Emulator:
- استخدم emulator به Google Play Services
- تأكد من تسجيل دخول حساب Google في الإيميوليتر

### للاختبار على جهاز فعلي:
- تأكد من تثبيت Google Play Services
- تأكد من وجود حساب Google مسجل

---

## ✅ قائمة التحقق النهائية - Final Checklist

قبل الاختبار، تأكد من:

- [ ] تم إنشاء Android Debug OAuth Client في Google Cloud Console
- [ ] تم تحميل google-services.json الجديد من Firebase
- [ ] تم استبدال الملف القديم
- [ ] تم تنفيذ `flutter clean`
- [ ] تم حذف android/build و android/app/build
- [ ] تم تنفيذ `flutter pub get`
- [ ] مر 10 دقائق على الأقل منذ إنشاء OAuth Client
- [ ] الجهاز/الإيميوليتر به حساب Google مسجل
- [ ] الإنترنت متصل

---

## 📊 النتائج المتوقعة - Expected Results

### ✅ نجاح تسجيل الدخول:

```
✅ فتح نافذة اختيار حساب Google
✅ عرض الحسابات المتاحة
✅ بعد الاختيار: "تم تسجيل الدخول بنجاح"
✅ التوجيه للشاشة الرئيسية
✅ عرض اسم المستخدم وصورته
```

### ❌ فشل تسجيل الدخول:

```
❌ رسالة خطأ في Snackbar
❌ البقاء في شاشة تسجيل الدخول
```

**في هذه الحالة**:
1. تحقق من Google Cloud Console
2. تأكد من إنشاء Android OAuth Client
3. انتظر 10 دقائق إضافية
4. راجع قسم استكشاف الأخطاء أعلاه

---

## 🔗 روابط سريعة - Quick Links

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials?project=amina-platform
- **Firebase Console**: https://console.firebase.google.com/project/amina-platform/settings/general
- **OAuth 2.0 Playground** (للاختبار): https://developers.google.com/oauthplayground/

---

## 📞 الدعم - Support

إذا استمرت المشكلة:
1. راجع [GOOGLE_SIGNIN_FIX.md](./GOOGLE_SIGNIN_FIX.md)
2. راجع [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)
3. تحقق من Android Studio Logcat للأخطاء التفصيلية

---

**آخر تحديث**: 2025-10-27
**الحالة**: ⚠️ بانتظار إنشاء Android OAuth Client واختبار تسجيل الدخول
