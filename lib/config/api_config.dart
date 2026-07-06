class ApiConfig {
  // ========================================
  // ⚙️ إعدادات الـ URL - مهم جداً!
  // ========================================
  // بيئة الإنتاج (Production):
  // - استخدم دومين السيرفر مع HTTPS
  // - السيرفر: https://amina.bdcbiz.com
  //
  // بيئة التطوير (Development):
  // - للتجربة على Android Emulator: استخدم 10.0.2.2
  // - للتجربة على جهاز Android حقيقي: استخدم IP الجهاز (مثل 192.168.x.x)
  // - للتجربة على iOS Simulator: استخدم localhost أو 127.0.0.1
  //
  // كيف تحصل على الـ IP بتاع جهازك؟
  // - Windows: افتح cmd واكتب ipconfig
  // - Mac/Linux: افتح Terminal واكتب ifconfig
  //
  // ملاحظة: السيرفر الحالي مثبت عليه PostgreSQL 17 و SSL Certificate صالح
  // ========================================

  // ========================================
  // 🔧 اختر البيئة المناسبة
  // ========================================

  // Production Environment - HTTPS Enabled for Security
  static const String baseUrl = 'https://amina.bdcbiz.com';
  // 🔧 WEBSOCKET FIX: Must include explicit port for WSS (443 for secure, 80 for non-secure)
  // Without port, Flutter's Uri.parse may default to port 0
  static const String wsUrl = 'wss://amina.bdcbiz.com:443';

  // Option 3: Development Environments (للتطوير المحلي)
  // static const String baseUrl = 'http://10.0.2.2:8000'; // لسيرفر جانجو المحلي (Android Emulator)
  // static const String wsUrl = 'ws://10.0.2.2:8000'; // WebSocket للـ Android Emulator
  // static const String baseUrl = 'http://192.168.8.40:8000'; // للجهاز الحقيقي (غير الـ IP حسب شبكتك)
  // static const String wsUrl = 'ws://192.168.8.40:8000'; // WebSocket للجهاز الحقيقي
  // static const String baseUrl = 'http://localhost:8000'; // لـ iOS Simulator
  // static const String wsUrl = 'ws://localhost:8000'; // WebSocket للـ iOS Simulator

  // API Endpoints
  static const String apiPrefix = '/api';

  // Auth Endpoints
  static const String registerClient = '$apiPrefix/users/auth/register_client/';
  static const String registerProvider = '$apiPrefix/users/auth/register_provider/';
  static const String login = '$apiPrefix/users/auth/login/';
  static const String logout = '$apiPrefix/users/auth/logout/';
  static const String me = '$apiPrefix/users/auth/me/';
  static const String changePassword = '$apiPrefix/users/auth/change_password/';
  static const String googleAuth = '$apiPrefix/users/auth/google/';
  // OTP Login Endpoints
  static const String sendOtp = '$apiPrefix/users/auth/send_otp/';
  static const String verifyOtp = '$apiPrefix/users/auth/verify_otp/';
  // Password Reset Endpoints (Code-based - 6 digits)
  static const String sendPasswordResetCode = '$apiPrefix/users/auth/send_password_reset_code/';
  static const String verifyPasswordResetCode = '$apiPrefix/users/auth/verify_password_reset_code/';
  static const String resetPasswordWithCode = '$apiPrefix/users/auth/reset_password_with_code/';

  // Email Verification Endpoints (Code-based - 6 digits)
  static const String sendVerificationCode = '$apiPrefix/users/auth/send_verification_code/';
  static const String verifyEmailCode = '$apiPrefix/users/auth/verify_email_code/';

  // Legacy endpoints (Token-based - for links)
  static const String forgotPassword = '$apiPrefix/users/auth/forgot_password/';
  static const String verifyResetToken = '$apiPrefix/users/auth/verify_reset_token/';
  static const String resetPassword = '$apiPrefix/users/auth/reset_password/';
  static const String verifyEmail = '$apiPrefix/users/auth/verify_email/';
  static const String resendVerificationLink = '$apiPrefix/users/auth/resend_verification_link/';

  // Client Profile Endpoints
  static const String clientProfile = '$apiPrefix/users/client-profile/';
  static const String updateClientInfo = '$apiPrefix/users/client-profile/update_info/';
  static const String updateClientProfile = '$apiPrefix/users/client-profile/update_profile/';
  static const String addresses = '$apiPrefix/users/client-profile/addresses/';
  static const String addAddress = '$apiPrefix/users/client-profile/add_address/';

  // Provider Profile Endpoints
  static const String providerProfile = '$apiPrefix/users/provider-profile/';
  static const String updateProviderProfile = '$apiPrefix/users/provider-profile/update_profile/';
  static const String providerAddresses = '$apiPrefix/users/provider-profile/addresses/';
  static const String addProviderAddress = '$apiPrefix/users/provider-profile/add_address/';
  static String setProviderDefaultAddress(int id) => '$apiPrefix/users/provider-profile/$id/set_default/';
  static String deleteProviderAddress(int id) => '$apiPrefix/users/provider-profile/$id/delete_address/';
  static const String publicProviders = '$apiPrefix/users/providers/'; // Public list of verified providers
  static String publicProviderDetail(int id) => '$apiPrefix/users/providers/$id/'; // Single provider detail

  // Providers List Endpoint
  static const String providers = '$apiPrefix/users/providers/';
  static const String featuredProviders = '$apiPrefix/users/providers/'; // العاملات المميزات
  static String providerDetail(int id) => '$apiPrefix/users/providers/$id/';
  static const String providerCompletedServices = '$apiPrefix/users/provider-profile/completed_services/';
  static String providerStats(int id) => '$apiPrefix/users/providers/$id/stats/';

  // Services Endpoints
  static const String categories = '$apiPrefix/services/categories/';
  static String categoryDetail(int id) => '$apiPrefix/services/categories/$id/';
  static const String services = '$apiPrefix/services/';
  static String serviceDetail(int id) => '$apiPrefix/services/$id/';

  // Booking Request Endpoints
  static const String bookingRequests = '$apiPrefix/services/booking-requests/';
  static String bookingRequestDetail(int id) => '$apiPrefix/services/booking-requests/$id/';
  static const String createBookingRequest = '$apiPrefix/services/booking-requests/create/';
  static String updateBookingRequest(int id) => '$apiPrefix/services/booking-requests/$id/update/';
  static String cancelBookingRequest(int id) => '$apiPrefix/services/booking-requests/$id/cancel/';

  // Worker Offer Endpoints
  static const String workerOffers = '$apiPrefix/services/worker-offers/';
  static String workerOfferDetail(int id) => '$apiPrefix/services/worker-offers/$id/';
  static const String createWorkerOffer = '$apiPrefix/services/worker-offers/create/';
  static String updateWorkerOffer(int id) => '$apiPrefix/services/worker-offers/$id/update/';
  static String acceptWorkerOffer(int id) => '$apiPrefix/services/worker-offers/$id/accept/';
  static String withdrawWorkerOffer(int id) => '$apiPrefix/services/worker-offers/$id/withdraw/';

  // Bookings Endpoints
  static const String bookings = '$apiPrefix/services/booking-requests/';
  static String bookingDetail(int id) => '$apiPrefix/bookings/$id/';
  static const String createBooking = '$apiPrefix/bookings/create/';
  static String updateBookingNotes(int id) => '$apiPrefix/bookings/$id/notes/';
  static String cancelBooking(int id) => '$apiPrefix/bookings/$id/cancel/';
  static String startBooking(int id) => '$apiPrefix/bookings/$id/start/';
  static String completeBooking(int id) => '$apiPrefix/bookings/$id/complete/';
  static String confirmCompletion(int id) => '$apiPrefix/bookings/$id/confirm-completion/';
  static String bookingHistory(int id) => '$apiPrefix/bookings/$id/history/';

  // Reschedule Endpoints
  static const String reschedules = '$apiPrefix/bookings/reschedules/';
  static const String createReschedule = '$apiPrefix/bookings/reschedules/create/';
  static String approveReschedule(int id) => '$apiPrefix/bookings/reschedules/$id/approve/';
  static String rejectReschedule(int id) => '$apiPrefix/bookings/reschedules/$id/reject/';

  // Rating Endpoints
  static const String ratings = '$apiPrefix/bookings/ratings/';
  static const String createRating = '$apiPrefix/bookings/ratings/create/';
  static String providerRatings(int providerId) => '$apiPrefix/bookings/ratings/provider/$providerId/';
  static String clientRatings(int clientId) => '$apiPrefix/bookings/ratings/?rated_user=$clientId';
  static String createServiceRating(int serviceId) => '$apiPrefix/bookings/ratings/service/$serviceId/';

  // Complaint Endpoints
  static const String complaints = '$apiPrefix/bookings/complaints/';
  static String complaintDetail(int id) => '$apiPrefix/bookings/complaints/$id/';
  static const String createComplaint = '$apiPrefix/bookings/complaints/create/';
  static String resolveComplaint(int id) => '$apiPrefix/bookings/complaints/$id/resolve/';

  // Notification Endpoints
  static const String notifications = '$apiPrefix/bookings/notifications/';
  static String markNotificationAsRead(int id) => '$apiPrefix/bookings/notifications/$id/read/';
  static const String markAllNotificationsAsRead = '$apiPrefix/bookings/notifications/read-all/';

  // Chat Endpoints
  static const String chatConversations = '$apiPrefix/chat/conversations/';
  static const String chatMessages = '$apiPrefix/chat/messages/';
  static String chatConversationDetail(int id) => '$apiPrefix/chat/conversations/$id/';
  static String chatConversationByBooking(int bookingId) => '$apiPrefix/chat/conversations/by_booking/$bookingId/';
  static String markMessageRead(int id) => '$apiPrefix/chat/messages/$id/mark_read/';
  static const String markConversationRead = '$apiPrefix/chat/messages/mark_conversation_read/';

  // WebSocket Chat Endpoint
  static String chatWebSocket(int conversationId) => '$wsUrl/ws/chat/$conversationId/';

  // Admin Endpoints
  static const String adminProviders = '$apiPrefix/users/admin/providers/'; // List providers by status
  static const String adminStats = '$apiPrefix/users/admin/providers/stats/'; // Dashboard statistics
  static String adminApproveProvider(int userId) => '$apiPrefix/users/admin/providers/$userId/approve/'; // Approve provider
  static String adminRejectProvider(int userId) => '$apiPrefix/users/admin/providers/$userId/reject/'; // Reject provider
  static String adminToggleProviderActive(int userId) => '$apiPrefix/users/admin/providers/$userId/toggle_active/'; // Toggle active status

  // Admin - Service Category Management
  static const String adminCategories = '$apiPrefix/services/admin/categories/'; // List all categories (including inactive) and create new ones
  static String adminCategoryDetail(int id) => '$apiPrefix/services/admin/categories/$id/'; // Get, update or delete a specific category

  // Admin - Service Management
  static const String adminServices = '$apiPrefix/services/admin/services/'; // List all services (including inactive) and create new ones
  static String adminServiceDetail(int id) => '$apiPrefix/services/admin/services/$id/'; // Get, update or delete a specific service

  // Admin - Booking Management
  static const String adminBookings = '$apiPrefix/bookings/admin/all/'; // List all bookings with advanced filters
  static String adminBookingDetail(int id) => '$apiPrefix/bookings/admin/$id/'; // Get detailed booking info
  static const String adminBookingStats = '$apiPrefix/bookings/admin/stats/'; // Get booking statistics
  static String adminCancelBooking(int id) => '$apiPrefix/bookings/admin/$id/cancel/'; // Cancel booking (no restrictions)

  // Admin - Chat Management
  static const String adminConversations = '$apiPrefix/chat/admin/conversations/'; // List all conversations
  static String adminConversationDetail(int id) => '$apiPrefix/chat/admin/conversations/$id/'; // Get conversation messages

  // Admin - Ratings Management
  static const String adminRatings = '$apiPrefix/bookings/admin/ratings/'; // List all ratings
  static String adminRatingDetail(int id) => '$apiPrefix/bookings/admin/ratings/$id/'; // Get rating details
  static String adminDeleteRating(int id) => '$apiPrefix/bookings/admin/ratings/$id/delete/'; // Delete rating

  // Admin - Complaints Management
  static const String adminComplaints = '$apiPrefix/bookings/admin/complaints/'; // List all complaints
  static String adminComplaintDetail(int id) => '$apiPrefix/bookings/admin/complaints/$id/'; // Get complaint details
  static String adminStartReviewComplaint(int id) => '$apiPrefix/bookings/admin/complaints/$id/start_review/'; // Start reviewing complaint
  static String adminResolveComplaint(int id) => '$apiPrefix/bookings/admin/complaints/$id/resolve/'; // Resolve complaint
  static String adminComplaintByBooking(int bookingId) => '$apiPrefix/bookings/admin/complaints/by-booking/$bookingId/'; // Get complaint by booking ID

  // Payment Endpoints
  static const String paymentsBase = '$apiPrefix/payments';

  // PaySky Payment Endpoints
  static const String payskyCreateSession = '$paymentsBase/paysky/create-session/';
  static String payskyPaymentStatus(String transactionRef) => '$paymentsBase/paysky/status/$transactionRef/';
  static const String payskySuccessfulPayments = '$paymentsBase/paysky/successful-payments/';
  static const String payskyMarkCompleted = '$paymentsBase/paysky/mark-completed/';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Token $token',
  };
}
