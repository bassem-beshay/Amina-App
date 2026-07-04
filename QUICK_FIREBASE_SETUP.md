# 🔥 دليل سريع: إضافة Firebase Credentials

## الخطوة 1: تحميل Service Account Key

### 1. افتح Firebase Console:
```
https://console.firebase.google.com/
```

### 2. اختر مشروعك أو أنشئ واحد جديد:
- إذا كان عندك مشروع Firebase لـ Amina: اختره
- إذا لم يكن عندك: اضغط "Add project" وأنشئ مشروع جديد

### 3. اذهب إلى Project Settings:
- اضغط على أيقونة الترس ⚙️ (أعلى اليسار بجانب "Project Overview")
- اختر **"Project settings"** (إعدادات المشروع)

### 4. اذهب إلى تبويب Service accounts:
- في الأعلى، اختر تبويب **"Service accounts"**
- ستجد صفحة عنوانها: "Firebase Admin SDK"

### 5. حمّل المفتاح:
- ابحث عن زر **"Generate new private key"** (إنشاء مفتاح خاص جديد)
- اضغط عليه
- سيظهر تحذير أمني - اضغط **"Generate key"**
- سيتم تحميل ملف JSON تلقائياً

### 6. مكان الملف المحمّل:
```
C:\Users\Dell\Downloads\amina-platform-firebase-adminsdk-xxxxx.json
```
(الاسم قد يختلف قليلاً)

---

## الخطوة 2: رفع الملف إلى السيرفر

### الطريقة الأسهل - استخدام SCP من PowerShell:

#### أ. افتح PowerShell:
- اضغط `Windows + R`
- اكتب: `powershell`
- اضغط Enter

#### ب. نفذ هذا الأمر:
```powershell
# استبدل اسم الملف بالاسم الصحيح المحمّل
scp "C:\Users\Dell\Downloads\amina-platform-firebase-adminsdk-xxxxx.json" root@31.97.46.103:/home/amina/AminaPlatform/firebase-credentials.json
```

**ملاحظة:** سيطلب منك كلمة مرور السيرفر

#### إذا نجح الأمر، ستظهر:
```
amina-platform-firebase-adminsdk-xxxxx.json    100%   2345    50.2KB/s   00:00
```

---

## الخطوة 3: التحقق من رفع الملف

### افتح SSH:
```powershell
ssh root@31.97.46.103
```

### تحقق من وجود الملف:
```bash
ls -lh /home/amina/AminaPlatform/firebase-credentials.json
```

### يجب أن ترى:
```
-rw-r--r-- 1 root root 2.3K Nov 17 firebase-credentials.json
```

---

## الخطوة 4: إعادة تشغيل Django

### جرب كل أمر حتى ينجح واحد:

```bash
# الطريقة 1: Gunicorn
sudo systemctl restart gunicorn

# الطريقة 2: Supervisor
sudo supervisorctl restart amina

# الطريقة 3: Systemd service
sudo systemctl restart amina

# الطريقة 4: إذا كنت تشغل Django يدوياً
# أوقف العملية الحالية ثم:
cd /home/amina/AminaPlatform
source venv/bin/activate
daphne -b 0.0.0.0 -p 8000 AminaPlatform.asgi:application
```

---

## الخطوة 5: التحقق من النجاح

### نفذ سكريبت التحقق:
```bash
cd /home/amina/AminaPlatform
source venv/bin/activate
python verify_firebase_setup.py --send-test
```

### يجب أن ترى:
```
✅ الملف موجود!
✅ محتوى الملف صحيح!
✅ تمت التهيئة بنجاح!
✅ خدمة الإشعارات جاهزة!
✅ تم إرسال الإشعار بنجاح!
🎉 جميع الاختبارات نجحت!
```

---

## 🎯 إذا واجهت مشاكل:

### مشكلة: "scp: command not found"

**الحل:** استخدم برنامج WinSCP:

1. حمّل WinSCP: https://winscp.net/eng/download.php
2. افتح WinSCP
3. الإعدادات:
   - Host name: `31.97.46.103`
   - User name: `root`
   - Password: (كلمة مرور السيرفر)
4. اضغط "Login"
5. اذهب للمجلد: `/home/amina/AminaPlatform/`
6. اسحب الملف من جهازك وأسقطه في المجلد
7. غيّر اسم الملف إلى: `firebase-credentials.json`

---

### مشكلة: "Permission denied"

```bash
# أعط صلاحيات للملف:
chmod 644 /home/amina/AminaPlatform/firebase-credentials.json
```

---

### مشكلة: "Firebase still not initialized"

```bash
# تحقق من محتوى الملف:
cat /home/amina/AminaPlatform/firebase-credentials.json

# يجب أن يبدأ بـ:
# {
#   "type": "service_account",
#   "project_id": "...",
#   ...
# }

# إذا كان فارغاً أو بصيغة خطأ، أعد رفعه
```

---

## ✅ اختبار نهائي من Flutter:

بعد إضافة الملف وإعادة تشغيل Django:

1. افتح Flutter App
2. اذهب إلى شاشة الاختبار: `test_notifications_screen.dart`
3. اضغط "🔔 Test General Notification"
4. **يجب أن تسمع صوت الإشعار!** ✅
5. اضغط "💬 Test Chat Notification"
6. **يجب أن تسمع صوت الشات!** ✅

---

## 📞 إذا احتجت مساعدة:

أرسل لي screenshot من:
- نتيجة `ls -lh firebase-credentials.json`
- نتيجة `python verify_firebase_setup.py`

وسأساعدك في حل المشكلة!
