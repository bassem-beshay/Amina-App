# إعداد Google OAuth للمنصة - Setup Google OAuth for Amina Platform

## معلومات المشروع - Project Information

- **Package Name**: `com.amina.platform`
- **Firebase Project**: `amina-platform`
- **Project Number**: `752936570315`

---

## 1️⃣ إنشاء OAuth Client IDs - Create OAuth Client IDs

يجب إنشاء **ثلاثة** OAuth Client IDs في [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=amina-platform):

### أ) Android Debug Client

**الخطوات:**
1. افتح [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=amina-platform)
2. اضغط **Create Credentials** → **OAuth client ID**
3. اختر **Application type**: `Android`
4. املأ البيانات:
   - **Name**: `Amina Platform - Debug`
   - **Package name**: `com.amina.platform`
   - **SHA-1 certificate fingerprint**:
     ```
     82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
     ```
5. اضغط **CREATE**
6. **احفظ الـ Client ID** الذي يظهر (سيكون بهذا الشكل):
   ```
   752936570315-XXXXXXXXXXXXX.apps.googleusercontent.com
   ```

---

### ب) Android Release Client

**الخطوات:**
1. في نفس الصفحة، اضغط **Create Credentials** → **OAuth client ID** مرة أخرى
2. اختر **Application type**: `Android`
3. املأ البيانات:
   - **Name**: `Amina Platform - Release`
   - **Package name**: `com.amina.platform`
   - **SHA-1 certificate fingerprint**:
     ```
     01:00:88:9F:63:55:AF:0A:B9:0B:6F:31:79:B5:15:CC:87:0F:82:77
     ```
4. اضغط **CREATE**
5. **احفظ الـ Client ID** الجديد

---

### ج) Web Client (مهم للغاية - Required for Google Sign-In)

**الخطوات:**
1. في نفس الصفحة، اضغط **Create Credentials** → **OAuth client ID** مرة ثالثة
2. اختر **Application type**: `Web application`
3. املأ البيانات:
   - **Name**: `Amina Platform - Web Client`
   - **Authorized JavaScript origins** (اختياري):
     ```
     http://localhost
     http://localhost:8000
     ```
   - **Authorized redirect URIs** (اختياري للآن)
4. اضغط **CREATE**
5. **احفظ الـ Web Client ID** - هذا هو الأهم!

---

## 2️⃣ تحديث ملف google-services.json - Update google-services.json

بعد إنشاء الثلاثة OAuth clients:

### الطريقة السهلة (موصى بها):
1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر المشروع **amina-platform**
3. اذهب إلى **Project Settings** (⚙️ أعلى اليسار) → **General**
4. تحت "Your apps"، اختر التطبيق Android
5. اضغط **Download google-services.json**
6. **استبدل** الملف القديم في المسار:
   ```
   aminaapplication/android/app/google-services.json
   ```

### الطريقة اليدوية:
افتح الملف `aminaapplication/android/app/google-services.json` وحدّث:

```json
{
  "project_info": {
    "project_number": "752936570315",
    "project_id": "amina-platform",
    "storage_bucket": "amina-platform.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:752936570315:android:5758706b5e862433cafa4e",
        "android_client_info": {
          "package_name": "com.amina.platform"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR_ANDROID_DEBUG_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.amina.platform",
            "certificate_hash": "82a7461cbdc4819f84c2118a1a4ba67b95770b0a"
          }
        },
        {
          "client_id": "YOUR_ANDROID_RELEASE_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.amina.platform",
            "certificate_hash": "0100889f6355af0ab90b6f3179b515cc870f8277"
          }
        },
        {
          "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyCa51Gz5qpOV0XI4MSSTQgkBthlAbBrzvU"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

**ملاحظة:** استبدل `YOUR_ANDROID_DEBUG_CLIENT_ID`، `YOUR_ANDROID_RELEASE_CLIENT_ID`، و `YOUR_WEB_CLIENT_ID` بالـ Client IDs الفعلية التي حصلت عليها.

---

## 3️⃣ تحديث كود Flutter - Update Flutter Code

افتح الملف: `aminaapplication/lib/services/google_auth_service.dart`

استبدل الـ Web Client ID القديم في السطر 6:

```dart
class GoogleAuthService {
  // استبدل هذا بالـ Web Client ID الجديد
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: _webClientId,
  );

  // باقي الكود...
}
```

---

## 4️⃣ اختبار الإعداد - Test Setup

```bash
cd aminaapplication

