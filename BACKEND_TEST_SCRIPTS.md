# 🧪 سكريبتات اختبار الإشعارات - Backend Testing Scripts

## تاريخ الإنشاء: 17 نوفمبر 2025

---

## 📋 المحتويات:

1. [سكريبت Python مستقل](#1-سكريبت-python-مستقل)
2. [اختبار من Django Shell](#2-اختبار-من-django-shell)
3. [اختبار من Django Management Command](#3-django-management-command)
4. [اختبار من Firebase Console](#4-اختبار-من-firebase-console)
5. [اختبار باستخدام cURL](#5-اختبار-باستخدام-curl)
6. [اختبار باستخدام Postman](#6-اختبار-باستخدام-postman)

---

## 1. سكريبت Python مستقل

### `test_notifications.py`

```python
#!/usr/bin/env python3
"""
سكريبت اختبار شامل لإرسال إشعارات FCM
يدعم جميع أنواع الإشعارات والأصوات المخصصة
"""

import firebase_admin
from firebase_admin import credentials, messaging
import sys
import os

# تهيئة Firebase Admin SDK
def initialize_firebase():
    """تهيئة Firebase Admin SDK"""
    # استبدل بمسار ملف credentials الخاص بك
    cred = credentials.Certificate('path/to/serviceAccountKey.json')

    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)

    print("✅ Firebase Admin SDK initialized")


def send_chat_notification(fcm_token, sender_name="أحمد"):
    """
    إرسال إشعار رسالة شات
    الصوت المتوقع: chat_sound.mp3
    """
    print("\n" + "="*50)
    print("📱 إرسال إشعار شات...")
    print("="*50)

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"💬 رسالة جديدة من {sender_name}",
            body="مرحباً! كيف حالك؟ هل أنت جاهز لبدء الخدمة؟",
        ),
        data={
            'notification_type': 'NEW_MESSAGE',
            'type': 'chat',
            'conversation_id': '123',
            'sender_id': '456',
            'sender_name': sender_name,
            'message_preview': 'مرحباً! كيف حالك؟',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_chat_v2',
                sound='default',
                color='#8B5CF6',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ Chat notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: chat_sound.mp3")
        print(f"📳 Expected vibration: Quick pattern")
        return True
    except Exception as e:
        print(f"❌ Error sending chat notification: {e}")
        return False


def send_booking_notification(fcm_token, client_name="سارة", service_name="تنظيف منزل"):
    """
    إرسال إشعار حجز جديد
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*50)
    print("📅 إرسال إشعار حجز...")
    print("="*50)

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"📅 حجز جديد من {client_name}",
            body=f"خدمة: {service_name}\nالتاريخ: 20 نوفمبر 2025",
        ),
        data={
            'notification_type': 'BOOKING_CONFIRMED',
            'type': 'booking',
            'booking_id': '789',
            'client_name': client_name,
            'service_name': service_name,
            'booking_date': '2025-11-20',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_urgent_v2',
                sound='default',
                color='#10B981',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ Booking notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: notification_sound.mp3")
        print(f"📳 Expected vibration: Long pattern")
        return True
    except Exception as e:
        print(f"❌ Error sending booking notification: {e}")
        return False


def send_payment_notification(fcm_token, amount=250.00):
    """
    إرسال إشعار دفع ناجح
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*50)
    print("💰 إرسال إشعار دفع...")
    print("="*50)

    message = messaging.Message(
        notification=messaging.Notification(
            title="✅ تم الدفع بنجاح",
            body=f"تم دفع {amount} جنيه للحجز. يمكنك الآن بدء الخدمة.",
        ),
        data={
            'notification_type': 'PAYMENT_SUCCESS',
            'type': 'payment',
            'amount': str(amount),
            'booking_id': '789',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_urgent_v2',
                sound='default',
                color='#10B981',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ Payment notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: notification_sound.mp3")
        return True
    except Exception as e:
        print(f"❌ Error sending payment notification: {e}")
        return False


def send_offer_notification(fcm_token, provider_name="محمد", price=200.00):
    """
    إرسال إشعار عرض جديد من مقدم خدمة
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*50)
    print("💼 إرسال إشعار عرض...")
    print("="*50)

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"💰 عرض جديد من {provider_name}",
            body=f"السعر المقترح: {price} جنيه",
        ),
        data={
            'notification_type': 'OFFER_SUBMITTED',
            'type': 'offer',
            'provider_name': provider_name,
            'price': str(price),
            'offer_id': '456',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_notifications_v2',
                sound='default',
                color='#8B5CF6',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ Offer notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: notification_sound.mp3")
        return True
    except Exception as e:
        print(f"❌ Error sending offer notification: {e}")
        return False


def send_data_only_notification(fcm_token):
    """
    إرسال Data-Only notification (بدون notification payload)
    لاختبار استخراج title/body من data
    """
    print("\n" + "="*50)
    print("🔬 إرسال Data-Only notification...")
    print("="*50)

    message = messaging.Message(
        data={
            'notification_type': 'NEW_MESSAGE',
            'type': 'chat',
            'title': 'رسالة اختبار (Data-Only)',  # مهم!
            'body': 'هذا إشعار يستخدم data فقط بدون notification payload',  # مهم!
            'conversation_id': '999',
        },
        android=messaging.AndroidConfig(
            priority='high',
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ Data-only notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: chat_sound.mp3")
        print(f"⚠️ Testing data extraction from 'data' payload")
        return True
    except Exception as e:
        print(f"❌ Error sending data-only notification: {e}")
        return False


def send_general_notification(fcm_token, title="إشعار عام", body="هذا إشعار تجريبي"):
    """
    إرسال إشعار عام
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*50)
    print("🔔 إرسال إشعار عام...")
    print("="*50)

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            'notification_type': 'GENERAL',
            'type': 'general',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_notifications_v2',
                sound='default',
                color='#8B5CF6',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ General notification sent successfully!")
        print(f"📝 Message ID: {response}")
        print(f"🔊 Expected sound: notification_sound.mp3")
        return True
    except Exception as e:
        print(f"❌ Error sending general notification: {e}")
        return False


def run_all_tests(fcm_token):
    """تشغيل جميع الاختبارات"""
    print("\n" + "🚀"*25)
    print("بدء اختبار شامل لنظام الإشعارات")
    print("🚀"*25 + "\n")

    print(f"📱 FCM Token: {fcm_token[:30]}...")

    results = {
        'chat': send_chat_notification(fcm_token),
        'booking': send_booking_notification(fcm_token),
        'payment': send_payment_notification(fcm_token),
        'offer': send_offer_notification(fcm_token),
        'data_only': send_data_only_notification(fcm_token),
        'general': send_general_notification(fcm_token),
    }

    print("\n" + "="*50)
    print("📊 ملخص النتائج:")
    print("="*50)

    for test_name, success in results.items():
        status = "✅" if success else "❌"
        print(f"{status} {test_name}: {'نجح' if success else 'فشل'}")

    total = len(results)
    passed = sum(results.values())

    print("\n" + "="*50)
    print(f"النتيجة النهائية: {passed}/{total} اختبار نجح")
    print("="*50 + "\n")

    return passed == total


def main():
    """الدالة الرئيسية"""
    if len(sys.argv) < 2:
        print("❌ الاستخدام: python test_notifications.py <FCM_TOKEN>")
        print("\nأمثلة:")
        print("  python test_notifications.py YOUR_FCM_TOKEN")
        print("  python test_notifications.py YOUR_FCM_TOKEN --test chat")
        print("  python test_notifications.py YOUR_FCM_TOKEN --test booking")
        print("  python test_notifications.py YOUR_FCM_TOKEN --test all")
        sys.exit(1)

    fcm_token = sys.argv[1]

    # تهيئة Firebase
    initialize_firebase()

    # تحديد نوع الاختبار
    if len(sys.argv) > 3 and sys.argv[2] == '--test':
        test_type = sys.argv[3]

        tests = {
            'chat': send_chat_notification,
            'booking': send_booking_notification,
            'payment': send_payment_notification,
            'offer': send_offer_notification,
            'data_only': send_data_only_notification,
            'general': send_general_notification,
            'all': run_all_tests,
        }

        if test_type in tests:
            if test_type == 'all':
                tests[test_type](fcm_token)
            else:
                tests[test_type](fcm_token)
        else:
            print(f"❌ نوع اختبار غير معروف: {test_type}")
            print(f"الأنواع المتاحة: {', '.join(tests.keys())}")
    else:
        # تشغيل جميع الاختبارات افتراضياً
        run_all_tests(fcm_token)


if __name__ == "__main__":
    main()
```

### كيفية الاستخدام:

```bash
# 1. تثبيت Firebase Admin SDK
pip install firebase-admin

# 2. تحميل Service Account Key من Firebase Console
# Project Settings > Service Accounts > Generate New Private Key

# 3. تشغيل السكريبت
python test_notifications.py YOUR_FCM_TOKEN

# اختبار نوع معين
python test_notifications.py YOUR_FCM_TOKEN --test chat
python test_notifications.py YOUR_FCM_TOKEN --test booking
python test_notifications.py YOUR_FCM_TOKEN --test all
```

---

## 2. اختبار من Django Shell

```python
# افتح Django Shell
python manage.py shell

# استيراد المكتبات المطلوبة
from firebase_admin import messaging
import firebase_admin
from firebase_admin import credentials

# تهيئة Firebase (إذا لم يكن مهيأ)
if not firebase_admin._apps:
    cred = credentials.Certificate('path/to/serviceAccountKey.json')
    firebase_admin.initialize_app(cred)

# FCM Token للمستخدم
fcm_token = "YOUR_FCM_TOKEN_HERE"

# ========================================
# 1. اختبار إشعار شات
# ========================================
chat_message = messaging.Message(
    notification=messaging.Notification(
        title="💬 رسالة جديدة من أحمد",
        body="مرحباً! كيف حالك؟",
    ),
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'conversation_id': '123',
    },
    android=messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='amina_chat_v2',
        ),
    ),
    token=fcm_token,
)

response = messaging.send(chat_message)
print(f"✅ Chat notification sent: {response}")

# ========================================
# 2. اختبار إشعار حجز
# ========================================
booking_message = messaging.Message(
    notification=messaging.Notification(
        title="📅 حجز جديد من سارة",
        body="خدمة: تنظيف منزل",
    ),
    data={
        'notification_type': 'BOOKING_CONFIRMED',
        'booking_id': '789',
    },
    android=messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='amina_urgent_v2',
        ),
    ),
    token=fcm_token,
)

response = messaging.send(booking_message)
print(f"✅ Booking notification sent: {response}")

# ========================================
# 3. اختبار Data-Only notification
# ========================================
data_only_message = messaging.Message(
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'title': 'رسالة اختبار',
        'body': 'هذا إشعار Data-Only',
    },
    android=messaging.AndroidConfig(priority='high'),
    token=fcm_token,
)

response = messaging.send(data_only_message)
print(f"✅ Data-only notification sent: {response}")
```

---

## 3. Django Management Command

### `management/commands/test_fcm.py`

```python
from django.core.management.base import BaseCommand
from firebase_admin import messaging
import firebase_admin
from firebase_admin import credentials


class Command(BaseCommand):
    help = 'Test FCM notifications'

    def add_arguments(self, parser):
        parser.add_argument('fcm_token', type=str, help='FCM device token')
        parser.add_argument(
            '--type',
            type=str,
            default='all',
            choices=['chat', 'booking', 'payment', 'offer', 'all'],
            help='Notification type to test'
        )

    def handle(self, *args, **options):
        fcm_token = options['fcm_token']
        notification_type = options['type']

        self.stdout.write(self.style.SUCCESS(f'Testing FCM notifications...'))
        self.stdout.write(f'Token: {fcm_token[:30]}...')
        self.stdout.write(f'Type: {notification_type}\n')

        # تهيئة Firebase إذا لم يكن مهيأ
        if not firebase_admin._apps:
            cred = credentials.Certificate('path/to/serviceAccountKey.json')
            firebase_admin.initialize_app(cred)

        if notification_type == 'chat' or notification_type == 'all':
            self.test_chat_notification(fcm_token)

        if notification_type == 'booking' or notification_type == 'all':
            self.test_booking_notification(fcm_token)

        if notification_type == 'payment' or notification_type == 'all':
            self.test_payment_notification(fcm_token)

        if notification_type == 'offer' or notification_type == 'all':
            self.test_offer_notification(fcm_token)

    def test_chat_notification(self, token):
        """Test chat notification"""
        self.stdout.write('\n📱 Testing chat notification...')

        message = messaging.Message(
            notification=messaging.Notification(
                title="💬 رسالة جديدة",
                body="اختبار صوت الشات",
            ),
            data={'notification_type': 'NEW_MESSAGE', 'type': 'chat'},
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='amina_chat_v2',
                ),
            ),
            token=token,
        )

        try:
            response = messaging.send(message)
            self.stdout.write(self.style.SUCCESS(f'✅ Chat notification sent: {response}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'❌ Error: {e}'))

    def test_booking_notification(self, token):
        """Test booking notification"""
        self.stdout.write('\n📅 Testing booking notification...')

        message = messaging.Message(
            notification=messaging.Notification(
                title="📅 حجز جديد",
                body="اختبار إشعار الحجز",
            ),
            data={'notification_type': 'BOOKING_CONFIRMED'},
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='amina_urgent_v2',
                ),
            ),
            token=token,
        )

        try:
            response = messaging.send(message)
            self.stdout.write(self.style.SUCCESS(f'✅ Booking notification sent: {response}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'❌ Error: {e}'))

    # ... باقي الدوال
```

### الاستخدام:

```bash
# اختبار جميع الأنواع
python manage.py test_fcm YOUR_FCM_TOKEN --type all

# اختبار نوع معين
python manage.py test_fcm YOUR_FCM_TOKEN --type chat
python manage.py test_fcm YOUR_FCM_TOKEN --type booking
```

---

## 4. اختبار من Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Cloud Messaging**
4. اضغط على **Send your first message**
5. املأ البيانات:

### للشات:
```
Title: 💬 رسالة اختبار
Body: اختبار صوت الشات

Additional options:
- Target: Single device
- FCM registration token: YOUR_TOKEN
- Custom data:
  * Key: notification_type, Value: NEW_MESSAGE
  * Key: type, Value: chat
```

### للحجز:
```
Title: 📅 حجز جديد
Body: اختبار إشعار الحجز

Additional options:
- Target: Single device
- FCM registration token: YOUR_TOKEN
- Custom data:
  * Key: notification_type, Value: BOOKING_CONFIRMED
```

---

## 5. اختبار باستخدام cURL

### إشعار شات:
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "💬 رسالة جديدة",
        "body": "اختبار صوت الشات"
      },
      "data": {
        "notification_type": "NEW_MESSAGE",
        "type": "chat"
      },
      "android": {
        "priority": "high",
        "notification": {
          "channel_id": "amina_chat_v2"
        }
      }
    }
  }'
```

### إشعار حجز:
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "📅 حجز جديد",
        "body": "اختبار إشعار الحجز"
      },
      "data": {
        "notification_type": "BOOKING_CONFIRMED"
      },
      "android": {
        "priority": "high",
        "notification": {
          "channel_id": "amina_urgent_v2"
        }
      }
    }
  }'
```

---

## 6. اختبار باستخدام Postman

### إعداد Postman:

1. **Method:** POST
2. **URL:** `https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send`
3. **Headers:**
   - `Authorization: Bearer YOUR_ACCESS_TOKEN`
   - `Content-Type: application/json`

### Body (اختبار شات):
```json
{
  "message": {
    "token": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "💬 رسالة جديدة",
      "body": "اختبار صوت الشات"
    },
    "data": {
      "notification_type": "NEW_MESSAGE",
      "type": "chat",
      "conversation_id": "123"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "amina_chat_v2",
        "sound": "default"
      }
    }
  }
}
```

### Body (اختبار حجز):
```json
{
  "message": {
    "token": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "📅 حجز جديد",
      "body": "اختبار إشعار الحجز"
    },
    "data": {
      "notification_type": "BOOKING_CONFIRMED",
      "booking_id": "789"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "amina_urgent_v2",
        "sound": "default"
      }
    }
  }
}
```

---

## 📊 جدول اختبار شامل:

| نوع الإشعار | `notification_type` | القناة | الصوت المتوقع | الاهتزاز |
|-------------|--------------------|---------|--------------|-----------|
| **شات** | `NEW_MESSAGE` | `amina_chat_v2` | `chat_sound.mp3` | سريع ✅ |
| **حجز** | `BOOKING_CONFIRMED` | `amina_urgent_v2` | `notification_sound.mp3` | طويل ✅ |
| **دفع** | `PAYMENT_SUCCESS` | `amina_urgent_v2` | `notification_sound.mp3` | طويل ✅ |
| **عرض** | `OFFER_SUBMITTED` | `amina_notifications_v2` | `notification_sound.mp3` | عادي ✅ |
| **عام** | `GENERAL` | `amina_notifications_v2` | `notification_sound.mp3` | عادي ✅ |

---

## ✅ Checklist للاختبار:

### قبل الاختبار:
- [ ] Firebase Admin SDK مثبت ومُعد
- [ ] Service Account Key متوفر
- [ ] FCM Token للجهاز متوفر
- [ ] التطبيق مثبت على الموبايل
- [ ] الأذونات ممنوحة للتطبيق

### أثناء الاختبار:
- [ ] اختبر إشعار شات (chat_sound.mp3)
- [ ] اختبر إشعار حجز (notification_sound.mp3)
- [ ] اختبر إشعار دفع (notification_sound.mp3)
- [ ] اختبر Data-Only notification
- [ ] اختبر مع التطبيق مفتوح
- [ ] اختبر مع التطبيق في الخلفية
- [ ] اختبر مع التطبيق مقفول

### بعد الاختبار:
- [ ] تأكد من ظهور الإشعارات
- [ ] تأكد من تشغيل الأصوات
- [ ] تأكد من الاهتزاز
- [ ] تأكد من فتح الصفحة الصحيحة عند النقر
- [ ] راجع Logs في Android Studio

---

**✅ جاهز للاختبار!** 🚀

استخدم السكريبتات أعلاه لاختبار نظام الإشعارات بشكل شامل.
