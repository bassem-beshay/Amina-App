# حل سريع لمشكلة Google Sign-In ⚡

## 🔴 المشكلة
تسجيل الدخول عبر Google لا يعمل

## ✅ الحل (3 خطوات فقط)

### 1️⃣ إنشاء Android OAuth Client

افتح: https://console.cloud.google.com/apis/credentials?project=amina-platform

اضغط **+ CREATE CREDENTIALS** → **OAuth client ID**

املأ:
```
Application type: Android
Name: Amina Platform - Debug
Package name: com.amina.platform
SHA-1: 82:A7:46:1C:BD:C4:81:9F:84:C2:11:8A:1A:4B:A6:7B:95:77:0B:0A
```

اضغط **CREATE**

---

### 2️⃣ تحميل google-services.json الجديد

افتح: https://console.firebase.google.com/project/amina-platform/settings/general

تحت **Your apps** → Android app → **Download google-services.json**

استبدل الملف في: `aminaapplication/android/app/google-services.json`

---

### 3️⃣ إعادة البناء

```bash
cd aminaapplication
flutter clean
flutter pub get
flutter run
```

⏰ **انتظر 5-10 دقائق** بعد إنشاء OAuth Client ثم جرب تسجيل الدخول!

---

## ✅ ما تم تحديثه مسبقاً

- ✅ Web Client ID محدّث في الكود
- ✅ google_auth_service.dart جاهز
- ✅ Dependencies محدّثة

**فقط الخطوات الثلاثة أعلاه مطلوبة!**

---

## 📞 إذا لم يعمل؟

راجع: [TESTING_CHECKLIST.md](./TESTING_CHECKLIST.md)
