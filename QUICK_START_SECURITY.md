# ⚡ دليل البدء السريع - الأمان

## 🎯 للمطورين الجدد

### 1️⃣ أول خطوة: نسخ ملف الإعدادات
```bash
cp .env.example .env
```

### 2️⃣ تعديل المفاتيح في .env
```env
ENVIRONMENT=development
GOOGLE_API_KEY=your_key_here
PAYSKY_MERCHANT_ID=your_merchant_id
PAYSKY_API_KEY=your_api_key
```

### 3️⃣ تشغيل التطبيق
```bash
# Development
flutter run --dart-define=ENVIRONMENT=development

# أو ببساطة
flutter run
```

---

## 🏗️ للبناء

### Development
```bash
flutter build apk --dart-define=ENVIRONMENT=development
```

### Production (الطريقة الآمنة)
```bash
./build_secure.sh production apk
```

---

## ⚠️ تحذيرات مهمة

### ❌ لا تفعل
- ❌ لا تضع API Keys في الكود
- ❌ لا ترفع ملف `.env` على Git
- ❌ لا تستخدم Debug Certificate في Production
- ❌ لا تنسخ google-services.json للعلن

### ✅ افعل
- ✅ استخدم `.env` file للمفاتيح
- ✅ احفظ Production Keystore بأمان
- ✅ استخدم `./build_secure.sh` للبناء
- ✅ اقرأ `SECURITY.md` قبل النشر

---

## 📚 الوثائق الكاملة

| الملف | الوصف |
|-------|-------|
| `SECURITY.md` | دليل الأمان الشامل |
| `BUILD_GUIDE.md` | دليل البناء المفصل |
| `SECURITY_IMPROVEMENTS_REPORT.md` | تقرير التحسينات |

---

## 🆘 مشاكل شائعة

### "Missing API Key" Error
**الحل:** تأكد من ملء `.env` file

### "Debug Certificate" Warning
**الحل:** عادي في Development، ممنوع في Production

### Build Fails
**الحل:**
```bash
flutter clean
flutter pub get
flutter build apk
```

---

## 📞 المساعدة

راجع الملفات التالية حسب الحاجة:
1. للتطوير: `README.md`
2. للأمان: `SECURITY.md`
3. للبناء: `BUILD_GUIDE.md`
