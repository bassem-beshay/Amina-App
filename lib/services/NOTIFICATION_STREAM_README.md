# NotificationStreamService - تحديثات فورية للإشعارات

## ما هي المشكلة التي يحلها؟

### المشكلة الحالية ❌
```dart
// الطريقة القديمة - API call واحد فقط
final notifications = await NotificationService.getNotifications();
// ❌ لو جاء notification جديد، مش هيظهر إلا لما تعمل refresh يدوي
// ❌ لازم تخرج من الصفحة وترجع تاني
```

### الحل الجديد ✅
```dart
// الطريقة الجديدة - Real-time Stream (يشبه Firestore snapshots)
Stream<List<NotificationModel>> stream = NotificationStreamService().notificationsStream;
// ✅ التحديثات تحصل تلقائيًا كل 10 ثواني
// ✅ لو جاء notification جديد، يظهر فورًا بدون تدخل منك
```

---

## كيف يشتغل؟

### 1. التشغيل الأساسي

```dart
import 'package:flutter/material.dart';
import '../services/notification_stream_service.dart';
import '../models/notification_model.dart';

class MyNotificationsScreen extends StatefulWidget {
  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  final NotificationStreamService _streamService = NotificationStreamService();

  @override
  void initState() {
    super.initState();

    // بدء الاستماع - يشبه onSnapshot في Firestore
    _streamService.startListening(
      pollInterval: Duration(seconds: 10), // التحديث كل 10 ثواني
      immediate: true, // جلب البيانات فورًا
    );
  }

  @override
  void dispose() {
    // إيقاف الاستماع عند الخروج
    _streamService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _streamService.notificationsStream, // 🔥 هنا السحر!
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final notifications = snapshot.data ?? [];

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(notifications[index].message),
            );
          },
        );
      },
    );
  }
}
```

---

## المميزات الرئيسية

### 1️⃣ **Stream للإشعارات** (Real-time List)

```dart
NotificationStreamService streamService = NotificationStreamService();

// الاستماع للإشعارات
streamService.notificationsStream.listen((notifications) {
  print('تم استلام ${notifications.length} إشعار');
  // ✅ يتم تحديث القائمة تلقائيًا كل 10 ثواني
});
```

### 2️⃣ **Stream لعداد الإشعارات غير المقروءة** (Unread Count)

```dart
// عرض عداد الإشعارات في AppBar
StreamBuilder<int>(
  stream: streamService.unreadCountStream,
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;

    return Badge(
      label: Text('$unreadCount'),
      child: Icon(Icons.notifications),
    );
  },
)
```

### 3️⃣ **تحديث فوري بعد Mark as Read**

```dart
// عند الضغط على notification
onTap: () async {
  // تحديد كمقروء
  await streamService.markAsRead(notification.id);

  // ✅ الـ UI يتحدث تلقائيًا!
  // ✅ العداد ينقص تلقائيًا!
  // ❌ مش محتاج setState() أو refresh يدوي
}
```

### 4️⃣ **Pull-to-Refresh**

```dart
RefreshIndicator(
  onRefresh: () => streamService.refresh(),
  child: ListView(...),
)
```

### 5️⃣ **تخصيص مدة التحديث**

```dart
// التحديث كل 5 ثواني (للتطبيقات الحساسة للوقت)
streamService.startListening(pollInterval: Duration(seconds: 5));

// التحديث كل 30 ثانية (لتقليل استهلاك البطارية)
streamService.startListening(pollInterval: Duration(seconds: 30));

// أو تغيير المدة أثناء التشغيل
streamService.setPollInterval(Duration(seconds: 15));
```

---

## أمثلة الاستخدام

### مثال 1: NotificationBadge في AppBar

```dart
AppBar(
  title: Text('الرئيسية'),
  actions: [
    IconButton(
      icon: NotificationBadge(), // ✅ العداد يتحدث تلقائيًا
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NotificationsScreenExample(),
        ));
      },
    ),
  ],
)
```

### مثال 2: التشغيل في main.dart (Global)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل الخدمة عند فتح التطبيق
  NotificationStreamService().startListening(
    pollInterval: Duration(seconds: 15),
  );

  runApp(MyApp());
}
```

### مثال 3: عرض Snackbar عند notification جديد

```dart
NotificationStreamService streamService = NotificationStreamService();
int lastCount = 0;