# تنظيف المشروع
flutter clean

# تحديث الـ dependencies
flutter pub get

# تشغيل التطبيق
flutter run
```

---

## 5️⃣ التحقق من SHA-1 في المستقبل - Verify SHA-1 in Future

### للحصول على Debug SHA-1:
```bash
keytool -list -v -keystore "C:\Users\Dell\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**النتيجة:**
```
SHA1: 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
SHA256: 36:22:DC:E5:3E:F6:6C:66:E3:73:A2:43:57:E7:1E:D1:44:71:EC:A6:27:81:26:44:C0:30:9A:0B:8B:56:47:E2
```

### للحصول على Release SHA-1:
```bash
keytool -list -v -keystore "C:\Users\Dell\my-key.jks" -alias my-key-alias -storepass 852456312002Bassem -keypass 852456312002Bassem
```

**النتيجة:**
```
SHA1: 01:00:88:9F:63:55:AF:0A:B9:0B:6F:31:79:B5:15:CC:87:0F:82:77
SHA256: 48:3E:98:A4:FD:F5:AB:28:C8:72:78:3E:B8:E2:D2:98:28:7F:39:40:75:07:79:11:93:8D:B9:BD:F5:C0:C8:A7
```

---

## ❗ ملاحظات مهمة - Important Notes

1. **Web Client ID إلزامي**: بدون Web Client ID، تسجيل الدخول عبر Google **لن يعمل** في Flutter
2. **Debug vs Release**: استخدم Debug fingerprint أثناء التطوير، و Release fingerprint عند نشر التطبيق
3. **SHA-1 بدون أقواس**: في ملف google-services.json، تُكتب بدون `:` (مثال: `82a7461cbdc4819f84c2118a1a4ba67b95770b0a`)
4. **يجب تفعيل Google Sign-In API**: في [Google Cloud Console APIs](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=amina-platform)

---

## 🐛 حل المشاكل الشائعة - Troubleshooting

### خطأ 12500 (Sign-in failed)
- **السبب**: SHA-1 fingerprint خاطئ أو OAuth client غير موجود
- **الحل**: تحقق من SHA-1 وأعد إنشاء OAuth client

### خطأ 10 (Developer Error)
- **السبب**: Web Client ID خاطئ في كود Flutter
- **الحل**: تحقق من أن Web Client ID مطابق للموجود في Google Cloud Console

### النافذة تُغلق مباشرة
- **السبب**: Package name غير مطابق
- **الحل**: تحقق من أن Package name هو `com.amina.platform` في جميع الأماكن

### خطأ API not enabled
- **السبب**: Google Sign-In API غير مفعّل
- **الحل**: فعّل API من [هنا](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=amina-platform)

---

## 📝 ملخص البيانات - Summary

| النوع | Package Name | SHA-1 Fingerprint |
|------|-------------|------------------|
| **Debug** | com.amina.platform | 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A |
| **Release** | com.amina.platform | 01:00:88:9F:63:55:AF:0A:B9:0B:6F:31:79:B5:15:CC:87:0F:82:77 |
| **Web Client** | - | - |

**Firebase Project**: amina-platform (752936570315)

---

## ✅ قائمة التحقق - Checklist

- [ ] إنشاء Android Debug OAuth Client
- [ ] إنشاء Android Release OAuth Client
- [ ] إنشاء Web OAuth Client (الأهم!)
- [ ] تحديث google-services.json
- [ ] تحديث google_auth_service.dart بالـ Web Client ID
- [ ] flutter clean && flutter pub get
- [ ] اختبار تسجيل الدخول عبر Google

---

**تاريخ الإنشاء**: 2025-10-27
**الإصدار**: 1.0
