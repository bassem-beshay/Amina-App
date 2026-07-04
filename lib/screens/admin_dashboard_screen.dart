import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';
import 'admin_pending_providers_screen.dart';
import 'admin_service_categories_screen.dart';
import 'admin_services_screen.dart';
import 'admin_all_providers_screen.dart';
import 'admin_rejected_providers_screen.dart';
import 'admin_verified_providers_screen.dart';
import 'admin_clients_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_conversations_ratings_screen.dart';
import 'notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  const AdminDashboardScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic> stats = {
    'pending_providers': 0,
    'verified_providers': 0,
    'rejected_providers': 0,
    'total_clients': 0,
  };
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadDashboard();
    _setupNotificationListener();
  }

  /// إعداد listener للإشعارات عند النقر
  void _setupNotificationListener() {
    PushNotificationService().onNotificationTapped.listen((data) {
      print('📲 Admin received notification tap: $data');

      // الأدمن: جميع الإشعارات توجه لصفحة الإشعارات
      // (الأدمن لا يستخدم الشات عادة، لكن يمكن إضافة منطق خاص إذا احتجت)
      _navigateToNotifications();
    });
  }

  /// الانتقال لصفحة الإشعارات
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // جلب معلومات المستخدم
      final meResp = await ApiClient.get(ApiConfig.me, needsAuth: true);
      if (meResp.success && meResp.rawResponse != null) {
        userData = meResp.rawResponse as Map<String, dynamic>;
      }

      // جلب الإحصائيات من الـ API
      final statsResp = await ApiClient.get(ApiConfig.adminStats, needsAuth: true);

      if (statsResp.success && statsResp.rawResponse != null) {
        final statsData = statsResp.rawResponse as Map<String, dynamic>;

        setState(() {
          stats = {
            'pending_providers': statsData['pending_providers'] ?? 0,
            'verified_providers': statsData['verified_providers'] ?? 0,
            'rejected_providers': statsData['rejected_providers'] ?? 0,
            'total_clients': statsData['total_clients'] ?? 0,
            'total_providers': statsData['total_providers'] ?? 0,
          };
          isLoading = false;
        });
      } else {
        throw Exception(statsResp.error ?? 'Failed to load statistics');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل الداشبورد: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          'لوحة تحكم الإدارة',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadDashboard,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.surface),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icons/app-icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage),
                      const SizedBox(height: 16),
                      ConnectivityIconButton(
                        onPressed: loadDashboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // رسالة الترحيب
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity( 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Theme.of(context).colorScheme.surface,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData?['first_name'] ?? 'المسؤول',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData?['email'] ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // الإحصائيات
                      const Text(
                        'الإحصائيات العامة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // صف الإحصائيات
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'قيد المراجعة',
                              value: '${stats['pending_providers']}',
                              icon: Icons.hourglass_empty,
                              color: Colors.orange,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        AdminPendingProvidersScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'موثقين',
                              value: '${stats['verified_providers']}',
                              icon: Icons.verified_user,
                              color: Colors.green,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        AdminVerifiedProvidersScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'مرفوضين',
                              value: '${stats['rejected_providers']}',
                              icon: Icons.cancel,
                              color: Colors.red,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        AdminRejectedProvidersScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'العملاء',
                              value: '${stats['total_clients']}',
                              icon: Icons.people,
                              color: Colors.blue,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => AdminClientsScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // القوائم الرئيسية
                      const Text(
                        'الإدارة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'مراجعة مزودي الخدمة',
                        subtitle:
                            'مراجعة وثائق المزودين الجدد وقبولهم أو رفضهم',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        badge: stats['pending_providers'] > 0
                            ? '${stats['pending_providers']}'
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminPendingProvidersScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'إدارة المزودين',
                        subtitle: 'عرض وإدارة جميع مزودي الخدمة',
                        icon: Icons.group,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminAllProvidersScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'إدارة العملاء',
                        subtitle: 'عرض وإدارة جميع العملاء',
                        icon: Icons.people_outline,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminClientsScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'إدارة فئات الخدمات',
                        subtitle: 'إضافة وتعديل فئات الخدمات المتاحة',
                        icon: Icons.category,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminServiceCategoriesScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'إدارة الخدمات',
                        subtitle: 'إضافة وتعديل الخدمات وأسعارها',
                        icon: Icons.home_repair_service,
                        color: const Color(0xFF0EA5E9),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminServicesScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'المحادثات، التقييمات، والشكاوى',
                        subtitle: 'عرض المحادثات مع التقييمات والشكاوى ومراجعتها',
                        icon: Icons.chat_bubble_outline,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminConversationsRatingsScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuCard(
                        title: 'إدارة الحجوزات والمدفوعات',
                        subtitle: 'عرض ومتابعة جميع الحجوزات وعمليات الدفع',
                        icon: Icons.event_note,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => AdminBookingsScreen(
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity( 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('تسجيل الخروج'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      final result = await AuthService.logout();
      if (context.mounted) {
        if (result.success) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        }
      }
    } catch (e) {
    }
  }
}
