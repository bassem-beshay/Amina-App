# 🔥 إصلاح التهيئة التلقائية لـ Firebase عند بدء Django

## المشكلة الأصلية:

عند إرسال الإشعارات من الـ Backend (عند إتمام حجز، رسالة شات، إلخ)، كانت تفشل مع الرسالة:
```
The default Firebase app does not exist. Make sure to initialize the SDK by calling initialize_app().
```

## السبب:

Firebase Admin SDK كان يتهيأ فقط عند الاستدعاء اليدوي لـ `FCMService.initialize()`، لكنه **لم يكن يتهيأ تلقائياً** عند بدء Django!

## الحل المطبق:

### 1. إصلاح صلاحيات ملف Firebase Credentials

**المشكلة:** الملف كان مملوكاً لـ `root`، بينما Gunicorn يعمل بحساب `amina`

**الحل:**
```bash
chown amina:amina /home/amina/AminaPlatform/firebase-credentials.json
chmod 600 /home/amina/AminaPlatform/firebase-credentials.json
```

### 2. إضافة التهيئة التلقائية في apps.py

**الملف:** `/home/amina/AminaPlatform/users/apps.py`

**الكود:**
```python
from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'

    def ready(self):
        """
        يتم تنفيذ هذا الكود عند بدء Django
        """
        # تهيئة Firebase Admin SDK
        try:
            from .fcm_service import FCMService
            FCMService.initialize()
            print('✅ Firebase initialized on Django startup')
        except Exception as e:
            print(f'⚠️ Warning: Could not initialize Firebase on startup: {e}')
```

## النتيجة:

✅ عند بدء Django/Gunicorn/Daphne، يتم تهيئة Firebase تلقائياً
✅ جميع الإشعارات من Backend تعمل الآن بنجاح
✅ لا حاجة للاستدعاء اليدوي لـ `FCMService.initialize()`

## التحقق:

```bash
# تحقق من التهيئة
cd /home/amina/AminaPlatform
source venv/bin/activate
python manage.py shell

>>> import firebase_admin
>>> len(firebase_admin._apps)
1  # ✅ Firebase initialized!
```

## ملاحظة هامة:

إذا تم تحديث ملف `firebase-credentials.json`، يجب:
1. التأكد من الصلاحيات: `chown amina:amina` + `chmod 600`
2. إعادة تشغيل الخدمات: `systemctl restart gunicorn && systemctl restart daphne`
