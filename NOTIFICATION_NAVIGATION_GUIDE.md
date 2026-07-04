# 🔔 دليل التنقل عند النقر على الإشعارات - Amina Platform

## 📋 نظرة عامة

عند النقر على الإشعار، يتم توجيه المستخدم للصفحة المناسبة **تلقائياً** حسب **نوع الإشعار** و**دور المستخدم**.

---

## 🎯 منطق التوجيه

### **القاعدة الأساسية:**

```
إشعار شات (NEW_MESSAGE)
    ↓
📱 فتح شاشة المحادثة مباشرة

إشعار عادي (حجز، عرض، دفع، إلخ)
    ↓
📋 فتح شاشة الإشعارات
```

---

## 👥 التوجيه حسب دور المستخدم

### **1️⃣ العميل (CLIENT) - CustomerHomeScreen**

#### **أ) إشعارات الشات:**
```dart
if (notification_type == 'NEW_MESSAGE') {
  // فتح شاشة الشات مباشرة
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        bookingId: conversation.bookingId,
        otherUserName: senderName,
      ),
    ),
  );
}
```

**البيانات المطلوبة في الإشعار:**
- `notification_type: 'NEW_MESSAGE'`
- `conversation_id: 123`
- `sender_name: 'أحمد'` (اختياري)

**مثال من Backend:**
```python
FCMService.send_notification(
    user=client,
    title='رسالة جديدة',
    body=f'لديك رسالة من {provider.get_full_name()}',
    notification_type='NEW_MESSAGE',
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'conversation_id': str(conversation.id),
        'sender_name': provider.get_full_name(),
    },
    sound='short_bang'  # صوت مميز للشات
)
```

---

#### **ب) الإشعارات العادية:**
```dart
else {
  // فتح شاشة الإشعارات
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NotificationsScreen(),
    ),
  );
}
```

**أمثلة الإشعارات العادية:**
- `OFFER_SUBMITTED` - عرض جديد من عاملة
- `BOOKING_CONFIRMED` - تأكيد الحجز
- `PAYMENT_SUCCESS` - نجاح الدفع
- `SERVICE_COMPLETED` - اكتمال الخدمة
- `RATING_RECEIVED` - تقييم جديد

**مثال من Backend:**
```python
FCMService.send_notification(
    user=client,
    title='عرض جديد',
    body=f'لديك عرض من {provider.get_full_name()} بسعر {offer.offered_price} جنيه',
    notification_type='OFFER_SUBMITTED',
    data={
        'notification_type': 'OFFER_SUBMITTED',
        'offer_id': str(offer.id),
        'booking_request_id': str(booking_request.id),
        'provider_name': provider.get_full_name(),
    },
    sound='notification_sound'
)
```

---

### **2️⃣ مقدم الخدمة (PROVIDER) - ProviderHomeScreen**

#### **أ) إشعارات الشات:**
```dart
if (notification_type == 'NEW_MESSAGE') {
  // جلب تفاصيل المحادثة
  final conversation = await ChatService.getConversationDetails(conversationId);

  // فتح شاشة الشات
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        bookingId: conversation.bookingId,
      ),
    ),
  );
}
```

**مثال من Backend:**
```python
FCMService.send_notification(
    user=provider,
    title='رسالة جديدة',
    body=f'لديك رسالة من {client.get_full_name()}',
    notification_type='NEW_MESSAGE',
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'conversation_id': str(conversation.id),
        'sender_name': client.get_full_name(),
    },
    sound='short_bang'
)
```

---

#### **ب) الإشعارات العادية:**
```dart
else {
  // فتح شاشة الإشعارات
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NotificationsScreen(),
    ),
  );
}
```

**أمثلة الإشعارات العادية:**
- `BOOKING_REQUEST_CREATED` - طلب حجز جديد
- `OFFER_ACCEPTED` - تم قبول عرضك
- `PAYMENT_RECEIVED` - استلام دفعة
- `BOOKING_STARTED` - بدء الخدمة
- `CLIENT_CONFIRMED_COMPLETION` - تأكيد العميل للخدمة

