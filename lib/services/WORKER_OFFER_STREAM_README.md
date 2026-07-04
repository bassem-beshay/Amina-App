# WorkerOfferStreamService - تحديثات فورية للعروض

## المشكلة المحلولة

### ❌ المشكلة القديمة:
```dart
// العميل فاتح صفحة العروض
final offers = await WorkerOfferService.getOffers(bookingRequestId: 123);

// ❌ العاملة قدمت عرض جديد
// ❌ العميل لن يرى العرض إلا لما يعمل refresh يدوي
// ❌ لازم يخرج من الصفحة ويرجع أو يسحب لأسفل (pull-to-refresh)
```

### ✅ الحل الجديد:
```dart
// العميل فاتح صفحة العروض
Stream<List<WorkerOffer>> stream = WorkerOfferStreamService().offersStream;

// ✅ العاملة قدمت عرض جديد
// ✅ العرض يظهر فورًا للعميل (خلال 8 ثواني)
// ✅ بدون أي تدخل من العميل!
// 🔥 تجربة real-time مثل WhatsApp تمامًا
```

---

## كيف يشتغل؟

### 1. الاستخدام الأساسي للعميل

```dart
import 'package:flutter/material.dart';
import '../services/worker_offer_stream_service.dart';
import '../models/worker_offer_model.dart';

class ClientOffersScreen extends StatefulWidget {
  final int bookingRequestId;

  @override
  State<ClientOffersScreen> createState() => _ClientOffersScreenState();
}

class _ClientOffersScreenState extends State<ClientOffersScreen> {
  final WorkerOfferStreamService _streamService = WorkerOfferStreamService();

  @override
  void initState() {
    super.initState();

    // بدء الاستماع للعروض على طلب حجز معين
    _streamService.startListening(
      bookingRequestId: widget.bookingRequestId,
      pollInterval: Duration(seconds: 8), // التحديث كل 8 ثواني
      immediate: true,
    );
  }

  @override
  void dispose() {
    _streamService.stopListening(); // cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العروض المقدمة'),
        actions: [
          // عداد العروض الجديدة
          StreamBuilder<int>(
            stream: _streamService.newOffersCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return SizedBox.shrink();

              return Badge(
                label: Text('$count'),
                child: Icon(Icons.notifications),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<WorkerOffer>>(
        stream: _streamService.offersStream, // 🔥 Real-time!
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          final offers = snapshot.data ?? [];

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return OfferCard(offer: offers[index]);
            },
          );
        },
      ),
    );
  }
}
```

---

## المميزات الرئيسية

### 1️⃣ **Stream للعروض** (Real-time List)

```dart
WorkerOfferStreamService streamService = WorkerOfferStreamService();

// الاستماع للعروض على طلب حجز معين
streamService.offersStream.listen((offers) {
  print('تم استلام ${offers.length} عرض');
  // ✅ القائمة تتحدث تلقائيًا كل 8 ثواني
  // ✅ لما عاملة تقدم عرض جديد، يظهر فورًا
});
```

### 2️⃣ **Stream لعداد العروض الجديدة** (New Offers Count)

```dart
// عرض عداد العروض الجديدة (pending) في AppBar
StreamBuilder<int>(
  stream: streamService.newOffersCountStream,
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;

    return Badge(
      label: Text('$count عرض جديد'),
      child: Icon(Icons.work),
    );
  },
)
```

### 3️⃣ **قبول عرض مع تحديث فوري**

```dart
// عند قبول عرض
await streamService.acceptOffer(offerId);

// ✅ الـ UI يتحدث تلقائيًا!
// ✅ حالة العرض تتغير من pending إلى accepted
// ✅ العداد ينقص تلقائيًا
// ❌ مش محتاج setState() أو refresh
```

### 4️⃣ **التصفية حسب طلب الحجز**

```dart
// جلب العروض على طلب حجز معين (للعميل)
streamService.startListening(bookingRequestId: 123);

// جلب كل العروض (للعاملة - لرؤية عروضها)
streamService.startListening(); // بدون bookingRequestId
```

### 5️⃣ **تخصيص مدة التحديث**

```dart
// تحديثات سريعة (كل 5 ثواني) - للعروض المهمة
streamService.startListening(pollInterval: Duration(seconds: 5));

// تحديثات عادية (كل 10 ثواني)
streamService.startListening(pollInterval: Duration(seconds: 10));
```

---

## أمثلة الاستخدام

### مثال 1: صفحة عروض العميل (Real-time)

