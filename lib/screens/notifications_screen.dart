import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'offer_details_screen.dart';
import 'chat_screen.dart';
import 'client_service_confirmation_screen.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final notifications = await NotificationService.getNotifications();

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      final success = await NotificationService.markAsRead(notification.id);
      if (success) {
        setState(() {
          // Update the notification in the list
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              message: notification.message,
              messageEn: notification.messageEn,
              notificationType: notification.notificationType,
              isRead: true,
              createdAt: notification.createdAt,
              relatedObjectId: notification.relatedObjectId,
              relatedObjectType: notification.relatedObjectType,
              bookingId: notification.bookingId,
            );
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success) {
      setState(() {
        _notifications = _notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            message: notification.message,
            messageEn: notification.messageEn,
            notificationType: notification.notificationType,
            isRead: true,
            createdAt: notification.createdAt,
            relatedObjectId: notification.relatedObjectId,
            relatedObjectType: notification.relatedObjectType,
            bookingId: notification.bookingId,
          );
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.markAllAsRead ?? 'تم تحديد كل الإشعارات كمقروءة'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    _markAsRead(notification);

    try {
      // Get user role
      final user = await AuthService.getCurrentUser();
      final userRole = user?.role;

      // Get the route information for this notification
      final routeInfo = NotificationService.getNotificationRoute(notification, userRole: userRole);
      final routeName = routeInfo['route'] as String;
      final message = routeInfo['message'] as String?;
      final offerId = routeInfo['offerId'] as int?;
      final bookingId = routeInfo['bookingId'] as int?;

      // Debug: Print notification type and route

      // Show message if available
      if (message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF4F46E5),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to the appropriate screen
      if (routeName == '/chat' && bookingId != null) {
        // Navigate to chat screen
        final otherUserName = _getOtherUserName(notification);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              bookingId: bookingId,
              otherUserName: otherUserName,
            ),
          ),
        ).then((result) {
          // Reload notifications after returning from chat
          if (mounted) {
            _loadNotifications();
          }
        });
      } else if (routeName == '/chat' && bookingId == null) {
        // Error: Chat route requires bookingId
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.chatOpenError ?? 'خطأ: لا يمكن فتح المحادثة - معرف الحجز غير موجود'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (routeName == '/offer-details' && offerId != null) {
        // Navigate to offer details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferDetailsScreen(offerId: offerId),
          ),
        ).then((result) {
          // Reload notifications after returning from offer details
          if (result == true && mounted) {
            _loadNotifications();
          }
        });
      } else if (routeName == '/service-confirmation' && bookingId != null) {
        // Navigate to service confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientServiceConfirmationScreen(
              bookingId: bookingId,
            ),
          ),
        ).then((result) {
          // Reload notifications after returning
          if (result == true && mounted) {
            _loadNotifications();
          }
        });
      } else if (routeName != '/') {
        // Navigate to the specific route and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          routeName,
          (route) => false,
        );
      } else {
        // Just pop back to the previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.unknownError ?? 'خطأ: '}$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getOtherUserName(NotificationModel notification) {
    // Extract name from notification message
    // Format: "لديك حجز جديد من [name] بتاريخ..."
    final match = RegExp(r'من (.+?) بتاريخ').firstMatch(notification.message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    return 'المستخدم';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Get user role to determine home route
        final user = await AuthService.getCurrentUser();
        final userRole = user?.role?.toUpperCase();

        // Navigate to appropriate home screen
        if (userRole == 'PROVIDER') {
          Navigator.pushNamedAndRemoveUntil(context, '/provider-home', (route) => false);
        } else if (userRole == 'CLIENT') {
          Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF4F46E5) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)?.notifications ?? 'الإشعارات',
          style: TextStyle(
            color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
          onPressed: () async {
            // Get user role to determine home route
            final user = await AuthService.getCurrentUser();
            final userRole = user?.role?.toUpperCase();

            // Navigate to appropriate home screen
            if (userRole == 'PROVIDER') {
              Navigator.pushNamedAndRemoveUntil(context, '/provider-home', (route) => false);
            } else if (userRole == 'CLIENT') {
              Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (route) => false);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white : const Color(0xFF4F46E5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.markAllAsRead ?? 'تحديد كمقروء',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF4F46E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFF4F46E5),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity( 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)?.noNotifications ?? 'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.noNotificationsSubtitle ?? 'ستظهر الإشعارات هنا عند وجود تحديثات جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final localizedMessage = notification.getLocalizedMessage(locale);
    final localizedTime = notification.getTimeAgo(locale: locale);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[900]
            : (notification.isRead ? Colors.white : const Color(0xFF4F46E5).withOpacity( 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withOpacity( 0.2)
              : const Color(0xFF4F46E5).withOpacity( 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      notification.getNotificationIcon(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