---

### **3️⃣ الإداري (ADMIN) - AdminDashboardScreen**

```dart
// جميع الإشعارات تذهب لصفحة الإشعارات
_navigateToNotifications();
```

**ملاحظة:** الأدمن عادة لا يستخدم الشات، لذلك جميع الإشعارات توجه لصفحة الإشعارات.

---

## 🔧 الكود التقني

### **A) في PushNotificationService:**

```dart
class PushNotificationService {
  // Stream للاستماع للإشعارات
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTapped => _notificationController.stream;

  // معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final Map<String, dynamic> data = json.decode(response.payload!);
      _notificationController.add(data);  // إرسال للـ listeners
    }
  }
}
```

---

### **B) في CustomerHomeScreen:**

```dart
void _setupNotificationListener() {
  PushNotificationService().onNotificationTapped.listen((data) async {
    // إشعار شات
    if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
      final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');
      if (conversationId != null) {
        await _navigateToChatFromConversation(conversationId, senderName);
      }
    }
    // إشعار عادي
    else {
      _navigateToNotifications();
    }
  });
}

Future<void> _navigateToChatFromConversation(int conversationId, String senderName) async {
  final conversation = await ChatService.getConversationDetails(conversationId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        bookingId: conversation.bookingId,
        otherUserName: senderName,
      ),
    ),
  );
}

void _navigateToNotifications() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
  );
}
```

---

### **C) في ProviderHomeScreen:**

```dart
void _setupNotificationListener() {
  PushNotificationService().onNotificationTapped.listen((data) {
    // إشعار شات
    if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        _navigateToChat(int.tryParse(conversationId.toString()));
      }
    }
    // إشعار عادي
    else {
      _navigateToNotifications();
    }
  });
}

Future<void> _navigateToChat(int? conversationId) async {
  if (conversationId == null) return;

  final conversation = await ChatService.getConversationDetails(conversationId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        bookingId: conversation.bookingId,
      ),
    ),
  );
}

void _navigateToNotifications() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
  );
}
```

---

## 📊 جدول أنواع الإشعارات والتوجيه

| نوع الإشعار | notification_type | الصفحة المستهدفة | الصوت | المستخدم |
|-------------|-------------------|------------------|-------|---------|
| **رسالة شات** | `NEW_MESSAGE` | ChatScreen | `short_bang` | Client/Provider |
| **عرض جديد** | `OFFER_SUBMITTED` | NotificationsScreen | `notification_sound` | Client |
| **قبول عرض** | `OFFER_ACCEPTED` | NotificationsScreen | `notification_sound` | Provider |
| **تأكيد حجز** | `BOOKING_CONFIRMED` | NotificationsScreen | `notification_sound` | Client/Provider |
| **دفع ناجح** | `PAYMENT_SUCCESS` | NotificationsScreen | `notification_sound` | Client/Provider |
| **بدء خدمة** | `BOOKING_STARTED` | NotificationsScreen | `notification_sound` | Client/Provider |
| **اكتمال خدمة** | `SERVICE_COMPLETED` | NotificationsScreen | `notification_sound` | Client/Provider |
| **تقييم** | `RATING_RECEIVED` | NotificationsScreen | `notification_sound` | Provider |

---

## 🧪 اختبار النظام

### **1️⃣ اختبار إشعار الشات:**

**Backend (Django Shell):**
```python
from users.fcm_service import FCMService
from users.models import User

# جلب المستخدم
user = User.objects.get(email='test@example.com')

# إرسال إشعار شات
FCMService.send_notification(
    user=user,
    title='رسالة جديدة',
    body='لديك رسالة من أحمد',
    notification_type='NEW_MESSAGE',
    data={
        'notification_type': 'NEW_MESSAGE',
        'type': 'chat',
        'conversation_id': '123',
        'sender_name': 'أحمد',
    },
    sound='short_bang'
)
```

