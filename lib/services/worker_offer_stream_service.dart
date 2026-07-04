import 'dart:async';
import '../models/worker_offer_model.dart';
import 'worker_offer_service.dart';

/// خدمة لتوفير تحديثات real-time للعروض (Worker Offers) عبر Stream
/// مفيدة للعميل لرؤية العروض الجديدة فورًا بدون refresh
class WorkerOfferStreamService {
  // Singleton pattern
  static final WorkerOfferStreamService _instance = WorkerOfferStreamService._internal();
  factory WorkerOfferStreamService() => _instance;
  WorkerOfferStreamService._internal();

  // Stream controller للعروض
  final StreamController<List<WorkerOffer>> _offersController =
      StreamController<List<WorkerOffer>>.broadcast();

  // Stream controller لعداد العروض الجديدة (pending)
  final StreamController<int> _newOffersCountController =
      StreamController<int>.broadcast();

  // Timer للتحديث الدوري
  Timer? _pollTimer;

  // آخر قائمة عروض تم جلبها (للمقارنة)
  List<WorkerOffer> _lastOffers = [];

  // مدة التحديث (يمكن تخصيصها)
  Duration _pollInterval = const Duration(seconds: 8);

  // حالة الخدمة
  bool _isActive = false;

  // معرف طلب الحجز (booking request ID) - للتصفية
  int? _bookingRequestId;

  /// الحصول على stream العروض
  /// مشابه لـ Firestore: collection('worker_offers').snapshots()
  Stream<List<WorkerOffer>> get offersStream => _offersController.stream;

  /// الحصول على stream عداد العروض الجديدة (pending)
  Stream<int> get newOffersCountStream => _newOffersCountController.stream;

  /// بدء الاستماع للتحديثات (يشبه onSnapshot)
  ///
  /// [bookingRequestId] - معرف طلب الحجز (للعميل: لجلب العروض على طلب معين)
  /// [pollInterval] - المدة بين كل تحديث (افتراضي: 8 ثواني)
  /// [immediate] - هل نجلب البيانات فورًا أم ننتظر أول interval
  void startListening({
    int? bookingRequestId,
    Duration? pollInterval,
    bool immediate = true,
  }) {
    if (_isActive) {
      return;
    }

    _isActive = true;
    _bookingRequestId = bookingRequestId;

    if (pollInterval != null) {
      _pollInterval = pollInterval;
    }

    if (_bookingRequestId != null) {
    }

    // جلب البيانات فورًا إذا كان مطلوب
    if (immediate) {
      _fetchAndEmit();
    }

    // بدء الـ polling
    _pollTimer = Timer.periodic(_pollInterval, (timer) {
      _fetchAndEmit();
    });
  }

  /// إيقاف الاستماع (cleanup)
  void stopListening() {
    if (!_isActive) return;

    _pollTimer?.cancel();
    _pollTimer = null;
    _isActive = false;

  }

  /// جلب البيانات وإرسالها عبر الـ stream
  Future<void> _fetchAndEmit() async {
    try {
      // جلب العروض من الـ API
      final offers = await WorkerOfferService.getOffers(
        bookingRequestId: _bookingRequestId,
      );

      // التحقق من وجود تغييرات (لتجنب إرسال نفس البيانات)
      if (_hasChanges(offers)) {
        // حفظ آخر نسخة
        _lastOffers = List.from(offers);

        // إرسال البيانات عبر الـ stream
        if (!_offersController.isClosed) {
          _offersController.add(offers);
        }

        // حساب وإرسال عداد العروض الجديدة (pending)
        final newOffersCount = offers.where((o) => o.status == 'pending').length;
        if (!_newOffersCountController.isClosed) {
          _newOffersCountController.add(newOffersCount);
        }


        // عرض رسالة عند وصول عرض جديد
        if (newOffersCount > 0 && _lastOffers.length < offers.length) {
        }
      }
    } catch (e) {
      // إرسال error عبر الـ stream
      if (!_offersController.isClosed) {
        _offersController.addError(e);
      }
    }
  }

