# بيانات Google OAuth - Google OAuth Credentials

## ✅ تم التحديث - Updated: 2025-10-27

---

## 🔐 Web Client ID (المستخدم في Flutter)

```
752936570315-sp96gqagj4d5e0hg3t53hn1ltbrkktki.apps.googleusercontent.com
```

**الموقع في الكود:**
- `lib/services/google_auth_service.dart` (السطر 8)
- `android/app/google-services.json` (السطر 17 و 30)

---

## 📱 Android OAuth Clients

### Debug Build
- **SHA-1**: `82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A`
- **Keystore**: `C:\Users\Dell\.android\debug.keystore`
- **Alias**: `androiddebugkey`
- **يجب إنشاء OAuth Client في Google Cloud Console**

### Release Build
- **SHA-1**: `01:00:88:9F:63:55:AF:0A:B9:0B:6F:31:79:B5:15:CC:87:0F:82:77`
- **Keystore**: `C:\Users\Dell\my-key.jks`
- **Alias**: `my-key-alias`
- **يجب إنشاء OAuth Client في Google Cloud Console**

---

## 🔗 روابط مهمة - Important Links

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials?project=amina-platform
- **Firebase Console**: https://console.firebase.google.com/project/amina-platform
- **Project Number**: 752936570315
- **Project ID**: amina-platform

---

## ⚠️ ملاحظة مهمة

**يجب إنشاء Android OAuth Clients يدوياً** في Google Cloud Console باستخدام البيانات أعلاه:

1. اذهب إلى: https://console.cloud.google.com/apis/credentials?project=amina-platform
2. اضغط **Create Credentials** → **OAuth client ID**
3. اختر **Application type**: Android
4. أنشئ اثنين:
   - واحد للـ Debug (باستخدام SHA-1 الخاص بـ Debug)
   - واحد للـ Release (باستخدام SHA-1 الخاص بـ Release)

بعد إنشائهم، سيتم إضافتهم تلقائياً لملف `google-services.json` عند تحميله من Firebase.

---

## 🧪 اختبار الإعداد

```bash
cd aminaapplication
flutter clean
flutter pub get
flutter run
```

---

## ✅ الملفات المحدّثة

- ✅ `lib/services/google_auth_service.dart` - تم تحديث Web Client ID
- ✅ `android/app/google-services.json` - تم تحديث OAuth clients
- ℹ️ يجب إنشاء Android Debug و Release OAuth clients يدوياً

---

## 📝 الخطوات التالية

1. ✅ **تم**: تحديث Web Client ID في Flutter
2. ✅ **تم**: تحديث google-services.json
3. ⏳ **يتبقى**: إنشاء Android Debug OAuth Client في Google Cloud Console
4. ⏳ **يتبقى**: إنشاء Android Release OAuth Client في Google Cloud Console
5. ⏳ **يتبقى**: اختبار تسجيل الدخول عبر Google

---

**آخر تحديث**: 2025-10-27 23:30
