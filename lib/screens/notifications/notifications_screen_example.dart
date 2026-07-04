import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_stream_service.dart';

/// مثال على استخدام NotificationStreamService مع StreamBuilder
/// هذه الصفحة تستقبل التحديثات تلقائيًا بدون الحاجة لـ refresh يدوي
class NotificationsScreenExample extends StatefulWidget {
  const NotificationsScreenExample({Key? key}) : super(key: key);

  @override
  State<NotificationsScreenExample> createState() => _NotificationsScreenExampleState();
}

class _NotificationsScreenExampleState extends State<NotificationsScreenExample> {
  final NotificationStreamService _streamService = NotificationStreamService();

  @override
  void initState() {
    super.initState();

    // بدء الاستماع للتحديثات (يشبه Firestore snapshots)
    // سيتم جلب البيانات كل 10 ثواني تلقائيًا
    _streamService.startListening(
      pollInterval: const Duration(seconds: 10),
      immediate: true, // جلب البيانات فورًا
    );
  }

  @override
  void dispose() {
    // إيقاف الاستماع عند الخروج من الصفحة
    _streamService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // زر لتحديد كل الإشعارات كمقروءة
          StreamBuilder<int>(
            stream: _streamService.unreadCountStream,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              if (unreadCount == 0) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'تحديد الكل كمقروء',
                onPressed: () async {
                  await _streamService.markAllAsRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديد كل الإشعارات كمقروءة')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        // Pull-to-refresh للتحديث الفوري
        onRefresh: () => _streamService.refresh(),
        child: StreamBuilder<List<NotificationModel>>(
          // الاستماع للـ stream - يشبه تمامًا Firestore snapshots()
          stream: _streamService.notificationsStream,
          builder: (context, snapshot) {
            // حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // حالة الخطأ
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ في جلب الإشعارات',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _streamService.refresh(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            // حالة عدم وجود إشعارات
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // عرض الإشعارات
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return NotificationTile(
                  notification: notification,
                  onTap: () async {
                    // تحديد الإشعار كمقروء عند الضغط عليه
                    if (!notification.isRead) {
                      await _streamService.markAsRead(notification.id);
                    }

                    // التنقل حسب نوع الإشعار
                    // يمكنك استخدام NotificationService.getNotificationRoute()
                    _handleNotificationTap(notification);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // هنا يمكنك إضافة منطق التنقل حسب نوع الإشعار
    // مثال:
    switch (notification.notificationType.toUpperCase()) {
      case 'BOOKING_CONFIRMED':
        // Navigator.pushNamed(context, '/chat', arguments: notification.bookingId);
        break;
      case 'OFFER_SUBMITTED':
        // Navigator.pushNamed(context, '/offer-details', arguments: notification.relatedObjectId);
        break;
      default:
        break;
    }
  }
}

/// Widget لعرض إشعار واحد
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.grey[200]
              : Theme.of(context).primaryColor.withOpacity( 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            notification.getNotificationIcon(),
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          notification.getTimeAgo(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
      tileColor: notification.isRead ? null : Colors.blue[50]?.withOpacity( 0.3),
    );
  }
}

/// Widget لعرض عداد الإشعارات غير المقروءة (Notification Badge)
/// يمكن استخدامه في AppBar أو BottomNavigationBar
class NotificationBadge extends StatelessWidget {
  final NotificationStreamService _streamService = NotificationStreamService();

  NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _streamService.unreadCountStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0) {
          return const Icon(Icons.notifications_none);
        }

        return Stack(
          children: [
            const Icon(Icons.notifications),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