```dart
// في صفحة تفاصيل طلب الحجز
ElevatedButton(
  child: Text('عرض العروض المقدمة'),
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ClientOffersStreamScreen(
        bookingRequestId: bookingRequest.id,
      ),
    ));
  },
)
```

### مثال 2: عرض Badge للعروض الجديدة

```dart
class BookingRequestCard extends StatelessWidget {
  final BookingRequest bookingRequest;

  @override
  Widget build(BuildContext context) {
    final streamService = WorkerOfferStreamService();

    // بدء الاستماع للعروض على هذا الطلب
    streamService.startListening(
      bookingRequestId: bookingRequest.id,
      immediate: false, // لا نريد جلب فوري
    );

    return Card(
      child: ListTile(
        title: Text(bookingRequest.serviceName),
        trailing: StreamBuilder<int>(
          stream: streamService.newOffersCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            if (count == 0) return SizedBox.shrink();

            return Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ClientOffersStreamScreen(
            bookingRequestId: bookingRequest.id,
          ),
        )),
      ),
    );
  }
}
```

### مثال 3: إشعار عند وصول عرض جديد

```dart
class MyHomeScreen extends StatefulWidget {
  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final WorkerOfferStreamService _streamService = WorkerOfferStreamService();
  int _lastOfferCount = 0;

  @override
  void initState() {
    super.initState();

    _streamService.startListening(bookingRequestId: myBookingRequestId);

    // الاستماع للتغييرات
    _streamService.offersStream.listen((offers) {
      final pendingOffers = offers.where((o) => o.status == 'pending').toList();

      // إذا زاد عدد العروض
      if (pendingOffers.length > _lastOfferCount) {
        // عرض notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 8),
                Text('لديك عرض جديد!'),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'عرض',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ClientOffersStreamScreen(
                    bookingRequestId: myBookingRequestId,
                  ),
                ));
              },
            ),
          ),
        );
      }

      _lastOfferCount = pendingOffers.length;
    });
  }

  @override
  void dispose() {
    _streamService.stopListening();
    super.dispose();
  }

  // ...
}
```

---

## السيناريو الكامل: من تقديم العرض إلى القبول

### خطوة 1: العميل ينشئ طلب حجز

```dart
// العميل ينشئ طلب حجز
await BookingService.createBookingRequest(...);

// العميل يفتح صفحة العروض ويستنى
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ClientOffersStreamScreen(bookingRequestId: request.id),
));
```

### خطوة 2: العاملة تقدم عرض

```dart
// العاملة تشوف الطلب وتقدم عرض
await WorkerOfferService.createOffer(
  bookingRequestId: request.id,
  priceAction: 'counter',
  offeredPrice: 150.0,
  message: 'أستطيع القيام بالخدمة بجودة عالية',
);
```

### خطوة 3: العرض يظهر فورًا للعميل ✨

```dart
// 🔥 تلقائيًا (بدون أي كود إضافي):
// 1. الـ WorkerOfferStreamService يجلب العرض الجديد (خلال 8 ثواني)
// 2. الـ StreamBuilder يبني الـ UI من جديد
// 3. العميل يشوف العرض الجديد فورًا
// 4. العداد يتحدث من 0 إلى 1
```

### خطوة 4: العميل يقبل العرض

```dart
// العميل يضغط "قبول العرض"
await streamService.acceptOffer(offer.id);

// ✅ حالة العرض تتحدث من pending إلى accepted
// ✅ يتم إنشاء Booking تلقائيًا
// ✅ الـ UI يتحدث فورًا بدون refresh
```

---

## الفرق الأساسي: قبل وبعد

### ❌ الطريقة القديمة

```dart
class OldOffersScreen extends StatefulWidget {
  final int bookingRequestId;

  @override
  State<OldOffersScreen> createState() => _OldOffersScreenState();
}

class _OldOffersScreenState extends State<OldOffersScreen> {
  List<WorkerOffer> offers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => isLoading = true);
    offers = await WorkerOfferService.getOffers(
      bookingRequestId: widget.bookingRequestId,
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ❌ مشاكل:
    // 1. العروض الجديدة لا تظهر تلقائيًا
    // 2. لازم pull-to-refresh يدوي
    // 3. تجربة مستخدم سيئة

    return RefreshIndicator(
      onRefresh: _loadOffers, // يدوي!
      child: ListView(...),
    );
  }
}
```

### ✅ الطريقة الجديدة

