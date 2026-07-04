class NotificationModel {
  final int id;
  final String message;
  final String? messageEn; // English message for localization
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final int? relatedObjectId;
  final String? relatedObjectType;
  final int? bookingId;

  NotificationModel({
    required this.id,
    required this.message,
    this.messageEn,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.relatedObjectId,
    this.relatedObjectType,
    this.bookingId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      message: json['message'] as String,
      messageEn: json['message_en'] as String?,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedObjectId: json['related_object_id'] as int?,
      relatedObjectType: json['related_object_type'] as String?,
      bookingId: json['booking'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'message_en': messageEn,
      'notification_type': notificationType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'related_object_id': relatedObjectId,
      'related_object_type': relatedObjectType,
      'booking': bookingId,
    };
  }

  /// Get localized message based on locale
  String getLocalizedMessage(String locale) {
    if (locale == 'en' && messageEn != null && messageEn!.isNotEmpty) {
      return messageEn!;
    }
    return message;
  }

  // Helper method to get notification icon based on type
  String getNotificationIcon() {
    switch (notificationType.toUpperCase()) {
      case 'BOOKING_CREATED':
      case 'BOOKING_CONFIRMED':
        return '📝';
      case 'OFFER_SUBMITTED':
        return '💼';
      case 'OFFER_ACCEPTED':
        return '✅';
      case 'BOOKING_STARTED':
        return '🚀';
      case 'BOOKING_COMPLETED':
      case 'SERVICE_COMPLETED':
      case 'PROVIDER_COMPLETED':
      case 'COMPLETION_REQUESTED':
        return '🎉';
      case 'BOOKING_CANCELED':
      case 'BOOKING_CANCELLED':
        return '❌';
      case 'RESCHEDULE_REQUESTED':
        return '📅';
      case 'RESCHEDULE_APPROVED':
        return '✅';
      case 'RESCHEDULE_REJECTED':
        return '❌';
      case 'RATING_RECEIVED':
        return '⭐';
      case 'COMPLAINT_FILED':
        return '⚠️';
      case 'COMPLAINT_RESOLVED':
        return '✅';
      case 'PAYMENT_SUCCESS':
        return '💰';
      case 'PAYMENT_FAILED':
        return '❌';
      default:
        return '🔔';
    }
  }

  // Helper method to format time ago with localization support
  String getTimeAgo({String locale = 'ar'}) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (locale == 'en') {
      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } else {
      // Arabic
      if (difference.inSeconds < 60) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ \u200F${difference.inMinutes}\u200F دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ \u200F${difference.inHours}\u200F ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ \u200F${difference.inDays}\u200F يوم';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'منذ \u200F$weeks\u200F أسبوع';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'منذ \u200F$months\u200F شهر';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'منذ \u200F$years\u200F سنة';
      }
    }
  }
}