streamService.notificationsStream.listen((notifications) {
  final newCount = notifications.length;

  if (newCount > lastCount) {
    // إشعار جديد وصل!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لديك إشعار جديد!')),
    );
  }

  lastCount = newCount;
});
```

---

## المقارنة: قبل وبعد

### ❌ الطريقة القديمة (One-time API Call)

```dart
class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    notifications = await NotificationService.getNotifications();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ❌ مشاكل:
    // - لازم تعمل refresh يدوي لرؤية إشعارات جديدة
    // - لو جاء notification وأنت في الصفحة، مش هيظهر
    // - كل مرة تدخل الصفحة، تعمل setState

    return RefreshIndicator(
      onRefresh: _loadNotifications, // refresh يدوي
      child: ListView(...),
    );
  }
}
```

### ✅ الطريقة الجديدة (Real-time Stream)

```dart
class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationStreamService _streamService = NotificationStreamService();

  @override
  void initState() {
    super.initState();
    _streamService.startListening(); // ✅ تشغيل واحد فقط
  }

  @override
  void dispose() {
    _streamService.stopListening(); // ✅ cleanup تلقائي
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ مميزات:
    // - التحديثات تحصل تلقائيًا كل 10 ثواني
    // - لو جاء notification جديد، يظهر فورًا
    // - مفيش setState() يدوي
    // - الـ StreamBuilder يدير كل شيء

    return StreamBuilder<List<NotificationModel>>(
      stream: _streamService.notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        return ListView(...);
      },
    );
  }
}
```

---

## الفرق بين الطريقة الجديدة و Firestore Snapshots

### Firestore (Real Database)

```dart
// Firestore - تحديثات فورية من الـ database
FirebaseFirestore.instance
  .collection('notifications')
  .snapshots() // ✅ تحديثات فورية من السيرفر
  .listen((snapshot) {
    // يتم استدعاء هذا الكود عند أي تغيير في الـ database
  });
```

### NotificationStreamService (REST API Polling)

```dart
// NotificationStreamService - تحديثات دورية من REST API
NotificationStreamService()
  .notificationsStream // ✅ تحديثات كل X ثواني من الـ API
  .listen((notifications) {
    // يتم استدعاء هذا الكود كل 10 ثواني (أو حسب المدة المحددة)
  });
```

**الفرق:**
- **Firestore**: تحديثات **فورية** عند حدوث تغيير (WebSocket)
- **NotificationStreamService**: تحديثات **دورية** كل X ثواني (HTTP Polling)

**لكن:**
- كلاهما يستخدم `StreamBuilder` بنفس الطريقة
- كلاهما يحدث الـ UI تلقائيًا
- كلاهما لا يحتاج `setState()` يدوي

---

## أفضل الممارسات

### 1. استخدم Singleton Pattern

```dart
// ✅ استخدم نفس الـ instance في كل التطبيق
final NotificationStreamService globalStreamService = NotificationStreamService();

// في أي مكان في التطبيق
globalStreamService.notificationsStream.listen(...);
```

### 2. أوقف الاستماع عند عدم الحاجة

```dart
@override
void dispose() {
  _streamService.stopListening(); // ✅ توفير البطارية
  super.dispose();
}
```

### 3. استخدم مدة مناسبة حسب الحالة

```dart
// Chat app - تحديثات سريعة
streamService.startListening(pollInterval: Duration(seconds: 5));

// News app - تحديثات بطيئة
streamService.startListening(pollInterval: Duration(minutes: 1));
```

### 4. استخدم error handling

```dart
StreamBuilder<List<NotificationModel>>(
  stream: streamService.notificationsStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error); // ✅ معالجة الأخطاء
    }
    // ...
  },
)
```

---

## الملفات المطلوبة

1. ✅ `lib/services/notification_stream_service.dart` - الخدمة الأساسية
2. ✅ `lib/screens/notifications/notifications_screen_example.dart` - مثال كامل
3. ✅ `lib/services/notification_service.dart` - موجود بالفعل
4. ✅ `lib/models/notification_model.dart` - موجود بالفعل

---

## الخلاصة

### لماذا نستخدم Snapshot (Stream) بدل API Call عادي؟

| الميزة | API Call عادي | Stream (Snapshot) |
|--------|---------------|-------------------|
| **التحديثات** | يدوي (refresh) | تلقائي (كل X ثواني) |
| **الإشعارات الجديدة** | لا تظهر إلا بعد refresh | تظهر تلقائيًا |
| **كود أقل** | تحتاج setState يدوي | StreamBuilder يديرها |
| **تجربة مستخدم** | عادية | احترافية ⭐ |
| **مثل Firestore** | ❌ | ✅ (تقريبًا) |

---

## استخدام الآن!

```dart
// في أي صفحة إشعارات:
import '../services/notification_stream_service.dart';

// بدء الاستماع
NotificationStreamService().startListening();

// استخدام StreamBuilder
StreamBuilder<List<NotificationModel>>(
  stream: NotificationStreamService().notificationsStream,
  builder: (context, snapshot) {
    final notifications = snapshot.data ?? [];
    return ListView(...);
  },
)
```

🎉 **الآن عندك نظام إشعارات real-time مثل Firestore تمامًا!**
