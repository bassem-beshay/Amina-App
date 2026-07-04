# 🔔 دليل كامل لإرسال Push Notifications من Backend

## 📋 جدول المحتويات
1. [نظرة عامة](#نظرة-عامة)
2. [شكل الإشعار المطلوب](#شكل-الإشعار-المطلوب)
3. [أمثلة من Backend (Django)](#أمثلة-من-backend-django)
4. [اختبار الإشعارات](#اختبار-الإشعارات)
5. [المشاكل الشائعة](#المشاكل-الشائعة)

---

## 🎯 نظرة عامة

التطبيق الآن يدعم **3 أنواع من الإشعارات**:

### ✅ 1. Notification + Data (مفضّل)
يظهر الإشعار تلقائياً حتى لو التطبيق **مقفول، في الخلفية، أو مفتوح**.

### ✅ 2. Data Only
يظهر الإشعار فقط لو التطبيق **مفتوح أو في الخلفية**.

### ❌ 3. Notification Only (غير مدعوم)
لا يمكن معالجة الإشعار عند النقر عليه.

---

## 📦 شكل الإشعار المطلوب

### ✅ الطريقة المثالية (Notification + Data)

```python
# Backend - Django Example
import firebase_admin
from firebase_admin import messaging

def send_notification(fcm_token, notification_type, data):
    message = messaging.Message(
        # ✅ قسم الإشعار (يظهر بره التطبيق)
        notification=messaging.Notification(
            title="رسالة جديدة",  # العنوان
            body="لديك رسالة جديدة من أحمد",  # النص
        ),

        # ✅ قسم البيانات (للتعامل داخل التطبيق)
        data={
            'notification_type': notification_type,  # مهم جداً!
            'type': 'chat',  # نوع الإشعار
            'conversation_id': '123',
            'booking_id': '456',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },

        # ✅ إعدادات Android
        android=messaging.AndroidConfig(
            priority='high',  # أولوية عالية
            notification=messaging.AndroidNotification(
                channel_id='amina_chat_v2',  # استخدام القناة المخصصة
                sound='default',  # الصوت الافتراضي
                priority='max',
                visibility='public',
            ),
        ),

        # ✅ إعدادات iOS (اختياري)
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(
                        title="رسالة جديدة",
                        body="لديك رسالة جديدة من أحمد",
                    ),
                    sound='default',
                    badge=1,
                ),
            ),
        ),

        token=fcm_token,
    )

    response = messaging.send(message)
    return response
```

---

### ✅ طريقة بديلة (Data Only)

```python
def send_data_only_notification(fcm_token, notification_type, data):
    message = messaging.Message(
        # ✅ بيانات فقط (Flutter يعرض الإشعار محلياً)
        data={
            'notification_type': notification_type,
            'type': 'chat',
            'title': 'رسالة جديدة',  # ✅ مهم!
            'body': 'لديك رسالة جديدة من أحمد',  # ✅ مهم!
            'conversation_id': '123',
            'booking_id': '456',
        },

        android=messaging.AndroidConfig(
            priority='high',
        ),

        token=fcm_token,
    )

    response = messaging.send(message)
    return response
```

⚠️ **ملاحظة:** لو استخدمت Data Only، لازم تضيف `title` و `body` في الـ `data`.

---

## 🔔 أنواع الإشعارات المدعومة

### 1️⃣ رسائل الشات (NEW_MESSAGE)

```python
send_notification(
    fcm_token=user.fcm_token,
    notification_type='NEW_MESSAGE',
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'conversation_id': str(conversation.id),
        'booking_id': str(booking.id),
        'sender_name': sender.get_full_name(),
    }
)
```

**قناة الإشعار:** `amina_chat_v2`
**الصوت:** مفعّل ✅
**الاهتزاز:** نمط قصير (300ms)

---

### 2️⃣ تأكيد الحجز (BOOKING_CONFIRMED)

```python
send_notification(
    fcm_token=provider.fcm_token,
    notification_type='BOOKING_CONFIRMED',
    data={
        'notification_type': 'BOOKING_CONFIRMED',
        'priority': 'high',
        'booking_id': str(booking.id),
        'client_name': client.get_full_name(),
        'service_name': service.name_ar,
    }
)
```

**قناة الإشعار:** `amina_urgent_v2`
**الصوت:** مفعّل ✅
**الاهتزاز:** نمط قوي (500ms × 3)
**LED:** بنفسجي 💜

---

### 3️⃣ عرض جديد (OFFER_SUBMITTED)

```python
send_notification(
    fcm_token=client.fcm_token,
    notification_type='OFFER_SUBMITTED',
    data={
        'notification_type': 'OFFER_SUBMITTED',
        'offer_id': str(offer.id),
        'booking_request_id': str(booking_request.id),
        'provider_name': provider.get_full_name(),
        'offered_price': str(offer.offered_price),
    }
)
```

**قناة الإشعار:** `amina_notifications_v2`
**الصوت:** مفعّل ✅
**الاهتزاز:** نمط متوسط (500ms)

---

### 4️⃣ دفع ناجح (PAYMENT_SUCCESS)

```python
send_notification(
    fcm_token=provider.fcm_token,
    notification_type='PAYMENT_SUCCESS',
    data={
        'notification_type': 'PAYMENT_SUCCESS',
        'priority': 'high',
        'booking_id': str(booking.id),
        'amount': str(payment.amount),
    }
)
```

**قناة الإشعار:** `amina_urgent_v2`

---

## 🧪 اختبار الإشعارات

### 1️⃣ اختبار من Firebase Console

1. افتح Firebase Console: https://console.firebase.google.com/
2. اذهب إلى **Cloud Messaging**
3. اضغط **Send your first message**
4. املأ:
   - **Notification title:** اختبار إشعار
   - **Notification text:** هذا إشعار تجريبي
5. في **Target:**
   - اختر **Single device**
   - الصق FCM Token من التطبيق
6. في **Additional options:**
   - **Android notification channel:** `amina_chat_v2`
   - **Sound:** Default sound
7. اضغط **Test** ثم **Send**

---

### 2️⃣ اختبار من Django Shell

```python
# في Django Shell
from firebase_admin import messaging
from users.models import User

# جلب المستخدم
user = User.objects.get(email='test@example.com')
fcm_token = user.fcm_devices.first().fcm_token

# إرسال إشعار تجريبي
message = messaging.Message(
    notification=messaging.Notification(
        title='اختبار إشعار',
        body='هذا إشعار تجريبي من Django',
    ),
    data={
        'notification_type': 'TEST',
        'type': 'test',
    },
    android=messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='amina_notifications_v2',
            sound='default',
        ),
    ),
    token=fcm_token,
)

response = messaging.send(message)
print(f'✅ Notification sent: {response}')
```

---

### 3️⃣ اختبار بواسطة curl

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "اختبار إشعار",
      "body": "هذا إشعار تجريبي",
      "sound": "default"
    },
    "data": {
      "notification_type": "TEST",
      "type": "test"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "amina_chat_v2",
        "sound": "default"
      }
    }
  }'
```

⚠️ استبدل `YOUR_SERVER_KEY` بـ Server Key من Firebase Console.

---

## ❌ المشاكل الشائعة وحلولها

### المشكلة 1: الإشعار مش بيظهر

**السبب المحتمل:**
- Backend بيبعت `data` فقط بدون `notification`
- FCM Token مش محفوظ صح
- الأذونات مرفوضة

**الحل:**
```python
# ✅ تأكد من إرسال notification + data
message = messaging.Message(
    notification=messaging.Notification(  # ✅ لازم يكون موجود
        title="العنوان",
        body="النص",
    ),
    data={ ... },
    token=fcm_token,
)
```

---

### المشكلة 2: الصوت مش شغال

**السبب المحتمل:**
- الموبايل في وضع صامت
- القناة (`channel_id`) غلط
- `sound` مش مضاف في الـ payload

**الحل:**
```python
# ✅ أضف sound في AndroidConfig
android=messaging.AndroidConfig(
    priority='high',
    notification=messaging.AndroidNotification(
        channel_id='amina_chat_v2',  # ✅ مهم!
        sound='default',  # ✅ مهم!
        priority='max',
    ),
)
```

---

### المشكلة 3: الإشعار بيظهر بس مش بيفتح التطبيق

**السبب المحتمل:**
- مفيش `data` في الـ payload
- مفيش `click_action`

**الحل:**
```python
data={
    'notification_type': 'NEW_MESSAGE',
    'click_action': 'FLUTTER_NOTIFICATION_CLICK',  # ✅ مهم!
    'conversation_id': '123',
}
```

---

### المشكلة 4: الإشعار بيظهر مرتين

**السبب المحتمل:**
- Backend بيبعت notification + Flutter بيعرض notification محلي

**الحل:**
- لو بتبعت `notification` من Backend، Flutter هيعرضها تلقائياً
- لو عايز تتحكم كامل، ابعت `data` فقط

---

## 📊 مقارنة بين الطرق

| الطريقة | التطبيق مفتوح | التطبيق في الخلفية | التطبيق مقفول | الصوت | التحكم الكامل |
|---------|---------------|-------------------|---------------|-------|---------------|
| **Notification + Data** | ✅ | ✅ | ✅ | ✅ | ⚠️ محدود |
| **Data Only** | ✅ | ✅ | ❌ | ✅ | ✅ كامل |
| **Notification Only** | ✅ | ✅ | ✅ | ✅ | ❌ لا يوجد |

**الطريقة المفضلة:** Notification + Data ✅

---

## 🔐 حفظ FCM Token في Backend

### Django Model Example:

```python
from django.db import models

class FCMDevice(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='fcm_devices')
    fcm_token = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(max_length=20, choices=[('android', 'Android'), ('ios', 'iOS')])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'fcm_token')
```

### Django View Example:

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_fcm_token(request):
    fcm_token = request.data.get('fcm_token')
    device_type = request.data.get('device_type', 'android')

    if not fcm_token:
        return Response({'error': 'FCM token is required'}, status=400)

    # حفظ أو تحديث FCM Token
    device, created = FCMDevice.objects.update_or_create(
        user=request.user,
        fcm_token=fcm_token,
        defaults={
            'device_type': device_type,
            'is_active': True,
        }
    )

    return Response({
        'success': True,
        'message': 'FCM token saved successfully',
        'device_id': device.id,
    })
```

---

## 🎯 ملخص سريع

### ✅ ما يجب فعله:
1. ✅ أرسل `notification` + `data` معاً
2. ✅ أضف `notification_type` في `data`
3. ✅ استخدم `channel_id` الصحيح
4. ✅ فعّل `sound` في `AndroidConfig`
5. ✅ اختبر على موبايل حقيقي

### ❌ ما يجب تجنبه:
1. ❌ لا ترسل `notification` فقط بدون `data`
2. ❌ لا تنسى `sound: 'default'`
3. ❌ لا تستخدم `channel_id` خطأ
4. ❌ لا تختبر على Emulator فقط

---

## 📞 للدعم

إذا واجهت أي مشكلة:
1. تحقق من Logs في Flutter: `flutter logs`
2. تحقق من Firebase Console → Cloud Messaging → Logs
3. تأكد من FCM Token محفوظ صح في Database
4. جرب الإرسال من Firebase Console أولاً

---

**تم التحديث:** 17 نوفمبر 2025
**الإصدار:** v2.0 - دعم Data-Only Notifications
