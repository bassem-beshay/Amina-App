# 🔥 دليل إعداد Firebase للإشعارات - Amina Platform

## 📊 التشخيص الحالي:

### ❌ المشكلة المكتشفة:
```
✅ Flutter App: الأصوات مضبوطة بشكل صحيح
✅ Django Backend: الكود صحيح
❌ Firebase Credentials: ملف الاعتماد مفقود!
```

**النتيجة**: جميع الإشعارات (11/11) فشلت بسبب عدم تهيئة Firebase على السيرفر

---

## 🔍 الأدلة من السيرفر:

### 1. التحقق من Firebase على السيرفر:
```bash
# نتيجة الفحص:
📁 Service Account Key Path: /home/amina/AminaPlatform/serviceAccountKey.json
📁 File exists: False
❌ Service Account Key NOT FOUND!
Firebase apps initialized: 0
⚠️ Firebase NOT initialized
```

### 2. الإعدادات في Django:
```python
# من /home/amina/AminaPlatform/AminaPlatform/settings.py (Line 236)
FIREBASE_CREDENTIALS_PATH = BASE_DIR / 'firebase-credentials.json'
```

### 3. حالة الإشعارات من Database:
```
FCM Devices المسجلة: 2
- mariamamgad331@gmail.com
- bassembeshay50@gmail.com

الإشعارات المرسلة: 11
الحالة: فشل (Failed) - 11/11
السبب: Firebase غير مهيأ
```

---

## 🛠️ الحل: الحصول على Firebase Service Account Key

### الخطوة 1: الدخول إلى Firebase Console

1. **افتح Firebase Console:**
   ```
   https://console.firebase.google.com/
   ```

2. **اختر مشروع Amina Platform**
   - إذا لم يكن موجوداً، أنشئ مشروعاً جديداً

---

### الخطوة 2: تحميل Service Account Key

#### الطريقة التفصيلية:

1. **من Firebase Console:**
   - اضغط على أيقونة الترس ⚙️ بجانب "Project Overview"
   - اختر **"Project Settings"**

2. **الانتقال إلى Service Accounts:**
   - في القائمة العلوية، اختر تبويب **"Service accounts"**
   - ستجد صفحة بعنوان: "Firebase Admin SDK"

3. **توليد المفتاح:**
   - ابحث عن قسم: **"Firebase service account"**
   - اضغط على زر **"Generate new private key"**
   - سيظهر تحذير أمني
   - اضغط **"Generate key"**

4. **تنزيل الملف:**
   - سيتم تنزيل ملف JSON تلقائياً
   - اسم الملف سيكون شبيه بـ:
     ```
     amina-platform-firebase-adminsdk-xxxxx-xxxxxxxxxx.json
     ```

---

### الخطوة 3: رفع الملف إلى السيرفر

#### الطريقة 1: باستخدام SCP (من Windows)

```powershell
# من PowerShell أو CMD في جهازك
# استبدل المسار بمكان الملف الذي حملته

scp "C:\Users\Dell\Downloads\amina-platform-firebase-adminsdk-xxxxx.json" root@31.97.46.103:/home/amina/AminaPlatform/firebase-credentials.json
```

#### الطريقة 2: باستخدام SFTP

```bash
# استخدم أي SFTP client مثل FileZilla أو WinSCP

# الإعدادات:
Host: 31.97.46.103
Username: root
Port: 22

# ارفع الملف إلى:
/home/amina/AminaPlatform/firebase-credentials.json
```

#### الطريقة 3: نسخ المحتوى مباشرة (SSH)

```bash
# 1. اتصل بالسيرفر
ssh root@31.97.46.103

# 2. أنشئ الملف
nano /home/amina/AminaPlatform/firebase-credentials.json

# 3. انسخ محتوى ملف JSON بالكامل والصقه في nano

# 4. احفظ:
# اضغط Ctrl+O ثم Enter ثم Ctrl+X
```

---

### الخطوة 4: التحقق من الملف على السيرفر

