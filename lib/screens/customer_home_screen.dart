import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../models/service_model.dart';
import '../models/provider_model.dart';
import '../services/service_service.dart';
import '../services/provider_service.dart';
import '../services/notification_service.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'category_services_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'provider_details_screen.dart';
import 'service_detail_screen.dart';
import 'client_bookings_screen.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../widgets/complete_profile_dialog.dart';
import '../widgets/skeleton_loader.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/address_service.dart';
import '../services/push_notification_service.dart';
import 'chat_screen.dart';
import 'conversations_list_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/connectivity_button.dart';
import 'package:geocoding/geocoding.dart';
import '../mixins/connectivity_aware_mixin.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with ConnectivityAwareMixin {
  List<ServiceCategory> _categories = [];
  List<Service> _services = [];
  List<Provider> _providers = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Map to store calculated ratings for each provider (providerId -> {rating, count})
  final Map<int, Map<String, dynamic>> _providerRatings = {};

  // Use ValueNotifier to avoid rebuilding entire widget tree when counts change
  final ValueNotifier<int> _unreadNotificationsCount = ValueNotifier(0);
  final ValueNotifier<int> _unreadMessagesCount = ValueNotifier(0);

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Timer for auto-refresh notifications and messages
  Timer? _notificationRefreshTimer;

  // Timer for auto-scroll quick services
  Timer? _quickServicesAutoScrollTimer;

  // PageView controller for quick services
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ScrollController and GlobalKey for scrolling to available offers
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _availableOffersKey = GlobalKey();

  /// 🌐 Override من ConnectivityAwareMixin
  /// يُستدعى عند أول تحميل وعند رجوع الاتصال
  @override
  Future<void> fetchData() async {
    await _initializeData();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startNotificationAutoRefresh();
    _startQuickServicesAutoScroll();
    _setupNotificationListener();
  }

  /// إعداد listener للإشعارات عند النقر
  void _setupNotificationListener() {
    PushNotificationService().onNotificationTapped.listen((data) async {
      // التعامل مع إشعارات الشات
      if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
        final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');
        final senderName = data['sender_name']?.toString() ?? (AppLocalizations.of(context)?.user ?? 'User');

        if (conversationId != null) {
          // جلب الـ booking_id من الـ conversation
          await _navigateToChatFromConversation(conversationId, senderName);
        }
      }
      // التعامل مع باقي الإشعارات (حجز، عرض، إلخ) - الانتقال لصفحة الإشعارات
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

  /// الانتقال لصفحة الشات من conversation_id
  Future<void> _navigateToChatFromConversation(int conversationId, String senderName) async {
    try {
      // جلب معلومات المحادثة للحصول على booking_id
      final conversation = await ChatService.getConversationDetails(conversationId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            bookingId: conversation.bookingId,
            otherUserName: senderName,
          ),
        ),
      ).then((_) {
        // تحديث عدد الرسائل غير المقروءة بعد العودة من الشات
        _loadUnreadMessagesCount();
      });
    } catch (e) {
      // في حالة فشل جلب المحادثة، يمكن عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.chatOpenFailure ?? 'Failed to open chat')),
        );
      }
    }
  }

  /// تحميل البيانات بالترتيب الصحيح
  Future<void> _initializeData() async {
    await _loadUserData(); // تحميل بيانات المستخدم أولاً
    await _loadData(); // ثم تحميل الخدمات (لترتيبها حسب التفضيلات)
    _loadUnreadNotificationsCount(); // تحميل الإشعارات
    _loadUnreadMessagesCount(); // تحميل عدد الرسائل غير المقروءة
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _notificationRefreshTimer?.cancel();
    _quickServicesAutoScrollTimer?.cancel();
    _unreadNotificationsCount.dispose();
    _unreadMessagesCount.dispose();
    super.dispose();
  }

  void _scrollToAvailableOffers() {
    if (_availableOffersKey.currentContext != null) {
      Scrollable.ensureVisible(
        _availableOffersKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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

  /// تشغيل auto-scroll للخدمات السريعة كل 7 ثواني
  void _startQuickServicesAutoScroll() {
    _quickServicesAutoScrollTimer = Timer.periodic(
      const Duration(seconds: 7),
      (timer) {
        if (mounted && _pageController.hasClients) {
          final currentPage = _pageController.page?.round() ?? 0;
          final nextPage = (currentPage + 1) % (_getFilteredCategories().take(6).length);

          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  Future<void> _loadUserData() async {
    try {
      final token = ApiClient.authToken;
      if (token == null || token.isEmpty) {
        return;
      }

      ApiClient.setAuthToken(token);

      // جلب بيانات المستخدم الأساسية
      final meResp = await ApiClient.get(ApiConfig.me, needsAuth: true);

      if (meResp.success && meResp.rawResponse != null) {
        final meData = meResp.rawResponse as Map<String, dynamic>;
        final role = (meData['role'] ?? '').toString().toLowerCase();


        // لو المستخدم provider، جيب بيانات الـ profile بتاعه (فيها الصورة)
        if (role == 'provider') {
          final profileResp = await ApiClient.get(
            ApiConfig.providerProfile,
            needsAuth: true,
          );

          if (profileResp.success && profileResp.rawResponse != null) {
            final profileData = profileResp.rawResponse as Map<String, dynamic>;

            // دمج البيانات: بيانات المستخدم + بيانات الـ profile
            final merged = <String, dynamic>{};
            merged.addAll(meData);

            // أضف بيانات الـ profile (بدون الـ user المتداخل)
            profileData.forEach((k, v) {
              if (k != 'user') {
                merged[k] = v;
              }
            });


            setState(() {
              _userData = merged;
            });
            return;
          }
        } else if (role == 'client') {
          // لو client، جيب الـ addresses
          final profileResp = await ApiClient.get(
            ApiConfig.clientProfile,
            needsAuth: true,
          );

          if (profileResp.success && profileResp.rawResponse != null) {
            final profileData = profileResp.rawResponse as Map<String, dynamic>;

            final merged = <String, dynamic>{};
            merged.addAll(meData);
            profileData.forEach((k, v) {
              if (k != 'user') {
                merged[k] = v;
              }
            });


            setState(() {
              _userData = merged;
            });
            return;
          }
        }

        // لو مش provider ولا client، أو لو فشل جلب الـ profile، استخدم البيانات الأساسية
        setState(() {
          _userData = meData;
        });
      }
    } catch (e) {
    }
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
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final categories = await ServiceService.getCategories();
    final services = await ServiceService.getServices();
    final providers = await ProviderService.getTopRatedProviders(limit: 5);

    // Debug: print the data to see what we got

    if (categories.isNotEmpty) {
    }

    if (services.isNotEmpty) {
    }

    if (providers.isNotEmpty) {
    }

    // Sort services based on user's preferred categories
    final sortedServices = _sortServicesByPreference(services);

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _services = sortedServices;
      _providers = providers;
      _isLoading = false;
    });

    // Load ratings for all providers
    _loadAllProviderRatings();
  }

  /// تحميل التقييمات المحسوبة لكل الـ providers
  Future<void> _loadAllProviderRatings() async {
    for (final provider in _providers) {
      await _loadProviderRating(provider.id);
    }
  }

  /// تحميل التقييم المحسوب لـ provider واحد
  Future<void> _loadProviderRating(int providerId) async {
    try {
      final response = await ApiClient.get(
        ApiConfig.providerRatings(providerId),
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse;
        List<dynamic> ratings = [];

        // Handle different response formats
        if (data is List) {
          ratings = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('results')) {
            ratings = data['results'] as List? ?? [];
          } else if (data.containsKey('data')) {
            ratings = data['data'] as List? ?? [];
          } else if (data.containsKey('ratings')) {
            ratings = data['ratings'] as List? ?? [];
          }
        }

        if (ratings.isNotEmpty) {
          // حساب متوسط التقييمات
          double totalRating = 0.0;
          int validRatingsCount = 0;

          for (var rating in ratings) {
            if (rating is Map<String, dynamic> && rating.containsKey('rating')) {
              final ratingValue = rating['rating'];
              if (ratingValue != null) {
                totalRating += (ratingValue is int) ? ratingValue.toDouble() : (ratingValue as num).toDouble();
                validRatingsCount++;
              }
            }
          }

          if (validRatingsCount > 0) {
            final average = totalRating / validRatingsCount;
            setState(() {
              _providerRatings[providerId] = {
                'rating': average,
                'count': validRatingsCount,
              };
            });
          }
        }
      }
    } catch (e) {
    }
  }

  /// ترتيب الخدمات حسب التفضيلات - الخدمات المفضلة أولاً
  List<Service> _sortServicesByPreference(List<Service> services) {

    // إذا لم يكن هناك بيانات مستخدم أو تفضيلات، نرجع القائمة كما هي
    if (_userData == null) {
      return services;
    }


    if (_userData!['preferred_service_categories'] == null) {
      return services;
    }

    try {
      final List<int> preferredCategoryIds =
          List<int>.from(_userData!['preferred_service_categories']);

      if (preferredCategoryIds.isEmpty) {
        return services;
      }


      // طباعة كل الخدمات مع categories بتاعتها
      for (var service in services) {
      }

      // فصل الخدمات إلى مفضلة وغير مفضلة
      final preferredServices = <Service>[];
      final otherServices = <Service>[];

      for (var service in services) {
        final isPreferred = preferredCategoryIds.contains(service.category.id);

        if (isPreferred) {
          preferredServices.add(service);
        } else {
          otherServices.add(service);
        }
      }

      for (var service in preferredServices) {
      }

      for (var service in otherServices) {
      }

      // دمج القوائم - المفضلة أولاً ثم البقية
      final sorted = [...preferredServices, ...otherServices];

      for (int i = 0; i < sorted.length; i++) {
      }


      return sorted;
    } catch (e) {
      return services;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  // Helper methods to format date and time
  String _formatDate(DateTime date) {
    final List<String> arabicDays = [
      AppLocalizations.of(context)?.monday ?? 'Monday',
      AppLocalizations.of(context)?.tuesday ?? 'Tuesday',
      AppLocalizations.of(context)?.wednesday ?? 'Wednesday',
      AppLocalizations.of(context)?.thursday ?? 'Thursday',
      AppLocalizations.of(context)?.friday ?? 'Friday',
      AppLocalizations.of(context)?.saturday ?? 'Saturday',
      AppLocalizations.of(context)?.sunday ?? 'Sunday',
    ];

    final List<String> arabicMonths = [
      AppLocalizations.of(context)?.january ?? 'January',
      AppLocalizations.of(context)?.february ?? 'February',
      AppLocalizations.of(context)?.march ?? 'March',
      AppLocalizations.of(context)?.april ?? 'April',
      AppLocalizations.of(context)?.may ?? 'May',
      AppLocalizations.of(context)?.june ?? 'June',
      AppLocalizations.of(context)?.july ?? 'July',
      AppLocalizations.of(context)?.august ?? 'August',
      AppLocalizations.of(context)?.september ?? 'September',
      AppLocalizations.of(context)?.october ?? 'October',
      AppLocalizations.of(context)?.november ?? 'November',
      AppLocalizations.of(context)?.december ?? 'December',
    ];

    final dayName = arabicDays[date.weekday - 1];
    final monthName = arabicMonths[date.month - 1];

    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? (AppLocalizations.of(context)?.morning ?? 'AM') : (AppLocalizations.of(context)?.evening ?? 'PM');

    return '$hour:$minute $period';
  }

  Future<void> _showBookingDialog(Service service) async {
    // التحقق من اكتمال البيانات أولاً
    final profileCheck = await ProfileCompletionChecker.showCompletionDialogIfNeeded(context);

    if (profileCheck == 'go_to_edit') {
      // المستخدم اختار التوجيه لشاشة التعديل
      if (mounted) {
        final updated = await Navigator.of(context).pushNamed('/edit-client-profile');

        // بعد ما يرجع من شاشة التعديل، نتحقق لو البيانات اكتملت
        if (updated == true && mounted) {
          // نعيد محاولة الحجز
          _showBookingDialog(service);
        }
      }
      return;
    } else if (profileCheck != 'complete') {
      // المستخدم ألغى
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    int durationHours = service.estimatedDuration > 0
        ? service.estimatedDuration
        : 8;

    // العناوين المحفوظة
    List<Map<String, dynamic>> savedAddresses = [];
    Map<String, dynamic>? selectedAddress;
    bool isLoadingAddresses = true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // تحميل العناوين عند فتح ال Bottom Sheet
          if (isLoadingAddresses) {
            AddressService.getAddresses().then((response) {
              if (response.success && response.data != null) {
                setState(() {
                  savedAddresses = response.data!;
                  isLoadingAddresses = false;
                  // اختيار العنوان الافتراضي تلقائياً
                  if (savedAddresses.isNotEmpty) {
                    selectedAddress = savedAddresses.firstWhere(
                      (addr) => addr['is_default'] == true,
                      orElse: () => savedAddresses.first,
                    );
                  }
                });
              } else {
                setState(() {
                  isLoadingAddresses = false;
                });
              }
            });
          }

          return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header بنفسجي جميل
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.newBookingTitle ?? 'حجز جديد',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تعريف منزلي شامل',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // تاريخ الحجز - Dropdown Style
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)?.bookingDateLabel ?? 'تاريخ الحجز',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDate(selectedDate),
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF4F46E5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // وقت الحجز - Dropdown Style
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)?.bookingTimeLabel ?? 'وقت الحجز',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatTime(selectedTime),
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF4F46E5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // مدة الخدمة (ساعات)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.timelapse,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)?.serviceDurationLabel ?? 'مدة الخدمة (ساعات)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: AppLocalizations.of(context)?.durationExampleHint ?? 'مثالاً: 8 ساعات',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: durationHours.toString(),
                                )..selection = TextSelection.fromPosition(
                                    TextPosition(offset: durationHours.toString().length),
                                  ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed >= 1 && parsed <= 24) {
                                    setState(() {
                                      durationHours = parsed;
                                    });
                                  }
                                },
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)?.hour ?? 'ساعة',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // اختر العنوان
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)?.selectAddressLabel ?? 'اختر العنوان',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // قائمة العناوين أو رسالة تحميل
                      if (isLoadingAddresses)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                          ),
                        )
                      else if (savedAddresses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.location_off,
                                color: Color(0xFF4F46E5),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)?.noAddressesYetMessage ?? 'لا توجد عناوين محفوظة',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)?.pleaseAddAddressMessage ?? 'يرجى إضافة عنوان من إعدادات الحساب',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...savedAddresses.map((address) {
                          final isSelected = selectedAddress != null && selectedAddress!['id'] == address['id'];
                          final isDefault = address['is_default'] == true;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAddress = address;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4F46E5).withOpacity(0.05)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF4F46E5).withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.home,
                                      color: Color(0xFF4F46E5),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)?.defaultAddressLabel ?? 'افتراضي',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isDefault) const SizedBox(height: 8),
                                        Text(
                                          address['address'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address['city'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4F46E5),
                                      size: 24,
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              // زر الحجز
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ConnectivityButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );

    if (result == true && selectedAddress != null) {
      await _createBookingRequest(
        service: service,
        bookingDate: selectedDate,
        bookingTime: selectedTime,
        durationHours: durationHours,
        city: selectedAddress!['city'] ?? '',
        address: selectedAddress!['address'] ?? '',
      );
    } else if (result == true && selectedAddress == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseSelectAddressMessage ?? 'يرجى اختيار عنوان'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createBookingRequest({
    required Service service,
    required DateTime bookingDate,
    required TimeOfDay bookingTime,
    required int durationHours,
    required String city,
    required String address,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );

    final timeString = '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}:00';


    final result = await BookingService.createBookingRequest(
      serviceId: service.id,
      categoryId: service.category.id,
      bookingDate: bookingDate,
      bookingTime: timeString,
      durationHours: durationHours,
      city: city,
      address: address,
      clientBudget: service.basePrice,
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (result.success) {
    } else {
    }

    // Show result message
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.surface),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the home screen data
        await Future.delayed(const Duration(milliseconds: 500));
        _loadData();
        _loadUnreadNotificationsCount();
      } else {
        // Show error dialog with detailed info
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.bookingError ?? 'خطأ في الحجز'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.error!,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity( 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.troubleshootingTipsLabel ?? 'نصائح لحل المشكلة:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('1. ${AppLocalizations.of(context)?.troubleshootingTip1 ?? 'تأكد من أن السيرفر شغال على المنفذ 8000'}', style: const TextStyle(fontSize: 13)),
                        Text('2. ${AppLocalizations.of(context)?.troubleshootingTip2 ?? 'تحقق من إعدادات الشبكة'}', style: const TextStyle(fontSize: 13)),
                        Text('3. ${AppLocalizations.of(context)?.troubleshootingTip3 ?? 'راجع الـ console للمزيد من التفاصيل'}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ConnectivityTextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)?.ok ?? 'حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  List<Service> _getFilteredServices() {
    if (!_isSearching) return _services;

    final lowerQuery = _searchQuery.toLowerCase();
    return _services.where((service) {
      final serviceName = service.name.toLowerCase();
      final categoryName = service.category.name.toLowerCase();
      final description = service.description.toLowerCase();

      return serviceName.contains(lowerQuery) ||
          categoryName.contains(lowerQuery) ||
          description.contains(lowerQuery);
    }).toList();
  }

  List<Provider> _getFilteredProviders() {
    if (!_isSearching) return _providers;

    final lowerQuery = _searchQuery.toLowerCase();
    return _providers.where((provider) {
      final fullName = provider.fullName.toLowerCase();
      return fullName.contains(lowerQuery);
    }).toList();
  }

  List<ServiceCategory> _getFilteredCategories() {
    if (!_isSearching) return _categories;

    final lowerQuery = _searchQuery.toLowerCase();
    return _categories.where((category) {
      final categoryName = category.name.toLowerCase();
      return categoryName.contains(lowerQuery);
    }).toList();
  }

  // دالة للتحقق من رغبة المستخدم في الخروج
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Color(0xFF4F46E5)),
            const SizedBox(width: 12),
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
              backgroundColor: const Color(0xFF4F46E5),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
        backgroundColor: kPageBg,
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple header (greeting + notification + search bar)
              _buildHeader(),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Services
                    _sectionTitle('Quick Services'),
                    const SizedBox(height: 16),
                    _buildQuickServices(),

                    const SizedBox(height: 24),

                    // Available Offers
                    KeyedSubtree(
                      key: _availableOffersKey,
                      child: _sectionTitle('Available Offers'),
                    ),
                    const SizedBox(height: 16),
                    _buildAvailableOffers(),

                    const SizedBox(height: 24),

                    // Available Workers
                    _sectionTitle('Available Workers'),
                    const SizedBox(height: 16),
                    _buildPopularWorkers(),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        // Bottom Navigation Bar - kept as-is
        bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  // ---- Figma design tokens (home page) ----
  static const Color kPrimary = Color(0xFF8B5CF6);
  static const Color kPageBg = Color(0xFFF7F7F7);
  static const Color kNavGray = Color(0xFF7D7F88);
  static const Color kPriceDark = Color(0xFF1A1E25);
  static const Color kSearchBg = Color(0xFFF2F2F3);
  static const Color kSearchBorder = Color(0xFFE3E3E7);
  static const Color kDotInactive = Color(0xFFD9D9D9);
  static const Color kWorkerGradient = Color(0xFF515FFF);
  static const Color kStar = Color(0xFFFFBE55);

  /// Section heading — Inter Medium 16, black (Figma).
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        height: 1.3,
      ),
    );
  }

  /// English per-unit label for offer prices (Figma: "/ For Every Task").
  String _unitLabelEn(Service service) {
    switch (service.unit) {
      case 'HOUR':
        return 'For Every Hour';
      case 'DAY':
        return 'For Every Day';
      case 'TASK':
        return 'For Every Task';
      default:
        return service.unit;
    }
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: kPrimary,
      padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row: avatar + name/location + notification bell
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final token = ApiClient.authToken;
                  if (token != null && token.isNotEmpty) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(token: token),
                      ),
                    );
                    await _loadUserData();
                    await _loadData();
                    _loadUnreadNotificationsCount();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first')),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(child: _getProfileImage()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${_userData?['first_name'] ?? 'User'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getHeaderLocation(),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 18,
                          color: kPrimary,
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _unreadNotificationsCount,
                        builder: (context, count, child) {
                          if (count == 0) return const SizedBox.shrink();
                          return Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimary, width: 1.5),
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
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildSearchBar(),
        ],
      ),
    );
  }

  /// Header location text (English, LTR). City if available, else "Egypt".
  String _getHeaderLocation() {
    if (_userData != null && _userData!['addresses'] != null) {
      final addresses = _userData!['addresses'] as List?;
      if (addresses != null && addresses.isNotEmpty) {
        final firstAddress = addresses[0] as Map<String, dynamic>;
        final city = (firstAddress['city'] ?? '').toString();
        if (city.isNotEmpty) return city;
      }
    }
    return 'Egypt';
  }

  /// شريط التنقل السفلي الاحترافي
  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return provider_pkg.Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) => Container(
        key: ValueKey(languageProvider.locale.languageCode),
      height: 62,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // الأزرار العادية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. زر الرئيسية
                  _buildBottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: AppLocalizations.of(context)?.home ?? 'الرئيسية',
                    isDark: isDark,
                    isActive: true,
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),

                  // 2. زر الشات
                  ValueListenableBuilder<int>(
                    valueListenable: _unreadMessagesCount,
                    builder: (context, count, child) {
                      return _buildBottomNavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: AppLocalizations.of(context)?.conversations ?? 'المحادثات',
                        isDark: isDark,
                        badgeCount: count,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationsListScreen(),
                            ),
                          );
                          _loadUnreadMessagesCount();
                        },
                      );
                    },
                  ),

                  // 3. مساحة فارغة للزر المركزي
                  const SizedBox(width: 56),

                  // 4. زر الحجوزات
                  _buildBottomNavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: AppLocalizations.of(context)?.myBookings ?? 'حجوزاتي',
                    isDark: isDark,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientBookingsScreen(),
                        ),
                      );
                      if (!mounted) return;
                      await _loadUserData();
                      await _loadData();
                      _loadUnreadNotificationsCount();
                    },
                  ),

                  // 5. زر البروفايل
                  _buildBottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: AppLocalizations.of(context)?.profile ?? 'حسابي',
                    isDark: isDark,
                    onTap: () async {
                      final token = ApiClient.authToken;
                      if (token != null && token.isNotEmpty) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(token: token),
                          ),
                        );
                        await _loadUserData();
                        await _loadData();
                        _loadUnreadNotificationsCount();
                      }
                    },
                  ),
                ],
              ),
            ),

            // الزر المركزي البارز (الزائد)
            Positioned(
              top: -12,
              child: GestureDetector(
                onTap: () {
                  _scrollToAvailableOffers();
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// عنصر واحد من عناصر شريط التنقل السفلي
  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool isActive = false,
  }) {
    final color = isActive
        ? const Color(0xFF4F46E5)
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 23,
                  color: color,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: kSearchBg,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: kSearchBorder, width: 0.8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.search, size: 24, color: kPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
              cursorColor: kPrimary,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Search address, city, location',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: kNavGray,
                  letterSpacing: 0.32,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSearching
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.clear, size: 20, color: kNavGray),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : const Icon(Icons.tune, size: 24, color: kPrimary),
          const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _buildQuickServices() {
    if (_isLoading) {
      return const SkeletonQuickServices();
    }

    final filteredCategories = _getFilteredCategories();

    if (filteredCategories.isEmpty) {
      return SizedBox(
        height: 208,
        child: Center(
          child: Text(
            _isSearching ? 'No results found' : 'No services available',
            style: GoogleFonts.inter(fontSize: 14, color: kNavGray),
          ),
        ),
      );
    }

    final displayCategories = filteredCategories.take(6).toList();

    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _pageController,
            itemCount: displayCategories.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              String? imageUrl = category.image ?? category.icon;
              if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = '${ApiConfig.baseUrl}$imageUrl';
              }
              final title = category.nameEn.isNotEmpty ? category.nameEn : category.name;
              final subtitle = (category.description ?? '').isNotEmpty
                  ? category.description!
                  : 'Tap to explore this service';

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryServicesScreen(
                        categories: _categories,
                        initialCategory: category,
                      ),
                    ),
                  );
                  if (result == true) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    _loadData();
                    _loadUnreadNotificationsCount();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: kPrimary),
                          errorWidget: (context, url, error) => Container(color: kPrimary),
                        )
                      else
                        Container(color: kPrimary),
                      Container(color: Colors.black.withOpacity(0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 229),
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 229),
                              child: Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFC4C4C4),
                                  letterSpacing: 0.18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                'Press to explore',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCategories.length, (index) {
            final active = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: active ? 7 : 10,
              width: active ? 20 : 10,
              decoration: BoxDecoration(
                color: active ? kPrimary : kDotInactive,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAvailableOffers() {
    if (_isLoading) {
      return const SkeletonAvailableOffers();
    }

    final filteredServices = _getFilteredServices();

    List<Service> displayServices = filteredServices.where((service) => service.isFeatured).toList();
    if (displayServices.isEmpty && filteredServices.isNotEmpty) {
      displayServices = filteredServices.take(5).toList();
    }

    if (displayServices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _isSearching ? 'No results found' : 'No offers available',
            style: GoogleFonts.inter(fontSize: 14, color: kNavGray),
          ),
        ),
      );
    }

    return Column(
      children: displayServices.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(service: service),
                ),
              );
              if (result == true) {
                await Future.delayed(const Duration(milliseconds: 500));
                _loadData();
                _loadUnreadNotificationsCount();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: _offerImage(service),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _offerTitle(service),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.favorite_border, size: 18, color: kNavGray),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _offerCategory(service),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: kNavGray,
                            letterSpacing: 0.13,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${service.basePrice.toStringAsFixed(0)}EGP',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kPriceDark,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: '  / ${_unitLabelEn(service)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: kNavGray,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ConnectivityButton(
                            onPressed: () => _showBookingDialog(service),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimary,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size.fromHeight(40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: kPrimary, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Book Now',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: kPrimary,
                                letterSpacing: 0.18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _offerImage(Service service) {
    String? imageUrl = service.image;
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiConfig.baseUrl}$imageUrl';
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 149,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(height: 149, color: const Color(0xFFEDEAFB)),
        errorWidget: (context, url, error) => _offerImageFallback(),
      );
    }
    return _offerImageFallback();
  }

  Widget _offerImageFallback() {
    return Container(
      height: 149,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA78BFA), kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_repair_service, size: 48, color: Colors.white70),
      ),
    );
  }

  String _offerTitle(Service service) =>
      service.nameEn.isNotEmpty ? service.nameEn : service.name;

  String _offerCategory(Service service) =>
      service.category.nameEn.isNotEmpty ? service.category.nameEn : service.category.name;

  Widget _buildPopularWorkers() {
    if (_isLoading) {
      return const SkeletonPopularWorkers();
    }

    final filteredProviders = _getFilteredProviders();

    if (filteredProviders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _isSearching ? 'No results found' : 'No workers available',
            style: GoogleFonts.inter(fontSize: 14, color: kNavGray),
          ),
        ),
      );
    }

    final topProviders = filteredProviders.take(10).toList();

    return SizedBox(
      height: 209,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: topProviders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final provider = topProviders[index];
          final rating = (_providerRatings[provider.id]?['rating'] ?? provider.averageRating ?? 0.0) as num;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderDetailsScreen(providerId: provider.id),
                ),
              );
            },
            child: SizedBox(
              width: 147,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _workerImage(provider),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.55, 1.0],
                          colors: [Colors.transparent, kWorkerGradient.withOpacity(0.9)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: kStar),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 9,
                      bottom: 12,
                      child: Text(
                        provider.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F8FE),
                        ),
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
  }

  Widget _workerImage(Provider provider) {
    String? url = provider.profilePicture;
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      url = '${ApiConfig.baseUrl}$url';
    }
    final letter = provider.fullName.isNotEmpty ? provider.fullName[0].toUpperCase() : '?';
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, u) => Container(color: kPrimary),
        errorWidget: (context, u, e) => _workerImageFallback(letter),
      );
    }
    return _workerImageFallback(letter);
  }

  Widget _workerImageFallback(String letter) {
    return Container(
      color: kPrimary,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getLocationText() {
    // جرب تجيب المدينة من الـ addresses لو كان client
    if (_userData != null && _userData!['addresses'] != null) {
      final addresses = _userData!['addresses'] as List?;
      if (addresses != null && addresses.isNotEmpty) {
        final firstAddress = addresses[0] as Map<String, dynamic>;
        final city = firstAddress['city'] ?? '';
        if (city.isNotEmpty) {
          return '$city، ${AppLocalizations.of(context)?.egyptCountry ?? 'مصر'}';
        }
      }
    }

    // لو مفيش موقع، اعرض رسالة افتراضية
    return AppLocalizations.of(context)?.egyptCountry ?? 'مصر';
  }

  String _getCountryFlag() {
    // علم مصر 🇪🇬
    return '🇪🇬';
  }

  Widget _getProfileImage() {
    // جرب تجيب الصورة من البيانات
    String? profilePicUrl;

    if (_userData != null) {
      // جرب profile_picture_url أول حاجة (للـ providers)
      profilePicUrl = _userData!['profile_picture_url'] as String?;

      // لو مش موجود، جرب profile_picture
      if (profilePicUrl == null || profilePicUrl.isEmpty) {
        profilePicUrl = _userData!['profile_picture'] as String?;
      }
    }

    // لو فيه صورة، اعرضها
    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      String imageUrl = profilePicUrl;

      // لو الـ URL مش بادي بـ http، ضيف الـ base URL
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      // استخدام CachedNetworkImage بدلاً من Image.network لتحسين الأداء
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4F46E5),
          ),
        ),
        errorWidget: (context, url, error) {
          // لو الصورة مش شغالة، اعرض الأيقونة الافتراضية
          return _getDefaultAvatar();
        },
      );
    }

    // لو مفيش صورة، اعرض الأيقونة الافتراضية
    return _getDefaultAvatar();
  }

  Widget _getDefaultAvatar() {
    final hasName = _userData != null &&
        _userData!['first_name'] != null &&
        (_userData!['first_name'] as String).isNotEmpty;
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: hasName
          ? Text(
              (_userData!['first_name'] as String)[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: kPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            )
          : const Icon(Icons.person, color: Color(0xFFBDBDBD), size: 24),
    );
  }

  Widget _getProviderImage(Provider provider) {
    // جرب تجيب الصورة من الـ provider
    String? profilePicUrl = provider.profilePicture;

    // لو فيه صورة، اعرضها
    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      String imageUrl = profilePicUrl;

      // لو الـ URL مش بادي بـ http، ضيف الـ base URL
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      // استخدام CachedNetworkImage بدلاً من Image.network لتحسين الأداء
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4F46E5),
          ),
        ),
        errorWidget: (context, url, error) {
          // لو الصورة مش شغالة، اعرض الأيقونة الافتراضية
          return _getDefaultProviderAvatar(provider);
        },
      );
    }

    // لو مفيش صورة، اعرض الأيقونة الافتراضية
    return _getDefaultProviderAvatar(provider);
  }

  Widget _getDefaultProviderAvatar(Provider provider) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Text(
          provider.fullName.isNotEmpty
              ? provider.fullName[0].toUpperCase()
              : '👤',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper method to build service image
  Widget _buildServiceImage(Service service, Color categoryColor) {
    if (service.image != null && service.image!.isNotEmpty) {
      String imageUrl = service.image!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '\${ApiConfig.baseUrl}\$imageUrl';
      }

      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_repair_service,
                color: categoryColor,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }

    // Fallback to icon
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.home_repair_service,
        color: categoryColor,
        size: 30,
      ),
    );
  }



  // Helper method to get service name based on current language
  String _getServiceName(Service service) {
    final languageProvider = provider_pkg.Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.locale.languageCode == 'ar';
    return isArabic ? service.name : service.nameEn;
  }

  // Helper method to get category name based on current language
  String _getCategoryName(ServiceCategory category) {
    final languageProvider = provider_pkg.Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.locale.languageCode == 'ar';
    return isArabic ? category.name : category.nameEn;
  }

  // Widget when no addresses exist
  Widget _buildNoAddressWidget(
    bool isDark,
    StateSetter setModalState,
    List<Map<String, dynamic>> savedAddresses,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 48,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noAddressesYetMessage ?? 'لا توجد عناوين محفوظة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.noAddressesSavedMessage ?? 'قم بإضافة عنوان جديد للمتابعة',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ConnectivityIconButton(
            onPressed: () => _showAddAddressDialog(setModalState, savedAddresses, setSelectedAddress),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_location_alt, size: 20),
            label: Text(
              AppLocalizations.of(context)?.addNewAddressButton ?? 'إضافة عنوان جديد',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build address cards for selection
  List<Widget> _buildAddressCards(
    bool isDark,
    List<Map<String, dynamic>> addresses,
    Map<String, dynamic>? selectedAddress,
    StateSetter setModalState,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) {
    final List<Widget> widgets = [];

    // Add saved address cards
    for (var address in addresses) {
      final isSelected = selectedAddress?['id'] == address['id'];
      final isDefault = address['is_default'] == true;

      widgets.add(
        GestureDetector(
          onTap: () {
            setModalState(() {
              setSelectedAddress(address);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4F46E5).withOpacity(0.1)
                  : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF4F46E5).withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDefault ? Icons.home : Icons.location_on,
                    color: const Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Address details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address['label'] ?? (AppLocalizations.of(context)?.addressLabelDefault ?? 'عنوان'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF4F46E5) : null,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.defaultAddressLabel ?? 'افتراضي',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address['address'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            address['city'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Add "Add New Address" button
    widgets.add(
      const SizedBox(height: 8),
    );
    widgets.add(
      OutlinedButton.icon(
        onPressed: () => _showAddAddressDialog(setModalState, addresses, setSelectedAddress),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add_location_alt, size: 22),
        label: Text(
          AppLocalizations.of(context)?.addNewAddressButton ?? 'إضافة عنوان جديد',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return widgets;
  }

  // Show dialog to add new address with GPS
  Future<void> _showAddAddressDialog(
    StateSetter setModalState,
    List<Map<String, dynamic>> savedAddresses,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) async {
    final TextEditingController labelController = TextEditingController();
    bool isDetecting = false;
    String? detectedAddress;
    String? detectedCity;
    double? latitude;
    double? longitude;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_location_alt,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.addNewAddressButton ?? 'إضافة عنوان جديد',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label input
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.addressLabelOptionalHint ?? 'تسمية العنوان (اختياري)',
                        hintText: AppLocalizations.of(context)?.exampleHomeWorkHint ?? 'مثل: المنزل، العمل، إلخ',
                        prefixIcon: const Icon(Icons.label, color: Color(0xFF4F46E5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Detect location button
                    ConnectivityIconButton(
                      onPressed: isDetecting
                          ? null
                          : () async {
                              setDialogState(() {
                                isDetecting = true;
                              });

                              try {
                                // Check location permission
                                LocationPermission permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    throw Exception(AppLocalizations.of(context)?.locationPermissionDeniedError ?? 'تم رفض إذن الموقع');
                                  }
                                }

                                if (permission == LocationPermission.deniedForever) {
                                  throw Exception(AppLocalizations.of(context)?.locationPermissionDeniedPermanentlyError ?? 'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات');
                                }

                                // Get current position
                                Position position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                                latitude = position.latitude;
                                longitude = position.longitude;

                                // Reverse geocoding to get address
                                List<Placemark> placemarks = await placemarkFromCoordinates(
                                  position.latitude,
                                  position.longitude,
                                );

                                if (placemarks.isNotEmpty) {
                                  final place = placemarks.first;
                                  setDialogState(() {
                                    detectedCity = place.locality ?? place.administrativeArea ?? (AppLocalizations.of(context)?.unspecifiedText ?? 'غير محدد');
                                    detectedAddress = [
                                      place.street,
                                      place.subLocality,
                                      place.locality,
                                    ].where((e) => e != null && e.isNotEmpty).join(', ');
                                    isDetecting = false;
                                  });
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isDetecting = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)?.failedToDetectLocationMessage.replaceAll('{error}', e.toString()) ?? 'فشل تحديد الموقع: \u200F${e.toString()}\u200F'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: isDetecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location, size: 22),
                      label: Text(
                        isDetecting
                            ? (AppLocalizations.of(context)?.detectingLocationStatus ?? 'جاري تحديد الموقع...')
                            : (AppLocalizations.of(context)?.detectMyCurrentLocationButton ?? 'تحديد موقعي الحالي'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                    if (detectedAddress != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)?.locationDetectedSuccessMessage ?? 'تم تحديد الموقع بنجاح',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_city, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)?.cityLabelText ?? 'المدينة'}: $detectedCity',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)?.addressLabelText ?? 'العنوان'}: $detectedAddress',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                ConnectivityTextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
                ),
                ConnectivityButton(
                  onPressed: (detectedAddress != null && latitude != null && longitude != null)
                      ? () async {
                          Navigator.pop(context);

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                            ),
                          );

                          // Add address
                          final result = await AddressService.addAddress(
                            label: labelController.text.trim().isEmpty ? null : labelController.text.trim(),
                            latitude: latitude!,
                            longitude: longitude!,
                            address: detectedAddress!,
                            city: detectedCity ?? 'غير محدد',
                            country: 'Egypt',
                            isDefault: false,
                          );

                          if (mounted) {
                            Navigator.pop(context); // Close loading

                            if (result.success) {
                              // Refresh addresses
                              final addressesResponse = await AddressService.getAddresses();
                              if (addressesResponse.success && addressesResponse.data != null) {
                                setModalState(() {
                                  // Clear and update the savedAddresses list
                                  savedAddresses.clear();
                                  savedAddresses.addAll(addressesResponse.data!);

                                  // Select the newly added address
                                  final newAddress = savedAddresses.firstWhere(
                                    (addr) => addr['address'] == detectedAddress,
                                    orElse: () => savedAddresses.last,
                                  );
                                  setSelectedAddress(newAddress);
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)?.addressAddedSuccess ?? 'تم إضافة العنوان بنجاح'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.error ?? (AppLocalizations.of(context)?.failedToAddAddress ?? 'فشل إضافة العنوان')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)?.saveButtonText ?? 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  }


