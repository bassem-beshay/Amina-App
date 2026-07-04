# 🔧 إصلاحات مطلوبة في Backend

## ❌ المشاكل المكتشفة

### 1. Firebase Admin SDK غير مثبت
**المشكلة:**
```
Firebase Admin SDK not installed
```

**الحل:**
```bash
# في مجلد Backend
cd C:\Users\Dell\Desktop\Amina\AminaPlatform
pip install firebase-admin
```

---

### 2. كلمة مرور PostgreSQL خاطئة
**المشكلة:**
```
password authentication failed for user "postgres"
```

**الحل:**
افتح `C:\Users\Dell\Desktop\Amina\AminaPlatform\AminaPlatform\settings.py` وحدّث:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'amina_db',
        'USER': 'postgres',
        'PASSWORD': 'YOUR_CORRECT_PASSWORD_HERE',  # ← غيّر هذا
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

---

### 3. Notification Channels غير محدّثة في Backend
**المشكلة:**
الكود في Backend يستخدم أسماء قديمة للقنوات:
- `amina_notifications`
- `amina_urgent`
- `amina_chat`

لكن Flutter يستخدم الآن:
- `amina_notifications_v2`
- `amina_urgent_v2`
- `amina_chat_v2`

**الحل:**
حدّث `C:\Users\Dell\Desktop\Amina\AminaPlatform\users\fcm_service.py`:

**السطر 205 تقريباً - دالة `_get_channel_id()`:**
```python
@classmethod
def _get_channel_id(cls, notification_type: str) -> str:
    """
    تحديد قناة الإشعار بناءً على نوع الإشعار
    """
    if notification_type in ['NEW_MESSAGE', 'CHAT_MESSAGE']:
        return 'amina_chat_v2'  # ← غيّر من amina_chat
    elif notification_type in ['BOOKING_CONFIRMED', 'OFFER_ACCEPTED', 'BOOKING_STARTED']:
        return 'amina_urgent_v2'  # ← غيّر من amina_urgent
    else:
        return 'amina_notifications_v2'  # ← غيّر من amina_notifications
```

---

### 4. ملف Firebase Credentials غير موجود
**المشكلة:**
الكود يبحث عن: `C:\Users\Dell\Desktop\Amina\AminaPlatform\firebase-credentials.json`

**الحل:**
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Project Settings** > **Service Accounts**
4. اضغط **Generate New Private Key**
5. احفظ الملف باسم `firebase-credentials.json`
6. ضعه في: `C:\Users\Dell\Desktop\Amina\AminaPlatform\`

---

## ✅ خطوات التنفيذ بالترتيب

### 1. إصلاح قاعدة البيانات
```bash
cd C:\Users\Dell\Desktop\Amina\AminaPlatform

# حدّث كلمة المرور في settings.py أولاً
# ثم:
python manage.py makemigrations users
python manage.py migrate users
python manage.py migrate
```

### 2. تثبيت Firebase Admin
```bash
pip install firebase-admin
```

### 3. إضافة ملف Firebase Credentials
- حمّل `firebase-credentials.json` من Firebase Console
- ضعه في مجلد `AminaPlatform`

### 4. تحديث Notification Channels
افتح `users/fcm_service.py` وحدّث دالة `_get_channel_id()` كما هو موضح أعلاه

### 5. اختبار النظام
```bash
# تشغيل السيرفر
python manage.py runserver

# اختبار إرسال إشعار
python manage.py shell
>>> from users.fcm_service import FCMService
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> user = User.objects.first()
>>> FCMService.send_notification(user, "Test", "Testing notification sound")
```

---

## 🔍 التحقق من النجاح

### 1. تحقق من FCM Tokens في قاعدة البيانات
```sql
-- في PostgreSQL
SELECT * FROM users_fcmdevice WHERE is_active = true;
```

### 2. تحقق من سجلات الإشعارات
```sql
SELECT * FROM users_notificationlog ORDER BY created_at DESC LIMIT 10;
```

### 3. اختبار من Flutter
```dart
// في التطبيق
await PushNotificationService().showTestNotification();
```

يجب أن:
- ✅ يظهر الإشعار
- ✅ يصدر صوت
- ✅ يهتز الهاتف
- ✅ يُسجل في قاعدة البيانات

---

## 📊 هيكل قاعدة البيانات المتوقع

### جدول `users_fcmdevice`
```
id | user_id | fcm_token | device_type | is_active | created_at
---|---------|-----------|-------------|-----------|------------
1  | 5       | eXYz...   | android     | true      | 2025-01-08
```

### جدول `users_notificationlog`
```
id | user_id | title | body | notification_type | status | created_at
---|---------|-------|------|-------------------|--------|------------
1  | 5       | Test  | ...  | GENERAL          | sent   | 2025-01-08
```

---

## ⚠️ ملاحظات مهمة

1. **تطابق القنوات:** تأكد أن أسماء القنوات في Backend و Flutter متطابقة تماماً
2. **Firebase Setup:** يجب أن يكون Firebase مُفعّل في Console
3. **APNs (iOS):** إذا أردت دعم iOS، تحتاج إعداد APNs certificates
4. **Testing:** اختبر كل نوع إشعار على حدة (Chat, Booking, General)

---

## 🆘 استكشاف الأخطاء

### الإشعار لا يصل؟
1. ✅ تحقق من أن FCM Token مُسجل في قاعدة البيانات
2. ✅ تحقق من `NotificationLog` للأخطاء
3. ✅ تحقق من Firebase Console > Cloud Messaging
4. ✅ تأكد من أن الهاتف متصل بالإنترنت

### الإشعار يصل بدون صوت؟
1. ✅ تأكد من أن أسماء القنوات متطابقة (v2)
2. ✅ تأكد من أن الهاتف ليس في وضع الصمت
3. ✅ احذف بيانات التطبيق وأعد التثبيت
4. ✅ تحقق من إعدادات الإشعارات في الهاتف

---

**بالتوفيق! 🚀**