```dart
class NewOffersScreen extends StatefulWidget {
  final int bookingRequestId;

  @override
  State<NewOffersScreen> createState() => _NewOffersScreenState();
}

class _NewOffersScreenState extends State<NewOffersScreen> {
  final WorkerOfferStreamService _streamService = WorkerOfferStreamService();

  @override
  void initState() {
    super.initState();
    _streamService.startListening(
      bookingRequestId: widget.bookingRequestId,
    ); // ✅ تشغيل واحد فقط
  }

  @override
  void dispose() {
    _streamService.stopListening(); // ✅ cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ مميزات:
    // 1. العروض الجديدة تظهر تلقائيًا (كل 8 ثواني)
    // 2. مفيش setState() يدوي
    // 3. تجربة مستخدم احترافية 🔥

    return StreamBuilder<List<WorkerOffer>>(
      stream: _streamService.offersStream,
      builder: (context, snapshot) {
        final offers = snapshot.data ?? [];
        return ListView(...);
      },
    );
  }
}
```

---

## التكامل مع NotificationStreamService

يمكنك دمج الـ Notifications مع الـ Offers:

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationStreamService _notifService = NotificationStreamService();
  final WorkerOfferStreamService _offerService = WorkerOfferStreamService();

  @override
  void initState() {
    super.initState();

    // تشغيل الإشعارات
    _notifService.startListening();

    // تشغيل العروض
    _offerService.startListening(bookingRequestId: myRequestId);

    // الاستماع للإشعارات من نوع "عرض جديد"
    _notifService.notificationsStream.listen((notifications) {
      for (var notif in notifications) {
        if (notif.notificationType == 'OFFER_SUBMITTED' && !notif.isRead) {
          // عرض جديد وصل!
          _showNewOfferDialog(notif);
        }
      }
    });
  }

  @override
  void dispose() {
    _notifService.stopListening();
    _offerService.stopListening();
    super.dispose();
  }

  void _showNewOfferDialog(NotificationModel notif) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('عرض جديد وصل!'),
        content: Text(notif.message),
        actions: [
          TextButton(
            child: Text('عرض العرض'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClientOffersStreamScreen(
                  bookingRequestId: myRequestId,
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  // ...
}
```

---

## الأسئلة الشائعة

### س: هل يستهلك بطارية كثير؟

**ج:** لا، لأن:
- الـ polling كل 8 ثواني (وليس كل ثانية)
- يتوقف تلقائيًا عند الخروج من الصفحة
- يمكنك زيادة المدة إلى 15 ثانية لتوفير أكثر

### س: هل أقدر أوقف وأشغل الـ stream؟

**ج:** نعم:
```dart
// إيقاف
streamService.stopListening();

// تشغيل
streamService.startListening(bookingRequestId: 123);
```

### س: هل يشتغل مع أكثر من طلب حجز؟

**ج:** نعم، لكن يفضل استخدام instance منفصل لكل طلب:
```dart
final streamService1 = WorkerOfferStreamService();
streamService1.startListening(bookingRequestId: 123);

// لا يمكن - singleton pattern
// final streamService2 = WorkerOfferStreamService();
// streamService2.startListening(bookingRequestId: 456);
```

**الحل:** غير bookingRequestId:
```dart
streamService.setBookingRequestId(456); // تلقائيًا يجلب عروض جديدة
```

### س: لو العاملة سحبت عرضها؟

**ج:** الـ stream يتحدث تلقائيًا:
```dart
// العاملة تسحب العرض
await streamService.withdrawOffer(offerId);

// ✅ العميل يشوف حالة العرض تتغير من pending إلى withdrawn
```

---

## الخلاصة

### قبل: تجربة بطيئة ❌

- العميل يفتح صفحة العروض
- العاملة تقدم عرض
- **العميل لا يرى العرض**
- العميل يخرج ويرجع
- الآن يشوف العرض

### بعد: تجربة real-time ✅

- العميل يفتح صفحة العروض
- العاملة تقدم عرض
- **العميل يشوف العرض فورًا (خلال 8 ثواني)**
- تجربة احترافية مثل WhatsApp 🔥

---

## الملفات المطلوبة

1. ✅ `lib/services/worker_offer_stream_service.dart` - الخدمة الأساسية
2. ✅ `lib/screens/client_offers_stream_screen.dart` - صفحة العروض بـ Stream
3. ✅ `lib/services/worker_offer_service.dart` - موجود بالفعل
4. ✅ `lib/models/worker_offer_model.dart` - موجود بالفعل

---

## البدء الآن

```dart
// استبدل صفحة العروض القديمة بالجديدة:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ClientOffersStreamScreen(
    bookingRequestId: bookingRequest.id,
  ),
));
```

🎉 **الآن العروض تظهر فورًا بدون refresh!**
