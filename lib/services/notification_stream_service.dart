import 'dart:async';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// خدمة لتوفير تحديثات real-time للإشعارات عبر Stream
/// تعمل مثل Firestore snapshots() لكن مع REST API
class NotificationStreamService {
  // Singleton pattern
  static final NotificationStreamService _instance = NotificationStreamService._internal();
  factory NotificationStreamService() => _instance;
  NotificationStreamService._internal();

  // Stream controller للإشعارات
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  // Stream controller لعداد الإشعارات غير المقروءة
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  // Timer للتحديث الدوري
  Timer? _pollTimer;

  // آخر قائمة إشعارات تم جلبها (للمقارنة)
  List<NotificationModel> _lastNotifications = [];

  // مدة التحديث (يمكن تخصيصها)
  Duration _pollInterval = const Duration(seconds: 10);

  // حالة الخدمة
  bool _isActive = false;

  /// الحصول على stream الإشعارات
  /// مشابه لـ Firestore: collection('notifications').snapshots()
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  /// الحصول على stream عداد الإشعارات غير المقروءة
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// بدء الاستماع للتحديثات (يشبه onSnapshot)
  ///
  /// [pollInterval] - المدة بين كل تحديث (افتراضي: 10 ثواني)
  /// [immediate] - هل نجلب البيانات فورًا أم ننتظر أول interval
  void startListening({
    Duration? pollInterval,
    bool immediate = true,
  }) {
    if (_isActive) {
      return;
    }

    _isActive = true;

    if (pollInterval != null) {
      _pollInterval = pollInterval;
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
      // جلب الإشعارات من الـ API
      final notifications = await NotificationService.getNotifications();

      // التحقق من وجود تغييرات (لتجنب إرسال نفس البيانات)
      if (_hasChanges(notifications)) {
        // حفظ آخر نسخة
        _lastNotifications = List.from(notifications);

        // إرسال البيانات عبر الـ stream
        if (!_notificationsController.isClosed) {
          _notificationsController.add(notifications);
        }

        // حساب وإرسال عداد الإشعارات غير المقروءة
        final unreadCount = notifications.where((n) => !n.isRead).length;
        if (!_unreadCountController.isClosed) {
          _unreadCountController.add(unreadCount);
        }

      }
    } catch (e) {
      // إرسال error عبر الـ stream
      if (!_notificationsController.isClosed) {
        _notificationsController.addError(e);
      }
    }
  }

  /// التحقق من وجود تغييرات في البيانات
  bool _hasChanges(List<NotificationModel> newNotifications) {
    // إذا كان العدد مختلف، فهناك تغيير
    if (newNotifications.length != _lastNotifications.length) {
      return true;
    }

    // مقارنة IDs و isRead status
    for (int i = 0; i < newNotifications.length; i++) {
      final newNotif = newNotifications[i];
      final oldNotif = _lastNotifications.firstWhere(
        (n) => n.id == newNotif.id,
        orElse: () => NotificationModel(
          id: -1,
          message: '',
          notificationType: '',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      // إذا الإشعار جديد أو تغيرت حالة القراءة
      if (oldNotif.id == -1 || oldNotif.isRead != newNotif.isRead) {
        return true;
      }
    }

    return false;
  }

  /// تحديث يدوي فوري (refresh)
  /// مفيد لما المستخدم يعمل pull-to-refresh
  Future<void> refresh() async {
    if (!_isActive) {
      startListening();
      return;
    }

    await _fetchAndEmit();
  }

  /// تحديد إشعار كمقروء مع تحديث الـ stream فورًا
  Future<bool> markAsRead(int notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);

    if (success) {
      // تحديث الإشعار محليًا في الـ stream
      final updatedList = _lastNotifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            message: n.message,
            notificationType: n.notificationType,
            relatedObjectType: n.relatedObjectType,
            relatedObjectId: n.relatedObjectId,
            bookingId: n.bookingId,
            isRead: true, // تحديث الحالة
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      // إرسال البيانات المحدثة
      _lastNotifications = updatedList;
      if (!_notificationsController.isClosed) {
        _notificationsController.add(updatedList);
      }

      // تحديث العداد
      final unreadCount = updatedList.where((n) => !n.isRead).length;
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(unreadCount);
      }
    }

    return success;
  }

  /// تحديد كل الإشعارات كمقروءة
  Future<bool> markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();

    if (success) {
      // تحديث كل الإشعارات محليًا
      final updatedList = _lastNotifications.map((n) {
        return NotificationModel(
          id: n.id,
          message: n.message,
          notificationType: n.notificationType,
          relatedObjectType: n.relatedObjectType,
          relatedObjectId: n.relatedObjectId,
          bookingId: n.bookingId,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      _lastNotifications = updatedList;
      if (!_notificationsController.isClosed) {
        _notificationsController.add(updatedList);
      }

      // العداد يصبح 0
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(0);
      }
    }

    return success;
  }

  /// تخصيص مدة التحديث
  void setPollInterval(Duration interval) {
    _pollInterval = interval;

    // إعادة تشغيل الـ timer إذا كان نشط
    if (_isActive) {
      stopListening();
      startListening();
    }
  }

  /// cleanup عند إغلاق التطبيق
  void dispose() {
    stopListening();
    _notificationsController.close();
    _unreadCountController.close();
  }
}
