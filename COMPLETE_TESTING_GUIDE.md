# 🧪 دليل الاختبار الشامل للإشعارات - Amina Platform

## تاريخ الإنشاء: 17 نوفمبر 2025

---

## 🎯 الهدف من هذا الدليل:

هذا دليل شامل لاختبار نظام الإشعارات في تطبيق Amina من **Backend** و **Flutter** بشكل كامل. يغطي جميع السيناريوهات والحالات الممكنة.

---

## 📋 جدول المحتويات:

1. [الإعداد المبدئي](#1-الإعداد-المبدئي)
2. [اختبار من Flutter (المحلي)](#2-اختبار-من-flutter-المحلي)
3. [اختبار من Backend](#3-اختبار-من-backend)
4. [سيناريوهات الاختبار](#4-سيناريوهات-الاختبار)
5. [حل المشاكل](#5-حل-المشاكل)
6. [Checklist النهائي](#6-checklist-النهائي)

---

## 1. الإعداد المبدئي

### ✅ الخطوة 1: تثبيت التطبيق

```bash
# تأكد من أن التطبيق مُبني بأحدث إصدار
cd C:\Users\Dell\Desktop\Amina\aminaapplication
flutter clean
flutter pub get
flutter build apk

# تثبيت على الموبايل
flutter install
# أو
adb install build/app/outputs/flutter-apk/app-release.apk
```

### ✅ الخطوة 2: التأكد من الإعدادات

**على الموبايل:**
- ✅ الصوت مرفوع (ليس صامت)
- ✅ Do Not Disturb مُطفئ
- ✅ أذونات الإشعارات ممنوحة للتطبيق
- ✅ الإنترنت متصل (WiFi أو Mobile Data)

**في التطبيق:**
- ✅ تسجيل الدخول كـ Client أو Provider
- ✅ التحقق من FCM Token (سيظهر في Logs)
- ✅ الوصول لشاشة اختبار الإشعارات

### ✅ الخطوة 3: الحصول على FCM Token

**الطريقة 1: من شاشة الاختبار في Flutter**
1. افتح التطبيق
2. اذهب إلى `/notification-test` (شاشة اختبار الإشعارات)
3. انسخ FCM Token من البطاقة في الأعلى

**الطريقة 2: من Logs**
```bash
# شغّل التطبيق وراقب Logs
flutter run

# ابحث عن:
# ✅ FCM Token: YOUR_TOKEN_HERE
```

**الطريقة 3: من Database**
```sql
-- لو عندك وصول للـ Database
SELECT fcm_token FROM users WHERE id = YOUR_USER_ID;
```

---

## 2. اختبار من Flutter (المحلي)

### 🎯 شاشة اختبار الإشعارات

لقد أنشأنا شاشة اختبار كاملة في Flutter:

#### الوصول للشاشة:

```dart
// من أي مكان في التطبيق
Navigator.pushNamed(context, '/notification-test');

// أو أضف زر في الـ Settings/Profile
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/notification-test');
  },
  child: Text('🔔 اختبار الإشعارات'),
)
```

#### ميزات شاشة الاختبار:

1. **عرض FCM Token** - مع زر نسخ
2. **اختبار صوت الشات** - يشغل `chat_sound.mp3`
3. **اختبار صوت الإشعارات العاجلة** - يشغل `notification_sound.mp3`
4. **اختبار صوت الإشعارات العامة** - يشغل `notification_sound.mp3`
5. **تعليمات اختبار Backend** - خطوة بخطوة
6. **سيناريوهات الاختبار** - قائمة بجميع الحالات

### 📱 كيفية الاختبار المحلي:

#### 1. اختبار صوت الشات:
```
1. افتح شاشة اختبار الإشعارات
2. اضغط على "اختبار صوت الشات"
3. المتوقع:
   ✅ يظهر إشعار فوراً
   ✅ يشتغل صوت قصير ومميز (chat_sound.mp3)
   ✅ يهتز الموبايل (نمط سريع)
   ✅ يظهر LED بنفسجي
```

#### 2. اختبار صوت الإشعارات العاجلة:
```
1. اضغط على "اختبار صوت الإشعارات العاجلة"
2. المتوقع:
   ✅ يظهر إشعار فوراً
   ✅ يشتغل صوت هادئ (notification_sound.mp3)
   ✅ يهتز الموبايل (نمط طويل)
   ✅ يظهر LED بنفسجي
```

#### 3. اختبار صوت الإشعارات العامة:
```
1. اضغط على "اختبار صوت الإشعارات العامة"
2. المتوقع:
   ✅ يظهر إشعار فوراً
   ✅ يشتغل صوت هادئ (notification_sound.mp3)
   ✅ يهتز الموبايل (نمط عادي)
```

### 🔍 مراجعة Logs:

```bash
# شغّل التطبيق مع Logs
flutter run

# راقب المخرجات عند اختبار الإشعار:
# ✅ Test notification shown: chat
# 🔊 Sound: chat_sound
# 📱 Channel: amina_chat_v2
```

---

## 3. اختبار من Backend

### 📦 الإعداد المطلوب:

#### 1. تثبيت Firebase Admin SDK:
```bash
pip install firebase-admin
```

#### 2. تحميل Service Account Key:
1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Project Settings** (⚙️)
4. اختر تبويب **Service Accounts**
5. اضغط على **Generate New Private Key**
6. احفظ الملف باسم `serviceAccountKey.json`

#### 3. وضع الملف:
```bash
# ضع serviceAccountKey.json في مجلد المشروع
C:\Users\Dell\Desktop\Amina\aminaapplication\serviceAccountKey.json
```

### 🚀 استخدام السكريبت الجاهز:

لقد أنشأنا سكريبت Python كامل: `test_fcm_notifications.py`

#### الاستخدام الأساسي:

```bash
# تشغيل جميع الاختبارات
python test_fcm_notifications.py YOUR_FCM_TOKEN

# اختبار نوع معين
python test_fcm_notifications.py YOUR_FCM_TOKEN --test chat
python test_fcm_notifications.py YOUR_FCM_TOKEN --test booking
python test_fcm_notifications.py YOUR_FCM_TOKEN --test payment
python test_fcm_notifications.py YOUR_FCM_TOKEN --test offer
python test_fcm_notifications.py YOUR_FCM_TOKEN --test data_only
python test_fcm_notifications.py YOUR_FCM_TOKEN --test general
```

#### مثال عملي:

```bash
# 1. انسخ FCM Token من التطبيق
# مثال: ey5J8k9L3m4N...

# 2. شغّل اختبار الشات
python test_fcm_notifications.py ey5J8k9L3m4N... --test chat

# النتيجة المتوقعة:
# ✅ Chat notification sent successfully!
# 📝 Message ID: projects/xxx/messages/xxx
# 🔊 Expected sound: chat_sound.mp3
```

### 📊 أنواع الاختبارات المتاحة:

| النوع | الأمر | الصوت المتوقع | الاستخدام |
|-------|-------|---------------|-----------|
| **شات** | `--test chat` | `chat_sound.mp3` | رسائل الشات |
| **حجز** | `--test booking` | `notification_sound.mp3` | حجوزات جديدة |
| **دفع** | `--test payment` | `notification_sound.mp3` | دفع ناجح |
| **عرض** | `--test offer` | `notification_sound.mp3` | عروض العمال |
| **Data-Only** | `--test data_only` | `chat_sound.mp3` | اختبار data payload |
| **عام** | `--test general` | `notification_sound.mp3` | إشعارات عامة |
| **الكل** | `--test all` أو بدون | جميع الأصوات | اختبار شامل |

### 🔬 اختبار متقدم من Django Shell:

```python
# افتح Django Shell
python manage.py shell

# استيراد المكتبات
from firebase_admin import messaging

# FCM Token
token = "YOUR_FCM_TOKEN"

# اختبار شات
message = messaging.Message(
    notification=messaging.Notification(
        title="💬 رسالة اختبار",
        body="اختبار من Django Shell",
    ),
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
    },
    android=messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='amina_chat_v2',
        ),
    ),
    token=token,
)

# إرسال
response = messaging.send(message)
print(f"✅ Sent: {response}")
```

---

## 4. سيناريوهات الاختبار

### 📱 السيناريو 1: التطبيق مفتوح (Foreground)

**الخطوات:**
1. افتح التطبيق
2. ابقَ في أي صفحة (Home, Profile, إلخ)
3. أرسل إشعار من Backend أو شاشة الاختبار

**النتيجة المتوقعة:**
- ✅ يظهر الإشعار في أعلى الشاشة (Head-up notification)
- ✅ يشتغل الصوت المخصص حسب النوع
- ✅ يهتز الموبايل
- ✅ يشتغل LED بنفسجي
- ✅ لو ضغطت على الإشعار، ينتقل للصفحة المناسبة

**الكود المسؤول:**
```dart
// في push_notification_service.dart
Future<void> _handleForegroundMessage(RemoteMessage message) async {
  await _showLocalNotification(message);  // السطر 487
}
```

**Logs المتوقعة:**
```
📩 ========== FOREGROUND MESSAGE ==========
📩 Message ID: xxx
📩 Title: رسالة جديدة
📩 Notification Type: NEW_MESSAGE
🔔 Using CHAT channel for notification (sound: chat_sound)
✅ Local notification shown with sound and vibration
```

---

### 📱 السيناريو 2: التطبيق في الخلفية (Background)

**الخطوات:**
1. افتح التطبيق
2. اضغط Home button (التطبيق يصير في الخلفية)
3. أرسل إشعار من Backend

**النتيجة المتوقعة:**
- ✅ يظهر الإشعار في Notification Tray
- ✅ يشتغل الصوت المخصص
- ✅ يهتز الموبايل
- ✅ يشتغل LED بنفسجي
- ✅ لو ضغطت على الإشعار، يفتح التطبيق والصفحة المناسبة

**الكود المسؤول:**
```dart
// في push_notification_service.dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // السطر 14-162
}
```

**Logs المتوقعة:**
```
📩 Background message received: xxx
📝 Background Extracted - Title: رسالة جديدة, Body: ...
✅ Background notification displayed with sound
🔊 Channel: amina_chat_v2
```

---

### 📱 السيناريو 3: التطبيق مقفول (Terminated)

**الخطوات:**
1. اقفل التطبيق تماماً من Recent Apps (swipe away)
2. انتظر 5 ثواني للتأكد
3. أرسل إشعار من Backend

**النتيجة المتوقعة:**
- ✅ يظهر الإشعار في Notification Tray
- ✅ يشتغل الصوت المخصص
- ✅ يهتز الموبايل
- ✅ يشتغل LED بنفسجي
- ✅ لو ضغطت على الإشعار، يفتح التطبيق

**الكود المسؤول:**
```dart
// نفس Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)
```

**Logs المتوقعة:**
```
📩 Background message received: xxx
✅ Background notification displayed with sound
```

---

### 🔬 السيناريو 4: Data-Only Notification

**الغرض:** اختبار استخراج title/body من `data` payload

**الخطوات:**
1. استخدم السكريبت مع `--test data_only`
2. أو أرسل من Backend بدون `notification` object

**مثال كود Backend:**
```python
message = messaging.Message(
    data={
        'notification_type': 'NEW_MESSAGE',
        'title': 'رسالة اختبار',  # ✅ مهم!
        'body': 'Data-Only test',  # ✅ مهم!
    },
    android=messaging.AndroidConfig(priority='high'),
    token=fcm_token,
)
```

**النتيجة المتوقعة:**
- ✅ يظهر الإشعار رغم عدم وجود `notification` payload
- ✅ يستخدم title/body من `data`
- ✅ يشتغل الصوت المخصص

**Logs المتوقعة:**
```
⚠️ No notification payload, extracting from data...
📝 Extracted - Title: رسالة اختبار, Body: Data-Only test
✅ Local notification shown with sound
```

---

### 🔊 السيناريو 5: اختبار الأصوات المختلفة

**الهدف:** التأكد من تشغيل أصوات مختلفة حسب نوع الإشعار

#### اختبار 1: صوت الشات (chat_sound.mp3)

```bash
python test_fcm_notifications.py YOUR_TOKEN --test chat
```

**المتوقع:**
- 🔊 صوت قصير ومميز (1-2 ثانية)
- 📳 اهتزاز سريع [0, 300, 200, 300]

#### اختبار 2: صوت الإشعارات (notification_sound.mp3)

```bash
python test_fcm_notifications.py YOUR_TOKEN --test booking
```

**المتوقع:**
- 🔊 صوت هادئ ومريح (2-3 ثواني)
- 📳 اهتزاز متوسط [0, 500, 250, 500]

#### المقارنة:

| المعيار | chat_sound.mp3 | notification_sound.mp3 |
|---------|----------------|----------------------|
| **المدة** | 1-2 ثانية | 2-3 ثواني |
| **النوع** | سريع ومميز | هادئ ومريح |
| **الاستخدام** | رسائل الشات | حجوزات، دفع، عروض |

---

## 5. حل المشاكل

### ❌ المشكلة 1: الصوت لا يعمل

**الأسباب المحتملة:**
- الموبايل في وضع صامت
- Do Not Disturb مُفعّل
- الصوت في الإعدادات صفر
- الأذونات غير ممنوحة

**الحلول:**
```
1. ✅ تحقق من:
   - الموبايل مش صامت
   - رفع الصوت
   - Do Not Disturb مُطفئ

2. ✅ تحقق من الأذونات:
   Settings > Apps > Amina > Notifications > Allow

3. ✅ أعد تثبيت التطبيق:
   flutter clean && flutter build apk && flutter install
```

---

### ❌ المشكلة 2: الإشعار لا يظهر

**الأسباب المحتملة:**
- FCM Token غير صحيح
- Backend لم يرسل `title` و `body` في `data`
- مشكلة في Firebase

**الحلول:**
```
1. ✅ تحقق من FCM Token:
   - انسخه من شاشة الاختبار
   - تأكد أنه محفوظ في Database

2. ✅ تحقق من Backend:
   - راجع PUSH_NOTIFICATIONS_GUIDE.md
   - تأكد من إرسال title/body في data

3. ✅ راجع Logs:
   flutter run --verbose
```

---

### ❌ المشكلة 3: الصوت الخطأ يشتغل

**السبب:**
- `notification_type` غير صحيح في `data`

**الحل:**
```python
# تأكد من إرسال notification_type صحيح
data = {
    'notification_type': 'NEW_MESSAGE',  # للشات
    # أو
    'notification_type': 'BOOKING_CONFIRMED',  # للحجز
}
```

---

### ❌ المشكلة 4: خطأ في السكريبت

**الخطأ:**
```
❌ Error: [Errno 2] No such file or directory: 'serviceAccountKey.json'
```

**الحل:**
```bash
# 1. تأكد من وجود الملف
ls serviceAccountKey.json

# 2. أو استخدم المسار الكامل
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"

# 3. أو عدّل السكريبت
# غيّر السطر:
cred_path = '/full/path/to/serviceAccountKey.json'
```

---

## 6. Checklist النهائي

### ✅ قبل البدء:
- [ ] التطبيق مثبت على موبايل حقيقي
- [ ] تسجيل الدخول ناجح
- [ ] FCM Token موجود ومنسوخ
- [ ] الصوت مرفوع و Do Not Disturb مُطفئ
- [ ] الأذونات ممنوحة
- [ ] الإنترنت متصل

### ✅ اختبارات Flutter المحلية:
- [ ] اختبار صوت الشات - يشتغل ✅
- [ ] اختبار صوت الإشعارات العاجلة - يشتغل ✅
- [ ] اختبار صوت الإشعارات العامة - يشتغل ✅

### ✅ اختبارات Backend:
- [ ] Firebase Admin SDK مُعد
- [ ] serviceAccountKey.json موجود
- [ ] سكريبت الاختبار يعمل
- [ ] اختبار شات من Backend - ينجح ✅
- [ ] اختبار حجز من Backend - ينجح ✅
- [ ] اختبار Data-Only - ينجح ✅

### ✅ سيناريوهات التطبيق:
- [ ] التطبيق مفتوح - الإشعار يظهر مع صوت ✅
- [ ] التطبيق في الخلفية - الإشعار يظهر مع صوت ✅
- [ ] التطبيق مقفول - الإشعار يظهر مع صوت ✅

### ✅ الأصوات:
- [ ] chat_sound.mp3 يشتغل للشات ✅
- [ ] notification_sound.mp3 يشتغل للحجز ✅
- [ ] notification_sound.mp3 يشتغل للدفع ✅
- [ ] notification_sound.mp3 يشتغل للعروض ✅

### ✅ المميزات الإضافية:
- [ ] الاهتزاز يعمل ✅
- [ ] LED يعمل (لو مدعوم) ✅
- [ ] الضغط على الإشعار يفتح الصفحة الصحيحة ✅
- [ ] BigTextStyle يعرض النص الكامل ✅

---

## 🎉 النتيجة النهائية:

إذا نجحت جميع الاختبارات أعلاه:

```
✅ نظام الإشعارات يعمل بشكل ممتاز!
✅ الأصوات المخصصة تعمل
✅ جميع الحالات مدعومة
✅ Backend متصل بشكل صحيح

🎊 مبروك! التطبيق جاهز للإنتاج!
```

---

## 📚 مراجع إضافية:

- `SOUND_SYSTEM_VERIFICATION.md` - تقرير الفحص التقني
- `PUSH_NOTIFICATIONS_GUIDE.md` - دليل Backend الشامل
- `BACKEND_TEST_SCRIPTS.md` - أمثلة سكريبتات إضافية
- `NOTIFICATION_SOUNDS_SUMMARY.md` - ملخص نظام الأصوات
- `test_fcm_notifications.py` - السكريبت الجاهز

---

**تاريخ آخر تحديث:** 17 نوفمبر 2025
**الإصدار:** 2.0 - Complete Testing Framework

**✅ كل شيء جاهز للاختبار!** 🚀