```bash
# اتصل بالسيرفر
ssh root@31.97.46.103

# تحقق من وجود الملف
ls -lh /home/amina/AminaPlatform/firebase-credentials.json

# النتيجة المتوقعة:
# -rw-r--r-- 1 root root 2.3K Nov 17 14:30 firebase-credentials.json

# تحقق من محتوى الملف (أول 10 أسطر)
head -n 10 /home/amina/AminaPlatform/firebase-credentials.json

# يجب أن ترى شيئاً مثل:
# {
#   "type": "service_account",
#   "project_id": "amina-platform",
#   "private_key_id": "xxxxxxxxxx",
#   "private_key": "-----BEGIN PRIVATE KEY-----\n...",
#   "client_email": "firebase-adminsdk-xxxxx@amina-platform.iam.gserviceaccount.com",
#   ...
# }
```

---

### الخطوة 5: إعادة تشغيل Django Application

بعد رفع الملف، يجب إعادة تشغيل التطبيق لتهيئة Firebase:

#### إذا كنت تستخدم Gunicorn:

```bash
# على السيرفر
sudo systemctl restart gunicorn
# أو
sudo service gunicorn restart
```

#### إذا كنت تستخدم Supervisor:

```bash
sudo supervisorctl restart amina
```

#### إذا كنت تستخدم systemd service مخصص:

```bash
# استبدل 'amina' باسم الـ service الخاص بك
sudo systemctl restart amina
```

#### إذا كنت تشغل Django يدوياً:

```bash
# أوقف العملية الحالية (Ctrl+C)
# ثم شغل من جديد
cd /home/amina/AminaPlatform
source venv/bin/activate
python manage.py runserver 0.0.0.0:8000
# أو
daphne -b 0.0.0.0 -p 8000 AminaPlatform.asgi:application
```

---

### الخطوة 6: التحقق من نجاح التهيئة

```bash
# اتصل بالسيرفر
ssh root@31.97.46.103

# افتح Django Shell
cd /home/amina/AminaPlatform
source venv/bin/activate
python manage.py shell

# نفذ الأوامر التالية:
```

```python
import firebase_admin
from firebase_admin import credentials

# تحقق من عدد التطبيقات المهيأة
apps = len(firebase_admin._apps)
print(f"Firebase apps initialized: {apps}")

# إذا كانت النتيجة 0، جرب التهيئة يدوياً:
if apps == 0:
    from django.conf import settings
    cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_PATH))
    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully!")

# تحقق مرة أخرى
apps = len(firebase_admin._apps)
print(f"Firebase apps now: {apps}")
# يجب أن تكون النتيجة: 1
```

---

### الخطوة 7: إرسال إشعار تجريبي

```python
# من نفس Django Shell

from users.models import FCMDevice
from users.fcm_service import FCMNotificationService

# احصل على جهاز للاختبار
device = FCMDevice.objects.filter(is_active=True).first()
print(f"Testing device: {device.user.email}")
print(f"FCM Token: {device.registration_token[:20]}...")

# أرسل إشعار تجريبي
result = FCMNotificationService.send_notification(
    user=device.user,
    title="🔔 اختبار الإشعارات",
    body="هذا إشعار تجريبي للتأكد من عمل Firebase",
    data={
        'type': 'test',
        'notification_type': 'TEST_NOTIFICATION',
        'priority': 'high'
    }
)

print(f"Result: {result}")
# يجب أن ترى: {'success': True, 'message_id': 'projects/...'}
```

---

## 📋 محتويات Service Account Key JSON:

الملف يجب أن يحتوي على:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "xxxxxxxxxxxxxxxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "xxxxxxxxxxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project.iam.gserviceaccount.com"
}
```

**مهم**: هذه بيانات حساسة جداً! لا تشاركها أو ترفعها على Git.

---

## 🔒 الأمان:

### ⚠️ تحذيرات أمنية:

1. **لا ترفع الملف على Git:**
   ```bash
   # تأكد من وجوده في .gitignore
   echo "firebase-credentials.json" >> .gitignore
   echo "serviceAccountKey.json" >> .gitignore
   ```

2. **اضبط الصلاحيات:**
   ```bash
   # على السيرفر
   chmod 600 /home/amina/AminaPlatform/firebase-credentials.json
   chown amina:amina /home/amina/AminaPlatform/firebase-credentials.json
   ```

3. **خذ نسخة احتياطية:**
   ```bash
   # احفظ نسخة في مكان آمن
   cp /home/amina/AminaPlatform/firebase-credentials.json ~/backups/
   ```

---

## 🎯 بعد إصلاح Firebase:

### ستعمل الإشعارات بشكل كامل:

1. ✅ **إشعارات الحجز:**
   - عند إنشاء حجز جديد
   - عند تأكيد الحجز
   - عند إتمام الدفع
   - عند بدء الخدمة
   - عند إتمام الخدمة

2. ✅ **إشعارات الشات:**
   - عند استقبال رسالة جديدة
   - مع صوت مخصص للشات: `chat_sound.mp3`

3. ✅ **إشعارات التقييمات:**
   - عند استقبال تقييم جديد

4. ✅ **إشعارات عروض العمال:**
   - عند تقديم عامل عرضاً على طلب

---

## 📱 اختبار الأصوات بعد الإصلاح:

### من Flutter App:

1. **افتح test_notifications_screen.dart:**
   ```dart
   // الشاشة موجودة في:
   lib/screens/test_notifications_screen.dart
   ```

2. **جرب الأزرار:**
   - 🔔 Test General Notification → يجب أن يعزف `notification_sound.mp3`
   - 💬 Test Chat Notification → يجب أن يعزف `chat_sound.mp3`
   - 🚨 Test High Priority → يجب أن يعزف `notification_sound.mp3`

---

## 🐛 حل المشاكل:

### المشكلة 1: Firebase لا يزال غير مهيأ

```python
# من Django Shell
from users.fcm_service import FCMNotificationService

# حاول التهيئة يدوياً
FCMNotificationService.initialize()

# تحقق من الـ logs
import logging
logger = logging.getLogger('users.fcm_service')
```

### المشكلة 2: خطأ في الملف

```bash
# تحقق من صحة JSON
python -m json.tool /home/amina/AminaPlatform/firebase-credentials.json

# إذا كان صحيحاً، ستظهر النسخة المنسقة
# إذا كان خطأ، سيظهر رسالة خطأ
```

### المشكلة 3: صلاحيات الملف

```bash
# أعط صلاحيات القراءة
chmod 644 /home/amina/AminaPlatform/firebase-credentials.json

# تأكد من المالك
ls -l /home/amina/AminaPlatform/firebase-credentials.json
```

---

## ✅ Checklist للتأكد من كل شيء:

```
☐ تحميل Service Account Key من Firebase Console
☐ رفع الملف إلى /home/amina/AminaPlatform/firebase-credentials.json
☐ التحقق من صحة الملف (json.tool)
☐ ضبط الصلاحيات (chmod 600)
☐ إعادة تشغيل Django application
☐ التحقق من التهيئة في Django Shell (firebase_admin._apps)
☐ إرسال إشعار تجريبي
☐ اختبار صوت الإشعارات من Flutter App
☐ اختبار صوت الشات من Flutter App
☐ إضافة الملف إلى .gitignore
☐ أخذ نسخة احتياطية من الملف
```

---

## 📞 للمساعدة:

إذا واجهت أي مشكلة:

1. **تحقق من Logs:**
   ```bash
   # Django logs
   tail -f /var/log/django/error.log

   # Gunicorn logs
   tail -f /var/log/gunicorn/error.log
   ```

2. **تحقق من FCM Service:**
   ```python
   # من Django Shell
   from users.fcm_service import FCMNotificationService
   FCMNotificationService.initialize()
   ```

---

**🎉 بعد اتباع هذه الخطوات، ستعمل جميع الإشعارات مع الأصوات المخصصة بشكل صحيح!**

**📝 ملاحظة مهمة:**
- Flutter App جاهز ومضبوط بالكامل ✅
- Backend Code جاهز ومضبوط بالكامل ✅
- الملف الوحيد المفقود هو: `firebase-credentials.json` ❌
- بعد إضافة الملف، كل شيء سيعمل مباشرة! 🚀