  /// التحقق من وجود تغييرات في البيانات
  bool _hasChanges(List<WorkerOffer> newOffers) {
    // إذا كان العدد مختلف، فهناك تغيير
    if (newOffers.length != _lastOffers.length) {
      return true;
    }

    // مقارنة IDs و status
    for (int i = 0; i < newOffers.length; i++) {
      final newOffer = newOffers[i];
      final oldOffer = _lastOffers.firstWhere(
        (o) => o.id == newOffer.id,
        orElse: () => WorkerOffer(
          id: -1,
          bookingRequestId: -1,
          workerId: -1,
          priceAction: '',
          offeredPrice: 0.0,
          status: '',
          createdAt: DateTime.now(),
        ),
      );

      // إذا العرض جديد أو تغيرت حالته
      if (oldOffer.id == -1 || oldOffer.status != newOffer.status) {
        return true;
      }
    }

    return false;
  }

  /// تحديث يدوي فوري (refresh)
  /// مفيد لما المستخدم يعمل pull-to-refresh
  Future<void> refresh() async {
    if (!_isActive) {
      startListening(bookingRequestId: _bookingRequestId);
      return;
    }

    await _fetchAndEmit();
  }

  /// قبول عرض مع تحديث الـ stream فورًا
  Future<WorkerOfferResult> acceptOffer(int offerId) async {
    final result = await WorkerOfferService.acceptOffer(offerId);

    if (result.success) {
      // تحديث العرض محليًا في الـ stream
      final updatedList = _lastOffers.map((o) {
        if (o.id == offerId) {
          return WorkerOffer(
            id: o.id,
            bookingRequestId: o.bookingRequestId,
            workerId: o.workerId,
            priceAction: o.priceAction,
            offeredPrice: o.offeredPrice,
            message: o.message,
            estimatedDuration: o.estimatedDuration,
            status: 'accepted', // تحديث الحالة
            createdAt: o.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return o;
      }).toList();

      // إرسال البيانات المحدثة
      _lastOffers = updatedList;
      if (!_offersController.isClosed) {
        _offersController.add(updatedList);
      }

      // تحديث العداد (العرض المقبول لم يعد pending)
      final newOffersCount = updatedList.where((o) => o.status == 'pending').length;
      if (!_newOffersCountController.isClosed) {
        _newOffersCountController.add(newOffersCount);
      }
    }

    return result;
  }

  /// سحب عرض (للعاملة) مع تحديث الـ stream
  Future<WorkerOfferResult> withdrawOffer(int offerId) async {
    final result = await WorkerOfferService.withdrawOffer(offerId);

    if (result.success) {
      // تحديث العرض محليًا
      final updatedList = _lastOffers.map((o) {
        if (o.id == offerId) {
          return WorkerOffer(
            id: o.id,
            bookingRequestId: o.bookingRequestId,
            workerId: o.workerId,
            priceAction: o.priceAction,
            offeredPrice: o.offeredPrice,
            message: o.message,
            estimatedDuration: o.estimatedDuration,
            status: 'withdrawn',
            createdAt: o.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return o;
      }).toList();

      _lastOffers = updatedList;
      if (!_offersController.isClosed) {
        _offersController.add(updatedList);
      }

      // تحديث العداد
      final newOffersCount = updatedList.where((o) => o.status == 'pending').length;
      if (!_newOffersCountController.isClosed) {
        _newOffersCountController.add(newOffersCount);
      }
    }

    return result;
  }

  /// تخصيص مدة التحديث
  void setPollInterval(Duration interval) {
    _pollInterval = interval;

    // إعادة تشغيل الـ timer إذا كان نشط
    if (_isActive) {
      stopListening();
      startListening(bookingRequestId: _bookingRequestId);
    }
  }

  /// تغيير معرف طلب الحجز (للتصفية)
  void setBookingRequestId(int? bookingRequestId) {
    if (_bookingRequestId == bookingRequestId) return;

    _bookingRequestId = bookingRequestId;

    // إعادة جلب البيانات بالتصفية الجديدة
    if (_isActive) {
      _fetchAndEmit();
    }
  }

  /// الحصول على آخر قائمة عروض محلية (بدون API call)
  List<WorkerOffer> get lastOffers => List.from(_lastOffers);

  /// الحصول على عدد العروض الجديدة الحالي
  int get currentNewOffersCount =>
      _lastOffers.where((o) => o.status == 'pending').length;

  /// cleanup عند إغلاق التطبيق
  void dispose() {
    stopListening();
    _offersController.close();
    _newOffersCountController.close();
  }
}
