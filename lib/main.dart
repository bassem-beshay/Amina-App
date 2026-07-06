import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/edit_client_profile_screen.dart';
import 'screens/service_completion_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/provider_home_screen.dart';
import 'screens/conversations_list_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'widgets/connectivity_wrapper.dart';
import 'widgets/skeleton_loader.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Hide red error screens in production
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container();
    };

    FlutterError.onError = (FlutterErrorDetails details) {
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      return true;
    };
  }

  // Note: Push Notifications are initialized after login in auth_screen.dart

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AminaPlatformApp(),
    ),
  );
}

// Note: AuthCheckScreen is merged with SplashScreen

class AminaPlatformApp extends StatelessWidget {
  const AminaPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'Amina Platform',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
          supportedLocales: const [
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ConnectivityWrapper(
            child: SplashScreen(),
          ),
          initialRoute: null,
          onGenerateRoute: (settings) {
        // Handle routes with parameters
        if (settings.name?.startsWith('/service-completion/') == true) {
          final bookingId = int.tryParse(settings.name!.split('/').last);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => ServiceCompletionScreen(bookingId: bookingId),
            );
          }
        }
        return null;
      },
      routes: {
        '/auth': (context) => const ConnectivityWrapper(child: LoginScreen()),
        '/forgot-password': (context) => ConnectivityWrapper(child: ForgotPasswordScreen()),
        '/dashboard': (context) => const ConnectivityWrapper(child: AminaDashboard()),
        '/customer-home': (context) => const ConnectivityWrapper(child: CustomerHomeScreen()),
        '/provider-home': (context) => const ConnectivityWrapper(child: ProviderHomeScreen()),
        '/edit-client-profile': (context) => const ConnectivityWrapper(child: EditClientProfileScreen()),
        '/conversations': (context) => ConnectivityWrapper(child: ConversationsListScreen()),
        '/admin-dashboard': (context) {
          // Get token from storage to pass to admin dashboard
          return ConnectivityWrapper(
            child: FutureBuilder<String?>(
              future: StorageService.getAuthToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonScreen(showAppBar: false);
                }
                final token = snapshot.data;
                if (token == null) {
                  // No token, redirect to auth
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  });
                  return const SkeletonScreen(showAppBar: false);
                }
                return AdminDashboardScreen(token: token);
              },
            ),
          );
        },
          },
        );
      },
    );
  }
}

class AminaDashboard extends StatefulWidget {
  const AminaDashboard({super.key});

  @override
  State<AminaDashboard> createState() => _AminaDashboardState();
}

class _AminaDashboardState extends State<AminaDashboard> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardHome(),
    const ServicesScreen(),
    const WorkersScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🏡', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.aminaPlatform ?? 'Amina Platform',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              Text(
                AppLocalizations.of(context)?.welcomeYou ?? 'Welcome!',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, size: 20),
          ),
          onPressed: () async {
            // Get saved token and navigate to profile
            final token = await StorageService.getAuthToken();
            if (token == null) {
              // Not logged in -> go to auth screen
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login first')),
                );
              }
              return;
            }

            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ProfileScreen(token: token),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cleaning_services_outlined),
            activeIcon: Icon(Icons.cleaning_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 2 : 1,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              _buildServicesCard(),
              _buildWorkersCard(),
              _buildRevenueCard(),
              _buildLiveRequestsCard(),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return _buildCard(
      title: 'Popular Services',
      icon: Icons.cleaning_services,
      child: Column(
        children: [
          _buildServiceItem('Full House Cleaning', '450 EGP', Icons.clean_hands),
          _buildServiceItem('Child Care', '300 EGP', Icons.child_care),
          _buildServiceItem('Home Cooking', '350 EGP', Icons.restaurant),
          _buildServiceItem('Elder Care', '400 EGP', Icons.accessible),
          const Spacer(),
          _buildCardButton('View All Services', Icons.arrow_forward_ios),
        ],
      ),
    );
  }

  Widget _buildWorkersCard() {
    return _buildCard(
      title: 'Top Workers',
      icon: Icons.people,
      child: Column(
        children: [
          _buildWorkerItem('Fatima Ahmed', 'House Cleaning', '5.0', '342'),
          _buildWorkerItem('Mariam Mohamed', 'Home Cooking', '4.9', '278'),
          _buildWorkerItem('Sara Hassan', 'Child Care', '4.8', '195'),
          const Spacer(),
          _buildCardButton('Manage Workers', Icons.manage_accounts),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final formatter = NumberFormat('#,###');
    return _buildCard(
      title: 'Revenue',
      icon: Icons.account_balance_wallet,
      child: Column(
        children: [
          _buildRevenueItem(
            "Today's Earnings",
            '${formatter.format(8500)} EGP',
            Icons.today,
            const Color(0xFF10B981),
          ),
          _buildRevenueItem(
            "Week's Earnings",
            '${formatter.format(65000)} EGP',
            Icons.calendar_view_week,
            const Color(0xFF3B82F6),
          ),
          _buildRevenueItem(
            "Month's Earnings",
            '${formatter.format(250000)} EGP',
            Icons.calendar_today,
            const Color(0xFF4F46E5),
          ),
          const Spacer(),
          _buildCardButton('Financial Reports', Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildLiveRequestsCard() {
    return _buildCard(
      title: 'Live Requests',
      icon: Icons.notifications_active,
      badge: '3 new',
      child: Column(
        children: [
          _buildRequestItem('Laila Ahmed', 'House Cleaning', 'Zamalek, Cairo'),
          _buildRequestItem('Ahmed Mohamed', 'Child Care', 'Maadi, Cairo'),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _buildCardButton('View All', Icons.list)),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCardButton(
                  'Manage',
                  Icons.settings,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return _buildCard(
      title: 'Recent Activity',
      icon: Icons.history,
      child: Column(
        children: [
          _buildActivityItem(
            'Cleaning service completed',
            '2 hours ago',
            Icons.check_circle,
            const Color(0xFF10B981),
          ),
          _buildActivityItem(
            'New request',
            '4 hours ago',
            Icons.add_circle,
            const Color(0xFF3B82F6),
          ),
          _buildActivityItem(
            'New rating',
            '6 hours ago',
            Icons.star,
            const Color(0xFFF59E0B),
          ),
          _buildActivityItem(
            'System update',
            '1 day ago',
            Icons.update,
            const Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, String price, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1a1a1a),
              ),
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerItem(
    String name,
    String specialty,
    String rating,
    String reviews,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
              ),
            ),
            child: const Center(
              child: Text('👩', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                Text(
                  specialty,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: Color(0xFF1a1a1a),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '($reviews reviews)',
                style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1a1a1a),
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(String client, String service, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFF59E0B), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                Text(
                  service,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity( 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF1a1a1a), fontSize: 14),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton(String text, IconData icon, {bool isPrimary = true}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF4F46E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isPrimary
            ? null
            : Border.all(color: const Color(0xFF4F46E5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isPrimary ? Colors.white : const Color(0xFF4F46E5),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.white : const Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Screens for other navigation items
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Services'));
  }
}

class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Workers'));
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports'));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AuthService.logout();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Logged out')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final token = await StorageService.getAuthToken();
                if (token == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login first'),
                      ),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ProfileScreen(token: token),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
