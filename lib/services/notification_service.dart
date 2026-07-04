import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  /// جلب كل الإشعارات للمستخدم الحالي
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiClient.get(
        ApiConfig.notifications,
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        // البيانات ممكن تكون array مباشرة أو object فيه key اسمها 'data' أو 'results'
        List<dynamic> notificationsJson = [];

        if (response.rawResponse is List) {
          notificationsJson = response.rawResponse as List;
        } else if (response.rawResponse is Map) {
          final map = response.rawResponse as Map<String, dynamic>;
          if (map.containsKey('data')) {
            notificationsJson = map['data'] as List? ?? [];
          } else if (map.containsKey('results')) {
            notificationsJson = map['results'] as List? ?? [];
          } else if (map.containsKey('notifications')) {
            notificationsJson = map['notifications'] as List? ?? [];
          }
        }

        return notificationsJson
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      return 0;
    }
  }

  /// تحديد إشعار معين كمقروء
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.markNotificationAsRead(notificationId),
        needsAuth: true,
        body: {},
      );

      if (response.success) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// تحديد كل الإشعارات كمقروءة
  static Future<bool> markAllAsRead() async {
    try {
      final response = await ApiClient.post(
        ApiConfig.markAllNotificationsAsRead,
        needsAuth: true,
        body: {},
      );

      if (response.success) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// تحديد نوع الإشعار بناءً على notification_type و related_object_type
  /// يرجع route name و optional parameters للـ navigation
  static Map<String, dynamic> getNotificationRoute(NotificationModel notification, {String? userRole}) {
    // تحديد المسار بناءً على نوع الإشعار
    switch (notification.notificationType.toUpperCase()) {
      // إشعار تأكيد الحجز - فتح الشات
      case 'BOOKING_CONFIRMED':
        return {
          'route': '/chat',
          'bookingId': notification.bookingId,
          'message': 'لديك حجز جديد - يمكنك التواصل مع الطرف الآخر',
        };

      // إشعارات الحجوزات الأخرى - للعميل
      case 'BOOKING_CREATED':
      case 'BOOKING_STARTED':
        return {
          'route': '/customer-home',
          'tab': 1, // تاب الحجوزات (إذا كان موجود)
        };

      // إشعار إكمال الخدمة
      case 'BOOKING_COMPLETED':
      case 'SERVICE_COMPLETED':
      case 'PROVIDER_COMPLETED':
      case 'COMPLETION_REQUESTED':
        // لو المستخدم provider، يروح للـ home
        // لو المستخدم client، يروح لصفحة التأكيد
        if (userRole == 'PROVIDER') {
          return {
            'route': '/provider-home',
            'message': 'تم إكمال الخدمة بنجاح',
          };
        } else {
          return {
            'route': '/service-confirmation',
            'bookingId': notification.bookingId,
            'message': 'تم إكمال الخدمة - يرجى تأكيد الإكمال',
          };
        }

      // إشعار تأكيد العميل للخدمة - للبروفايدر (العميل أكد إتمام الخدمة)
      case 'CLIENT_CONFIRMED_COMPLETION':
      case 'SERVICE_CONFIRMED':
      case 'COMPLETION_CONFIRMED':
      case 'CLIENT_CONFIRMED':
        return {
          'route': '/provider-home',
          'message': 'العميل أكد إتمام الخدمة',
        };

      case 'BOOKING_CANCELED':
      case 'BOOKING_CANCELLED':
        return {
          'route': '/customer-home',
          'tab': 1, // تاب الحجوزات (إذا كان موجود)
        };

      // إشعارات العروض - للعميل (العاملة أرسلت عرض)
      case 'OFFER_SUBMITTED':
        return {
          'route': '/offer-details',
          'offerId': notification.relatedObjectId, // تمرير offer ID للصفحة
          'message': 'تم استلام عرض جديد على طلبك',
        };

      // إشعار قبول العرض - للعاملة (العميل قبل العرض)
      case 'OFFER_ACCEPTED':
        return {
          'route': '/provider-home',
          'tab': 2, // تاب الحجوزات للعاملة
          'message': 'تم قبول عرضك',
        };

      // إشعارات إعادة الجدولة
      case 'RESCHEDULE_REQUESTED':
      case 'RESCHEDULE_APPROVED':
      case 'RESCHEDULE_REJECTED':
        return {
          'route': notification.relatedObjectType == 'booking_request'
              ? '/customer-home'
              : '/provider-home',
          'tab': notification.relatedObjectType == 'booking_request' ? 1 : 2,
        };

      // إشعارات التقييم
      case 'RATING_RECEIVED':
        // لو المستخدم provider، يروح للـ home بتاعه
        // لو المستخدم client، يروح للـ home بتاعه
        if (userRole == 'PROVIDER') {
          return {
            'route': '/provider-home',
            'message': 'لقد حصلت على تقييم جديد',
          };
        } else {
          return {
            'route': '/customer-home',
            'tab': 0, // الصفحة الرئيسية للعميل
          };
        }

      // إشعارات الشكاوى
      case 'COMPLAINT_FILED':
      case 'COMPLAINT_RESOLVED':
        return {
          'route': notification.relatedObjectType == 'booking_request'
              ? '/customer-home'
              : '/provider-home',
          'tab': 1,
        };

      // إشعارات الدفع
      case 'PAYMENT_SUCCESS':
      case 'PAYMENT_FAILED':
        return {
          'route': '/customer-home',
          'tab': 1,
        };

      // افتراضي - العودة للصفحة الرئيسية
      default:
        return {
          'route': '/',
          'tab': 0,
        };
    }
  }
}
