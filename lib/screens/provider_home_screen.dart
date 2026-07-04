import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../models/booking_request_model.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';
import '../services/worker_offer_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../services/push_notification_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../providers/language_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'provider_active_bookings_screen.dart';
import 'chat_screen.dart';
import 'conversations_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../widgets/connectivity_button.dart';
import '../widgets/payment_fee_notice.dart';
import '../mixins/connectivity_aware_mixin.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen>
    with ConnectivityAwareMixin {
  int _currentIndex = 0;
  bool _isLoading = true;

  // Flag to track internal navigation (to prevent exit dialog when navigating between tabs)
  bool _isNavigatingInternally = false;

  // Use ValueNotifier to avoid rebuilding entire widget tree when counts change
  final ValueNotifier<int> _unreadNotificationsCount = ValueNotifier(0);
  final ValueNotifier<int> _unreadMessagesCount = ValueNotifier(0);

  // Real data from API
  List<BookingRequest> _bookingRequests = [];
  List<BookingRequest> _filteredBookingRequests = [];
  User? _currentUser;
  Map<String, dynamic>? _providerProfileData; // Raw API data for profile picture

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Timer for auto-refresh notifications
  Timer? _notificationRefreshTimer;

  /// 🌐 Override من ConnectivityAwareMixin
  @override
  Future<void> fetchData() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadNotificationsCount();
    _loadUnreadMessagesCount();
    _startNotificationAutoRefresh();
    _setupNotificationListener();
  }

  /// إعداد listener للإشعارات
  void _setupNotificationListener() {
    PushNotificationService().onNotificationTapped.listen((data) {

      // التعامل مع إشعارات الشات
      if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
        final conversationId = data['conversation_id'];
        if (conversationId != null) {
          _navigateToChat(int.tryParse(conversationId.toString()));
        }
      }
      // التعامل مع باقي الإشعارات - الانتقال لصفحة الإشعارات
      else {
        _navigateToNotifications();
      }
    });
  }

  /// الانتقال لصفحة الإشعارات
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    ).then((_) {
      // تحديث عدد الإشعارات بعد العودة
      _loadUnreadNotificationsCount();
    });
  }

  /// الانتقال إلى صفحة الشات
  Future<void> _navigateToChat(int? conversationId) async {
    if (conversationId == null) return;


    try {
      // جلب تفاصيل المحادثة من الـ API
      final conversation = await ChatService.getConversationDetails(conversationId);
      final bookingId = conversation.bookingId;

      if (mounted) {
        // الحصول على اسم الطرف الآخر
        final currentUser = await AuthService.getCurrentUser();
        final otherUser = conversation.client.id == currentUser?.id
            ? conversation.provider
            : conversation.client;

        final otherUserName = otherUser.fullName;

        // فتح صفحة الشات
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              bookingId: bookingId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.chatOpenErrorSnackbar ?? 'حدث خطأ أثناء فتح المحادثة')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    _searchController.dispose();
    _unreadNotificationsCount.dispose();
    _unreadMessagesCount.dispose();
    super.dispose();
  }

  /// تشغيل auto-refresh للإشعارات والرسائل كل 5 ثواني (real-time)
  void _startNotificationAutoRefresh() {
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (mounted) {
          _loadUnreadNotificationsCount();
          _loadUnreadMessagesCount();
        }
      },
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Fetch current user data from API (not local storage)
    final userResult = await AuthService.fetchCurrentUser();
    User? user;
    Map<String, dynamic>? profileData;

    if (userResult.success && userResult.user != null) {
      user = userResult.user;

      // Fetch raw provider profile data for image URL
      if (user?.role == 'PROVIDER') {
        try {
          final profileResp = await ApiClient.get(
            ApiConfig.providerProfile,
            needsAuth: true,
          );
          if (profileResp.success && profileResp.rawResponse != null) {
            profileData = profileResp.rawResponse as Map<String, dynamic>;
          }
        } catch (e) {
        }
      }

      if (user?.providerProfile != null) {
      } else {
      }
    } else {
      // Fallback to local storage
      user = await AuthService.getCurrentUser();
    }

    // Fetch booking requests from API (status = PENDING)
    final requests = await BookingService.getBookings(status: 'PENDING');


    // Note: Service images are now included in the API response via serviceImage field
    // No need to fetch them separately anymore!

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _providerProfileData = profileData;
      _bookingRequests = requests;
      _filteredBookingRequests = requests;
      _isLoading = false;
    });
  }

  // Filter booking requests based on search query
  void _filterBookingRequests(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBookingRequests = _bookingRequests;
      } else {
        _filteredBookingRequests = _bookingRequests.where((request) {
          final serviceName = request.serviceTitle?.toLowerCase() ?? '';
          final categoryName = request.categoryName?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return serviceName.contains(searchLower) || categoryName.contains(searchLower);
        }).toList();
      }
    });
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final count = await NotificationService.getUnreadCount();
    _unreadNotificationsCount.value = count;
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final conversations = await ChatService.getConversations();
      int totalUnread = 0;
      for (var conv in conversations) {
        totalUnread += conv.unreadCount;
      }
      _unreadMessagesCount.value = totalUnread;
    } catch (e) {
      // Silently fail - chat might not be available yet
    }
  }

  // دالة للتحقق من رغبة المستخدم في الخروج
  Future<bool> _onWillPop() async {
    // إذا كان في tab غير الرئيسية (Index 0)، ارجع للرئيسية بدون dialog
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _isNavigatingInternally = true; // Set flag to prevent dialog on next back
      });
      return false; // Don't pop - just switch to home tab
    }

    // إذا كان flag مفعل (جاي من navigation داخلي)، ارجع للرئيسية بدون dialog
    if (_isNavigatingInternally) {
      setState(() {
        _isNavigatingInternally = false; // Reset flag
      });
      return false; // Don't pop
    }

    // الآن فقط اعرض dialog الخروج (المستخدم في tab الرئيسية وعايز يخرج من التطبيق)
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)?.confirmExit ?? 'تأكيد الخروج'),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)?.exitAppMessage ?? 'هل تريد الخروج من التطبيق؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)?.exit ?? 'خروج'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          clipBehavior: Clip.none, // Allow overflow
          children: [
            // Content with SafeArea
            Positioned.fill(
              child: SafeArea(
                child: _currentIndex == 0
                    ? _buildHomeTab()
                    : _currentIndex == 1
                        ? const NotificationsScreen()
                        : _currentIndex == 2
                            ? _buildBookingsTab()
                            : _buildProfileTab(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: provider_pkg.Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) => Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              key: ValueKey(languageProvider.locale.languageCode),
              currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
              onTap: (index) async {
                // إذا ضغط على المحادثات (index 1)، افتح صفحة المحادثات
                if (index == 1) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationsListScreen(),
                    ),
                  );
                  _loadUnreadMessagesCount();
                  return; // Don't change _currentIndex
                }

                // إذا ضغط على الملف الشخصي (index 3)، افتح صفحة الملف الشخصي
                if (index == 3) {
                  final token = await StorageService.getAuthToken();
                  if (token != null && mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(token: token),
                      ),
                    );
                    await _loadData();
                    _loadUnreadNotificationsCount();
                  }
                  return; // Don't change _currentIndex
                }

                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              selectedItemColor: const Color(0xFF4F46E5),
              unselectedItemColor: isDark
                  ? Colors.grey[500]
                  : Colors.grey[600],
              selectedFontSize: 11,
              unselectedFontSize: 10,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? const Color(0xFF4F46E5).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _currentIndex == 0
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                      size: 22,
                    ),
                  ),
                  label: AppLocalizations.of(context)?.home ?? 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? const Color(0xFF4F46E5).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _currentIndex == 1
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 22,
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _unreadMessagesCount,
                          builder: (context, count, child) {
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  label: AppLocalizations.of(context)?.conversations ?? 'المحادثات',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2
                          ? const Color(0xFF4F46E5).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _currentIndex == 2
                          ? Icons.event_note_rounded
                          : Icons.event_note_outlined,
                      size: 22,
                    ),
                  ),
                  label: AppLocalizations.of(context)?.myBookings ?? 'الحجوزات',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentIndex == 3
                          ? const Color(0xFF4F46E5).withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _currentIndex == 3
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 22,
                    ),
                  ),
                  label: AppLocalizations.of(context)?.profile ?? 'الملف الشخصي',
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF10B981),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity( 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterBookingRequests,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)?.search ?? 'ابحث عن خدمة...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterBookingRequests('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // New Requests Section
              // New Requests Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.pending ?? 'طلبات حجز جديدة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_filteredBookingRequests.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // New Requests List with Lazy Loading
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      ),
                    )
                  : _filteredBookingRequests.isEmpty
                      ? _buildEmptyState(
                          _searchQuery.isNotEmpty
                              ? AppLocalizations.of(context)?.noResults ?? 'لا توجد نتائج للبحث'
                              : AppLocalizations.of(context)?.noBookings ?? 'لا توجد طلبات حجز جديدة',
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredBookingRequests.length,
                          addAutomaticKeepAlives: false, // Disable keep-alives for better memory
                          addRepaintBoundaries: true, // Enable repaint boundaries for performance
                          cacheExtent: 500, // Cache 500px ahead for smoother scrolling
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_filteredBookingRequests[index]);
                          },
                        ),

              const SizedBox(height: 80),
            ],
          ),
        ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [const Color(0xFF4F46E5), const Color(0xFF4338CA)]
            : [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Profile Avatar - Clickable
            GestureDetector(
              onTap: () async {
                final token = await StorageService.getAuthToken();
                if (token != null && mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(token: token),
                    ),
                  );
                  if (!mounted) return;
                  await _loadData();
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF4F46E5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: _buildProfileImage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name & Location - Flexible to prevent overflow
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // مرحباً + الاسم - سطر واحد
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)?.hello ?? "مرحباً",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _currentUser?.fullName != null
                            ? _currentUser!.fullName.split(' ').first
                            : "مقدم الخدمة",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // الموقع مع العلم
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _getLocationText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _getCountryFlag(_currentUser?.providerProfile?.country),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications Icon with Badge
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                _loadUnreadNotificationsCount();
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 24,
                        color: isDark ? Colors.white : const Color(0xFF4F46E5),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: _unreadNotificationsCount,
                      builder: (context, count, child) {
                        if (count == 0) return const SizedBox.shrink();
                        return Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF4F46E5) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get service image from API response
    String? serviceImageUrl = request.serviceImage;

    if (serviceImageUrl != null && serviceImageUrl.isNotEmpty) {
    } else {
    }

    // Add base URL if not absolute
    if (serviceImageUrl != null && serviceImageUrl.isNotEmpty && !serviceImageUrl.startsWith('http')) {
      serviceImageUrl = '${ApiConfig.baseUrl}$serviceImageUrl';
    }


    // Get client profile picture URL
    // Try profilePictureUrl first, then fallback to profilePicture
    String? clientProfilePicUrl = request.clientInfo?.profilePictureUrl ?? request.clientInfo?.profilePicture;


    if (clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty && !clientProfilePicUrl.startsWith('http')) {
      clientProfilePicUrl = '${ApiConfig.baseUrl}$clientProfilePicUrl';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showOfferDialog(request),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                ? const Color(0xFF10B981).withOpacity(0.2)
                : const Color(0xFF10B981).withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.0 : 0.5),
                blurRadius: 1,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image Header - BIGGER
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  // Service Image or Gradient Fallback
                  if (serviceImageUrl != null && serviceImageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: serviceImageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 700,
                      memCacheHeight: 400,
                      maxWidthDiskCache: 900,
                      maxHeightDiskCache: 500,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) {
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B981),
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      },
                      errorWidget: (context, url, error) {
                        return _buildGradientBackground(request.categoryName, 300);
                      },
                    )
                  else
                    _buildGradientBackground(request.categoryName, 300),

                  // Enhanced Multi-Layer Gradient Overlay
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.75),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.4, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Budget Badge - Enhanced
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${request.clientBudget?.toStringAsFixed(0) ?? '---'} ${AppLocalizations.of(context)?.egpCurrency ?? 'جنيه'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Service Title at Bottom - Enhanced with Modern Styling
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode).isNotEmpty
                                    ? request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode)
                                    : '${AppLocalizations.of(context)?.bookingRequest ?? 'طلب حجز'} #${request.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (request.getLocalizedCategoryName(Localizations.localeOf(context).languageCode).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.category_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            request.getLocalizedCategoryName(Localizations.localeOf(context).languageCode),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Info Section with Profile Picture - Enhanced
                  if (request.clientInfo != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.08),
                            const Color(0xFF4F46E5).withOpacity(0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Client Avatar with Image - Bigger & Enhanced
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: () {
                                if (clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty) {
                                  return CachedNetworkImage(
                                    imageUrl: clientProfilePicUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 112,
                                    memCacheHeight: 112,
                                    maxWidthDiskCache: 168,
                                    maxHeightDiskCache: 168,
                                    fadeInDuration: const Duration(milliseconds: 200),
                                    placeholder: (context, url) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) {
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 28,
                                      );
                                    },
                                  );
                                } else {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 28,
                                  );
                                }
                              }(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.clientInfo!.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (request.clientInfo?.rating != null && request.clientInfo!.rating! > 0)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: Colors.amber[600],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${request.clientInfo!.rating!.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)?.rating ?? 'تقييم',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)?.newClient ?? 'عميل جديد',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Location - FULL WIDTH, NO ELLIPSIS with Enhanced Design
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                          ? [
                              const Color(0xFF374151).withOpacity(0.7),
                              const Color(0xFF374151).withOpacity(0.5),
                            ]
                          : [
                              const Color(0xFFF9FAFB),
                              const Color(0xFFF3F4F6),
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFF10B981).withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.2),
                                const Color(0xFF4F46E5).withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 24,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            request.location,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Action Buttons - Enhanced with Modern Design
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _showRequestDetails(request),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              side: BorderSide(
                                color: isDark
                                  ? const Color(0xFF10B981).withOpacity(0.4)
                                  : const Color(0xFF10B981).withOpacity(0.3),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline_rounded, size: 22),
                            label: Text(
                              AppLocalizations.of(context)?.bookingDetails ?? 'تفاصيل الحجز',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF10B981),
                                Color(0xFF4F46E5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showOfferDialog(request),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)?.submit ?? 'قدم عرض',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }


  Widget _buildGradientBackground(String? categoryName, [double height = 180]) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Category Icon
          Center(
            child: Icon(
              _getCategoryIcon(categoryName),
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.cleaning_services;

    final category = categoryName.toLowerCase();
    if (category.contains('تنظيف') || category.contains('clean')) {
      return Icons.cleaning_services;
    } else if (category.contains('سباكة') || category.contains('plumb')) {
      return Icons.plumbing;
    } else if (category.contains('كهرباء') || category.contains('electric')) {
      return Icons.electrical_services;
    } else if (category.contains('طبخ') || category.contains('cook')) {
      return Icons.restaurant;
    } else if (category.contains('رعاية') || category.contains('care')) {
      return Icons.favorite;
    } else if (category.contains('تربية') || category.contains('child')) {
      return Icons.child_care;
    } else {
      return Icons.home_repair_service;
    }
  }

  // Helper method to translate booking request status
  String _translateRequestStatus(String statusLabel) {
    final cleanStatus = statusLabel.trim().toLowerCase();
    final loc = AppLocalizations.of(context);

    // Check for various status patterns
    if (cleanStatus.contains('قيد الانتظار') || cleanStatus.contains('pending')) {
      return loc?.pending ?? 'قيد الانتظار';
    } else if (cleanStatus.contains('قيد التنفيذ') || cleanStatus.contains('in progress') || cleanStatus.contains('in_progress')) {
      return loc?.inProgress ?? 'قيد التنفيذ';
    } else if (cleanStatus.contains('مكتمل') || cleanStatus.contains('completed')) {
      return loc?.completed ?? 'مكتمل';
    } else if (cleanStatus.contains('ملغي') || cleanStatus.contains('canceled') || cleanStatus.contains('cancelled')) {
      return loc?.cancelled ?? 'ملغي';
    } else if (cleanStatus.contains('لم') && cleanStatus.contains('عروض') || cleanStatus.contains('no offers')) {
      return loc?.noOffersReceived ?? 'لم تستلم عروض';
    } else if (cleanStatus.contains('تم استلام') || cleanStatus.contains('استلام') || cleanStatus.contains('received')) {
      // Extract number of offers if present
      final numbers = RegExp(r'\d+').allMatches(statusLabel);
      if (numbers.isNotEmpty) {
        final count = numbers.first.group(0);
        return '${loc?.receivedOffersText ?? 'تم استلام'} $count ${loc?.offers ?? 'عروض'}';
      }
      return loc?.offersReceived ?? 'تم استلام عروض';
    } else if (cleanStatus.contains('متاح') || cleanStatus.contains('available')) {
      return loc?.availableForOffers ?? 'متاح للعروض';
    } else if (cleanStatus.contains('جديد') || cleanStatus.contains('new')) {
      return loc?.newStatus ?? 'جديد';
    }

    // Return original if no match
    return statusLabel;
  }

  // Show offer dialog for provider to submit their offer
  Future<void> _showOfferDialog(BookingRequest request) async {
    // Debug: Check client profile picture URL

    // Check verification status
    final verificationStatus = _currentUser?.providerProfile?.verificationStatus;

    if (verificationStatus != 'VERIFIED') {
      // تحديد العنوان والرسالة حسب الحالة
      String title;
      String message;
      IconData iconData;
      Color iconColor;

      if (verificationStatus == 'PENDING') {
        title = AppLocalizations.of(context)?.pending ?? 'حسابك قيد المراجعة';
        message = 'انتظر الأدمن مراجعة ملفك الشخصي.';
        iconData = Icons.hourglass_empty;
        iconColor = Colors.orange;
      } else if (verificationStatus == 'REJECTED') {
        title = AppLocalizations.of(context)?.rejected ?? 'تم رفض حسابك';
        message = 'لا يحق لك تقديم طلب. تم رفض حسابك من قبل الإدارة.\n\nيرجى التواصل مع الإدارة لمعرفة الأسباب.';
        iconData = Icons.cancel_outlined;
        iconColor = Colors.red;
      } else {
        title = AppLocalizations.of(context)?.verificationRequiredTitle ?? 'التوثيق مطلوب';
        message = AppLocalizations.of(context)?.verificationRequiredMessageText ?? 'يجب أن يكون حسابك موثقاً لتقديم عروض على طلبات الحجز.\n\nيرجى إكمال بيانات ملفك الشخصي وتحميل المستندات المطلوبة.';
        iconData = Icons.verified_user_outlined;
        iconColor = const Color(0xFF10B981);
      }

      // Show dialog with appropriate message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              height: 1.5,
            ),
          ),
          actions: [
            ConnectivityTextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.ok ?? 'حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    // If VERIFIED, show the offer bottom sheet
    String priceAction = 'accept'; // 'accept' or 'counter'
    final priceController = TextEditingController(
      text: request.clientBudget?.toStringAsFixed(0) ?? '0',
    );
    final messageController = TextEditingController();

    // Prepare client profile picture URL
    String? clientProfilePicUrl = request.clientInfo?.profilePictureUrl ?? request.clientInfo?.profilePicture;
    if (clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty && !clientProfilePicUrl.startsWith('http')) {
      clientProfilePicUrl = '${ApiConfig.baseUrl}$clientProfilePicUrl';
    }

    // Capture localized strings before showing bottom sheet
    final messageToClientHint = AppLocalizations.of(context)?.messageToClientHint ?? 'مثال: لدي خبرة 5 سنوات في هذا المجال وأستطيع تقديم خدمة احترافية...';
    final egpCurrency = AppLocalizations.of(context)?.egpCurrency ?? 'جنيه';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AnimatedPadding(
            padding: MediaQuery.of(context).viewInsets,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        children: [
                          // Header Title with Icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)?.submit ?? 'تقديم عرض احترافي',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Client Info Card - Professional Design
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.08),
                                  const Color(0xFF4F46E5).withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Client Profile Section
                                Row(
                                  children: [
                                    // Client Profile Picture
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF10B981),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty
                                            ? Image.network(
                                                clientProfilePicUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(0xFF10B981).withOpacity(0.3),
                                                          const Color(0xFF4F46E5).withOpacity(0.3),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                        color: const Color(0xFF10B981),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: const Color(0xFF10B981).withOpacity(0.2),
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 32,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF10B981).withOpacity(0.3),
                                                      const Color(0xFF4F46E5).withOpacity(0.3),
                                                    ],
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 32,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Client Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  request.clientInfo?.fullName ?? (AppLocalizations.of(context)?.client ?? 'عميل'),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ),
                                              // Client Rating
                                              if (request.clientInfo?.rating != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star_rounded,
                                                        color: Color(0xFFFBBF24),
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        request.clientInfo!.rating!.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFFFBBF24),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  request.city ?? request.address,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Divider
                                Divider(
                                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                                  height: 1,
                                ),
                                const SizedBox(height: 16),
                                // Service Image - إضافة صورة الخدمة
                                if (request.serviceImage != null && request.serviceImage!.isNotEmpty) ...[
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withOpacity(0.2),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        request.serviceImage!.startsWith('http')
                                            ? request.serviceImage!
                                            : '${ApiConfig.baseUrl}${request.serviceImage}',
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF10B981).withOpacity(0.2),
                                                  const Color(0xFF4F46E5).withOpacity(0.2),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 3,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF10B981).withOpacity(0.2),
                                                  const Color(0xFF4F46E5).withOpacity(0.2),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.image_not_supported_outlined,
                                                    size: 48,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppLocalizations.of(context)?.cannotLoadImage ?? 'لا يمكن تحميل الصورة',
                                                    style: const TextStyle(
                                                      color: Color(0xFF10B981),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Service Title
                                Row(
                                  children: [
                                    Icon(
                                      Icons.engineering_rounded,
                                      color: const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode).isNotEmpty
                                            ? request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode)
                                            : '${AppLocalizations.of(context)?.bookingRequest ?? 'طلب حجز'} #${request.id}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Budget Display
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF10B981).withOpacity(0.15)
                                        : const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)?.clientBudget ?? 'ميزانية العميل',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${request.clientBudget?.toStringAsFixed(0) ?? '---'} ${AppLocalizations.of(context)?.egpCurrency ?? 'جنيه'}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Payment Fee Notice
                          const PaymentFeeNotice(compact: true),

                          const SizedBox(height: 20),

                          // Price Action Selection - Enhanced
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_offer_outlined,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)?.chooseOfferType ?? 'اختر نوع العرض',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Accept Button - Beautiful Card
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                priceAction = 'accept';
                                priceController.text = request.clientBudget?.toStringAsFixed(0) ?? '0';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: priceAction == 'accept'
                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                    : (isDark ? const Color(0xFF374151) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: priceAction == 'accept'
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  width: priceAction == 'accept' ? 3 : 2,
                                ),
                                boxShadow: priceAction == 'accept'
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: priceAction == 'accept'
                                          ? const Color(0xFF10B981)
                                          : (isDark ? Colors.grey[600] : Colors.grey[300]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      priceAction == 'accept'
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)?.accept ?? 'قبول سعر العميل',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: priceAction == 'accept'
                                                ? const Color(0xFF10B981)
                                                : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${request.clientBudget?.toStringAsFixed(0) ?? '---'} $egpCurrency',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: priceAction == 'accept'
                                                ? const Color(0xFF4F46E5)
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (priceAction == 'accept')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)?.selectedLabel ?? 'مختار',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Counter Button - Beautiful Card
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                priceAction = 'counter';
                                final clientBudget = request.clientBudget ?? 0;
                                priceController.text = (clientBudget + 50).toStringAsFixed(0);
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: priceAction == 'counter'
                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                    : (isDark ? const Color(0xFF374151) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: priceAction == 'counter'
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  width: priceAction == 'counter' ? 3 : 2,
                                ),
                                boxShadow: priceAction == 'counter'
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: priceAction == 'counter'
                                          ? const Color(0xFF10B981)
                                          : (isDark ? Colors.grey[600] : Colors.grey[300]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      priceAction == 'counter'
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)?.proposeDifferentPrice ?? 'اقتراح سعر مختلف',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: priceAction == 'counter'
                                                ? const Color(0xFF10B981)
                                                : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(context)?.mustBeHigherThanClientBudget ?? 'يجب أن يكون أعلى من ميزانية العميل',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (priceAction == 'counter')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)?.selectedLabel ?? 'مختار',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Price Input (only for counter) - Enhanced
                          if (priceAction == 'counter') ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)?.proposedPrice ?? 'السعر المقترح',
                                        labelStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF10B981),
                                        ),
                                        hintText: AppLocalizations.of(context)?.enterPriceEGPHint ?? 'أدخل السعر بالجنيه',
                                        hintStyle: TextStyle(
                                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                                        ),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.payments_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        suffixText: AppLocalizations.of(context)?.egpCurrency ?? 'جنيه',
                                        suffixStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // زر تأكيد لإغلاق الكيبورد (مهم لـ iOS)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    tooltip: 'تأكيد',
                                    padding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Message Field - Enhanced
                          Text(
                            '💬 ${AppLocalizations.of(context)?.messageToClient ?? 'رسالة للعميل'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF374151) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: messageController,
                              maxLines: 4,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: messageToClientHint,
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons - Enhanced
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    side: BorderSide(
                                      color: isDark ? Colors.grey[600]! : const Color(0xFF10B981),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.cancel ?? 'إلغاء',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: ConnectivityButton(
                                  onPressed: () {
                                    // Validate
                                    final offeredPrice = double.tryParse(priceController.text) ?? 0;
                                    final clientBudget = request.clientBudget ?? 0;

                                    if (priceAction == 'counter' && offeredPrice <= clientBudget) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error_outline, color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  AppLocalizations.of(context)?.proposedPriceMustBeHigher ?? 'السعر المقترح يجب أن يكون أعلى من ميزانية العميل',
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(context, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    elevation: 5,
                                    shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)?.sendOffer ?? 'إرسال العرض',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == true) {
      // Send offer to backend
      final offeredPrice = double.tryParse(priceController.text) ?? 0;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)?.loading ?? 'جاري إرسال العرض...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final offerResult = await WorkerOfferService.createOffer(
        bookingRequestId: request.id,
        priceAction: priceAction,
        offeredPrice: offeredPrice,
        message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      );

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (offerResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(offerResult.message ?? AppLocalizations.of(context)?.success ?? 'تم إرسال عرضك بنجاح'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the list to remove the request
          await _loadData();
          _loadUnreadNotificationsCount(); // تحديث عداد الإشعارات في حال وصول إشعارات جديدة
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(offerResult.error ?? AppLocalizations.of(context)?.failed ?? 'فشل إرسال العرض'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Dispose controllers safely
    try {
      priceController.dispose();
    } catch (_) {}
    try {
      messageController.dispose();
    } catch (_) {}
  }

  void _showRequestDetails(BookingRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Capture localized strings before showing bottom sheet
    final messageToClientHint = AppLocalizations.of(context)?.messageToClientHint ?? 'مثال: لدي خبرة 5 سنوات في هذا المجال وأستطيع تقديم خدمة احترافية...';

    // Get service image from API response
    String? serviceImageUrl = request.serviceImage;

    if (serviceImageUrl != null && serviceImageUrl.isNotEmpty) {
      // Add base URL if not absolute
      if (!serviceImageUrl.startsWith('http')) {
        serviceImageUrl = '${ApiConfig.baseUrl}$serviceImageUrl';
      }
    } else {
    }

    // Get client profile picture
    String? clientProfilePicUrl = request.clientInfo?.profilePictureUrl ?? request.clientInfo?.profilePicture;
    if (clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty && !clientProfilePicUrl.startsWith('http')) {
      clientProfilePicUrl = '${ApiConfig.baseUrl}$clientProfilePicUrl';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.zero,
                    children: [
                      // Hero Image Section - NO BORDER RADIUS, FULL WIDTH
                      Stack(
                        children: [
                          // Service Image with Gradient
                          if (serviceImageUrl != null && serviceImageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: serviceImageUrl,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _buildGradientBackground(request.categoryName, 300),
                            )
                          else
                            _buildGradientBackground(request.categoryName, 300),

                          // Gradient Overlay
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),

                          // Close Button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                          // Title & Budget
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode).isNotEmpty
                                      ? request.getLocalizedServiceTitle(Localizations.localeOf(context).languageCode)
                                      : '${AppLocalizations.of(context)?.bookingRequest ?? 'طلب حجز'} #${request.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${request.clientBudget?.toStringAsFixed(0) ?? '---'} ${AppLocalizations.of(context)?.egpCurrency ?? 'جنيه'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (request.getLocalizedCategoryName(Localizations.localeOf(context).languageCode).isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          request.getLocalizedCategoryName(Localizations.localeOf(context).languageCode),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Details Section
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client Info Card
                          if (request.clientInfo != null)
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981).withOpacity(0.12),
                                    const Color(0xFF4F46E5).withOpacity(0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Client Avatar
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                                      ),
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.5),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: clientProfilePicUrl != null && clientProfilePicUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: clientProfilePicUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 35,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 35,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.clientInfo!.fullName,
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (request.clientInfo?.rating != null && request.clientInfo!.rating! > 0)
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded, size: 20, color: Colors.amber[600]),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${request.clientInfo!.rating!.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                AppLocalizations.of(context)?.rating ?? 'تقييم',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)?.newClient ?? 'عميل جديد',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Details Grid
                          Text(
                            AppLocalizations.of(context)?.bookingDetails ?? 'تفاصيل الحجز',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildDetailCard(
                            icon: Icons.calendar_today_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: AppLocalizations.of(context)?.date ?? 'التاريخ',
                            value: '${request.bookingDate.day}/${request.bookingDate.month}/${request.bookingDate.year}',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildDetailCard(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF4F46E5),
                            title: AppLocalizations.of(context)?.time ?? 'الوقت',
                            value: request.bookingTime,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildDetailCard(
                            icon: Icons.timelapse_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: AppLocalizations.of(context)?.duration ?? 'المدة',
                            value: '${request.durationHours} ${AppLocalizations.of(context)?.hours ?? 'ساعات'}',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildDetailCard(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: AppLocalizations.of(context)?.location ?? 'الموقع',
                            value: request.location,
                            isDark: isDark,
                            fullWidth: true,
                          ),
                          const SizedBox(height: 12),

                          _buildDetailCard(
                            icon: Icons.info_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: AppLocalizations.of(context)?.status ?? 'الحالة',
                            value: _translateRequestStatus(request.statusLabel),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildDetailCard(
                            icon: Icons.local_offer_rounded,
                            iconColor: const Color(0xFF06B6D4),
                            title: AppLocalizations.of(context)?.offersCount ?? 'عدد العروض',
                            value: '${request.offersCount} ${request.offersCount == 1 ? (AppLocalizations.of(context)?.offer ?? 'عرض') : (AppLocalizations.of(context)?.offers ?? 'عروض')}',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 32),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ConnectivityButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showOfferDialog(request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 5,
                                shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppLocalizations.of(context)?.submit ?? 'قدم عرضك الآن',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151).withOpacity(0.5) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    // Simply return the full-featured bookings screen
    return ProviderActiveBookingsScreen();
  }

  Widget _buildProfileTab() {
    return Center(
      child: Text(AppLocalizations.of(context)?.comingSoon ?? 'صفحة الملف الشخصي - قريباً'),
    );
  }

  // Get country flag emoji
  String _getCountryFlag(String? country) {
    final countryLower = (country ?? (AppLocalizations.of(context)?.egypt ?? 'مصر')).toLowerCase();

    if (countryLower.contains('مصر') || countryLower.contains('egypt')) {
      return '🇪🇬';
    } else if (countryLower.contains('سعود') || countryLower.contains('saudi')) {
      return '🇸🇦';
    } else if (countryLower.contains('إمارات') || countryLower.contains('uae') || countryLower.contains('emirates')) {
      return '🇦🇪';
    } else if (countryLower.contains('كويت') || countryLower.contains('kuwait')) {
      return '🇰🇼';
    } else if (countryLower.contains('قطر') || countryLower.contains('qatar')) {
      return '🇶🇦';
    } else if (countryLower.contains('بحرين') || countryLower.contains('bahrain')) {
      return '🇧🇭';
    } else if (countryLower.contains('عمان') || countryLower.contains('oman')) {
      return '🇴🇲';
    } else if (countryLower.contains('أردن') || countryLower.contains('jordan')) {
      return '🇯🇴';
    } else if (countryLower.contains('لبنان') || countryLower.contains('lebanon')) {
      return '🇱🇧';
    } else {
      return '🌍'; // Default world emoji
    }
  }

  // Get location text (city or country)
  String _getLocationText() {
    final city = _currentUser?.providerProfile?.city;
    final country = _currentUser?.providerProfile?.country ?? (AppLocalizations.of(context)?.egypt ?? 'مصر');

    if (city != null && city.isNotEmpty) {
      return city;
    }
    return country;
  }

  // Build profile image widget (using raw API data like profile_screen.dart)
  Widget _buildProfileImage() {
    // Try to get profile_picture_url from raw API data first
    String? profilePicUrl = _providerProfileData?['profile_picture_url'] as String?;

    // Fallback to profile_picture
    if (profilePicUrl == null || profilePicUrl.isEmpty) {
      profilePicUrl = _providerProfileData?['profile_picture'] as String?;
    }


    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      String imageUrl = profilePicUrl;

      // Add base URL if not absolute
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }


      // Use CachedNetworkImage with optimized quality for sharp profile pic
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 52,
        height: 52,
        memCacheWidth: 156, // 3x resolution for sharp display (52 * 3)
        memCacheHeight: 156,
        maxWidthDiskCache: 156,
        maxHeightDiskCache: 156,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => Container(
          width: 52,
          height: 52,
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: 52,
            height: 52,
            color: const Color(0xFFF3F4F6),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: Color(0xFF4F46E5),
            ),
          );
        },
      );
    }

    // No image available, show icon
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.person_rounded,
        size: 32,
        color: Color(0xFF4F46E5),
      ),
    );
  }
}
