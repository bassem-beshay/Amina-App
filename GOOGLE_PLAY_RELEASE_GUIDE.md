# 🚀 دليل رفع التطبيق على Google Play Store

## 📋 معلومات الإصدار الحالي

- **اسم التطبيق**: Amina - منصة أمينة
- **Package Name**: `com.aminaplatform.app` (تأكد من هذا في `build.gradle`)
- **الإصدار**: `1.0.27` (Version Name)
- **Build Number**: `27` (Version Code)

---

## 🔨 خطوات البناء والرفع

### 1️⃣ تنظيف المشروع
```bash
cd C:\Users\Dell\Desktop\Amina\aminaapplication
flutter clean
flutter pub get
```

### 2️⃣ فحص الكود
```bash
# فحص وجود أخطاء
flutter analyze

# اختبار التطبيق
flutter test
```

### 3️⃣ بناء App Bundle (موصى به من Google)
```bash
flutter build appbundle --release
```

**الملف الناتج سيكون في**:
```
build/app/outputs/bundle/release/app-release.aab
```

### 4️⃣ (اختياري) بناء APK
```bash
flutter build apk --release --split-per-abi
```

**الملفات الناتجة**:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 🔐 التوقيع الرقمي (إذا لم يكن موجوداً)

### إنشاء Keystore (مرة واحدة فقط)
```bash
keytool -genkey -v -keystore c:\Users\Dell\amina-upload-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**معلومات مهمة**:
- احفظ الـ password بشكل آمن
- احفظ الـ alias name (مثلاً: `upload`)
- لا تفقد ملف `.jks` أبداً!

### إعداد `key.properties`
أنشئ ملف في: `android/key.properties`
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=c:\\Users\\Dell\\amina-upload-key.jks
```

### تحديث `build.gradle`
تأكد من إضافة هذا في `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 📱 رفع على Google Play Console

### 1. الدخول لـ Play Console
- اذهب إلى: https://play.google.com/console
- سجّل الدخول بحسابك

### 2. إنشاء إصدار جديد
1. اختر التطبيق (Amina)
2. من القائمة الجانبية: **Production** > **Create new release**
3. ارفع ملف `.aab`: `app-release.aab`

### 3. ملء معلومات الإصدار

#### ✏️ Release Name
```
v1.0.27 - تحسينات الإشعارات والواجهة
```

#### 📝 Release Notes (العربية)
```
🆕 الجديد في هذا الإصدار:

🔔 تحسينات الإشعارات
• إضافة صوت واهتزاز لجميع الإشعارات
• أنماط اهتزاز مميزة لكل نوع إشعار
• إضاءة LED بلون التطبيق

🎨 تحسينات الواجهة
• تمرير تلقائي للخدمات السريعة
• تحسين تجربة التصفح

⚡ تحسينات الأداء
• تحسين سرعة التطبيق
• إصلاح عدة مشاكل
```

#### 📝 Release Notes (English)
```
🆕 What's New:

🔔 Notification Improvements
• Added sound & vibration for all notifications
• Unique vibration patterns for each notification type
• LED light with app color

🎨 UI Enhancements
• Auto-scroll for quick services
• Improved browsing experience

⚡ Performance Improvements
• Faster app performance
• Various bug fixes
```

### 4. معلومات إضافية مطلوبة

#### 📸 Screenshots (لازم تحدثها)
- **Phone**: 2-8 صور (1080x1920 أو 1080x2340)
- **7-inch Tablet**: 1-8 صور (1024x600)
- **10-inch Tablet**: 1-8 صور (2048x1536)

#### 🎨 Graphics
- **Feature Graphic**: 1024x500 (مطلوب)
- **App Icon**: 512x512 (مطلوب)

#### 📄 Store Listing
- **Short Description**: 80 حرف
```
منصة أمينة - أفضل خدمات منزلية بضغطة زر
```

- **Full Description**: 4000 حرف
```
🏠 منصة أمينة - خدمات منزلية موثوقة

احصل على أفضل الخدمات المنزلية بضغطة زر! منصة أمينة تربطك بأفضل مقدمي الخدمات المنزلية في مصر.