**النتيجة المتوقعة:**
1. ✅ الإشعار يظهر مع صوت `short_bang.mp3`
2. ✅ النقر على الإشعار يفتح ChatScreen مباشرة
3. ✅ الشات يحمل المحادثة رقم 123

---

### **2️⃣ اختبار إشعار عادي:**

**Backend (Django Shell):**
```python
FCMService.send_notification(
    user=user,
    title='عرض جديد',
    body='لديك عرض بسعر 500 جنيه',
    notification_type='OFFER_SUBMITTED',
    data={
        'notification_type': 'OFFER_SUBMITTED',
        'offer_id': '456',
        'provider_name': 'فاطمة',
    },
    sound='notification_sound'
)
```

**النتيجة المتوقعة:**
1. ✅ الإشعار يظهر مع صوت `notification_sound.mp3`
2. ✅ النقر على الإشعار يفتح NotificationsScreen
3. ✅ يظهر الإشعار في القائمة

---

## 🔍 Debugging

### **مشكلة: الإشعار يظهر لكن النقر لا يفعل شيء**

**السبب المحتمل:**
- مفيش `data` في الـ notification payload

**الحل:**
```python
# ✅ تأكد من إرسال data
message = messaging.Message(
    notification=messaging.Notification(...),
    data={
        'notification_type': 'NEW_MESSAGE',  # مهم جداً!
        'conversation_id': '123',
    },
    token=fcm_token,
)
```

---

### **مشكلة: الإشعار يفتح NotificationsScreen بدلاً من ChatScreen**

**السبب المحتمل:**
- `notification_type` مش `NEW_MESSAGE`
- أو `type` مش `chat`

**الحل:**
```python
# ✅ تأكد من الشروط
data={
    'notification_type': 'NEW_MESSAGE',  # ✅ مهم!
    'type': 'chat',  # ✅ مهم!
    'conversation_id': '123',
}
```

---

### **مشكلة: Error عند النقر**

**السبب المحتمل:**
- `conversation_id` مش موجود في الـ data

**الحل:**
```dart
// التحقق من وجود conversation_id
final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');
if (conversationId != null) {
  // فتح الشات
}
```

---

## 📝 ملخص سريع

### ✅ **ما تم تنفيذه:**

1. ✅ **CustomerHomeScreen** - معالج كامل للإشعارات
2. ✅ **ProviderHomeScreen** - معالج كامل للإشعارات
3. ✅ **AdminDashboardScreen** - معالج للإشعارات
4. ✅ **PushNotificationService** - Stream للاستماع
5. ✅ **توجيه ذكي** - شات → ChatScreen، عادي → NotificationsScreen
6. ✅ **أصوات مخصصة** - short_bang للشات، notification_sound للعادي

### 🎯 **كيف يعمل النظام:**

```
FCM ترسل Notification
    ↓
PushNotificationService يستقبل
    ↓
_onNotificationTapped تُستدعى
    ↓
تحويل payload إلى Map<String, dynamic>
    ↓
إرسال البيانات عبر Stream
    ↓
CustomerHomeScreen/ProviderHomeScreen يستقبل
    ↓
فحص notification_type
    ↓
إذا NEW_MESSAGE → ChatScreen
إذا غير ذلك → NotificationsScreen
```

---

## 🎉 النتيجة النهائية

✅ **إشعار شات** → يفتح شاشة المحادثة مباشرة 💬
✅ **إشعار عادي** → يفتح شاشة الإشعارات 📋
✅ **الأصوات مختلفة** → تجربة مستخدم مميزة 🔊
✅ **يعمل في جميع الحالات** → Foreground, Background, Terminated 🚀

---

**تاريخ الإنشاء:** 20 نوفمبر 2025
**الحالة:** ✅ مكتمل ويعمل بنجاح
**الإصدار:** v1.0