✨ خدماتنا:
• تنظيف منزلي شامل
• طبخ منزلي
• رعاية أطفال
• رعاية مسنين
• غسيل وكي الملابس
• وأكثر...

🔒 الأمان أولاً:
• جميع مقدمي الخدمات مفحوصين
• تقييمات حقيقية من العملاء
• دفع آمن ومضمون

📱 مميزات التطبيق:
• واجهة سهلة وبسيطة
• حجز سريع
• تتبع الطلبات
• دردشة مباشرة
• إشعارات فورية

💳 طرق دفع متعددة:
• بطاقات الائتمان
• محافظ إلكترونية
• الدفع عند الاستلام

🌟 لماذا أمينة؟
✓ خدمة عملاء ممتازة
✓ أسعار منافسة
✓ سرعة في الاستجابة
✓ جودة مضمونة

حمّل التطبيق الآن واحصل على أول خدمة بخصم خاص! 🎁
```

---

## ✅ قائمة التحقق قبل النشر

### الكود
- [ ] تم تحديث الإصدار في `pubspec.yaml`
- [ ] تم اختبار التطبيق على أجهزة مختلفة
- [ ] لا توجد أخطاء في `flutter analyze`
- [ ] تم اختبار الإشعارات
- [ ] تم اختبار Firebase
- [ ] تم اختبار الدفع الإلكتروني

### البناء
- [ ] تم بناء `.aab` بنجاح
- [ ] الملف موقّع رقمياً
- [ ] حجم الملف مناسب (< 150 MB)

### Google Play Console
- [ ] تم رفع `.aab`
- [ ] تم ملء Release Notes
- [ ] تم تحديث Screenshots
- [ ] تم تحديث Store Listing
- [ ] تم اختيار الدول المستهدفة
- [ ] تم تحديد التصنيف العمري

### الاختبار
- [ ] تم اختبار الإصدار على Internal Testing
- [ ] تم اختبار الإصدار على Closed Testing (اختياري)
- [ ] جميع الوظائف تعمل بشكل صحيح

---

## 🎯 خطوات النشر النهائية

### 1. Internal Testing (اختبار داخلي)
- اختبر الإصدار مع فريقك أولاً
- مدة الاختبار: 2-7 أيام

### 2. Closed Testing (اختياري)
- اختبر مع مجموعة محدودة من المستخدمين
- احصل على feedback قبل النشر العام

### 3. Production (النشر العام)
- بعد التأكد من كل شيء، انشر الإصدار
- **ملاحظة**: قد يستغرق المراجعة 1-7 أيام

---

## 📊 بعد النشر

### المتابعة
1. **راقب التقييمات والمراجعات**
2. **تحقق من الـ Crash Reports**
3. **راقب Analytics**
4. **رد على استفسارات المستخدمين**

### التحديثات المستقبلية
- اتبع نفس الخطوات لكل تحديث
- احرص على زيادة Version Code في كل مرة
- احتفظ بسجل للتغييرات (CHANGELOG)

---

## ⚠️ ملاحظات مهمة

1. **لا تفقد ملف `.jks`**: بدونه لن تستطيع تحديث التطبيق!
2. **احفظ passwords**: احتفظ بها في مكان آمن
3. **اختبر جيداً**: قبل النشر على Production
4. **اقرأ سياسات Google Play**: لتجنب رفض التطبيق

---

## 🆘 مشاكل شائعة وحلولها

### المشكلة: "You uploaded a debuggable APK"
**الحل**: استخدم `--release` في أمر البناء

### المشكلة: "Version code already exists"
**الحل**: زِد Version Code في `pubspec.yaml`

### المشكلة: "App not signed"
**الحل**: تأكد من إعداد `key.properties` بشكل صحيح

### المشكلة: "Screenshots don't meet requirements"
**الحل**: تأكد من الأبعاد الصحيحة والصيغة (PNG أو JPEG)

---

## 📞 دعم إضافي

- **Google Play Help**: https://support.google.com/googleplay/android-developer
- **Flutter Deployment Guide**: https://docs.flutter.dev/deployment/android

---

**بالتوفيق في النشر! 🚀**
