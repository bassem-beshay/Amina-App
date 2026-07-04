import 'api_client.dart';
import '../config/api_config.dart';

/// خدمة إدارة الحجوزات للأدمن
class AdminService {
  /// جلب كل الحجوزات مع فلترة متقدمة
  ///
  /// Parameters:
  /// - [status]: فلترة بالحالة (CONFIRMED, IN_PROGRESS, COMPLETED, CANCELED)
  /// - [clientId]: فلترة بالعميل
  /// - [providerId]: فلترة بالبروفايدر
  /// - [dateFrom]: من تاريخ (YYYY-MM-DD)
  /// - [dateTo]: إلى تاريخ (YYYY-MM-DD)
  /// - [city]: المدينة
  /// - [search]: البحث في اسم الخدمة أو العميل أو البروفايدر
  static Future<ApiResponse> getAllBookings({
    String? status,
    int? clientId,
    int? providerId,
    String? dateFrom,
    String? dateTo,
    String? city,
    String? search,
  }) async {
    try {
      // بناء Query Parameters
      Map<String, String> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (clientId != null) {
        queryParams['client_id'] = clientId.toString();
      }
      if (providerId != null) {
        queryParams['provider_id'] = providerId.toString();
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = dateTo;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      String url = ApiConfig.adminBookings;

      // إضافة Query Parameters إلى URL
      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب الحجوزات: $e',
        statusCode: 0,
      );
    }
  }

  /// جلب تفاصيل حجز معين (Admin)
  ///
  /// Parameters:
  /// - [bookingId]: معرف الحجز
  static Future<ApiResponse> getBookingDetails(int bookingId) async {
    try {
      final url = ApiConfig.adminBookingDetail(bookingId);

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب تفاصيل الحجز: $e',
        statusCode: 0,
      );
    }
  }

  /// جلب إحصائيات الحجوزات
  ///
  /// Parameters:
  /// - [dateFrom]: من تاريخ (YYYY-MM-DD)
  /// - [dateTo]: إلى تاريخ (YYYY-MM-DD)
  static Future<ApiResponse> getBookingStats({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = dateTo;
      }

      String url = ApiConfig.adminBookingStats;

      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب الإحصائيات: $e',
        statusCode: 0,
      );
    }
  }

  /// إلغاء حجز (Admin - بدون قيود)
  ///
  /// Parameters:
  /// - [bookingId]: معرف الحجز
  /// - [reason]: سبب الإلغاء
  static Future<ApiResponse> cancelBooking(int bookingId, String reason) async {
    try {
      final url = ApiConfig.adminCancelBooking(bookingId);

      final response = await ApiClient.post(
        url,
        body: {'reason': reason},
        needsAuth: true,
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في إلغاء الحجز: $e',
        statusCode: 0,
      );
    }
  }

  // ========================================
  // 💬 إدارة المحادثات (Conversations)
  // ========================================

  /// جلب جميع المحادثات
  ///
  /// Parameters:
  /// - [clientId]: فلترة بالعميل
  /// - [providerId]: فلترة بالمزود
  /// - [bookingId]: فلترة بالحجز
  static Future<ApiResponse> getAllConversations({
    int? clientId,
    int? providerId,
    int? bookingId,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (clientId != null) {
        queryParams['client_id'] = clientId.toString();
      }
      if (providerId != null) {
        queryParams['provider_id'] = providerId.toString();
      }
      if (bookingId != null) {
        queryParams['booking_id'] = bookingId.toString();
      }

      String url = ApiConfig.adminConversations;

      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب المحادثات: $e',
        statusCode: 0,
      );
    }
  }

  /// جلب رسائل محادثة معينة
  ///
  /// Parameters:
  /// - [conversationId]: معرف المحادثة
  static Future<ApiResponse> getConversationMessages(int conversationId) async {
    try {
      final url = ApiConfig.adminConversationDetail(conversationId);

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب الرسائل: $e',
        statusCode: 0,
      );
    }
  }

  // ========================================
  // ⭐ إدارة التقييمات (Ratings)
  // ========================================

  /// جلب جميع التقييمات
  ///
  /// Parameters:
  /// - [clientId]: فلترة بالعميل
  /// - [providerId]: فلترة بالمزود
  /// - [bookingId]: فلترة بالحجز
  /// - [minRating]: الحد الأدنى للتقييم (1-5)
  /// - [maxRating]: الحد الأقصى للتقييم (1-5)
  static Future<ApiResponse> getAllRatings({
    int? clientId,
    int? providerId,
    int? bookingId,
    int? minRating,
    int? maxRating,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (clientId != null) {
        queryParams['client_id'] = clientId.toString();
      }
      if (providerId != null) {
        queryParams['provider_id'] = providerId.toString();
      }
      if (bookingId != null) {
        queryParams['booking_id'] = bookingId.toString();
      }
      if (minRating != null) {
        queryParams['min_rating'] = minRating.toString();
      }
      if (maxRating != null) {
        queryParams['max_rating'] = maxRating.toString();
      }

      String url = ApiConfig.adminRatings;

      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب التقييمات: $e',
        statusCode: 0,
      );
    }
  }

  /// حذف تقييم
  ///
  /// Parameters:
  /// - [ratingId]: معرف التقييم
  static Future<ApiResponse> deleteRating(int ratingId) async {
    try {
      final url = ApiConfig.adminDeleteRating(ratingId);

      final response = await ApiClient.delete(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في حذف التقييم: $e',
        statusCode: 0,
      );
    }
  }

  // ========================================
  // 📢 إدارة الشكاوي (Complaints)
  // ========================================

  /// جلب جميع الشكاوي
  ///
  /// Parameters:
  /// - [status]: فلترة بالحالة (PENDING, RESOLVED)
  /// - [clientId]: فلترة بالعميل
  /// - [providerId]: فلترة بالمزود
  /// - [bookingId]: فلترة بالحجز
  static Future<ApiResponse> getAllComplaints({
    String? status,
    int? clientId,
    int? providerId,
    int? bookingId,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (clientId != null) {
        queryParams['client_id'] = clientId.toString();
      }
      if (providerId != null) {
        queryParams['provider_id'] = providerId.toString();
      }
      if (bookingId != null) {
        queryParams['booking_id'] = bookingId.toString();
      }

      String url = ApiConfig.adminComplaints;

      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب الشكاوي: $e',
        statusCode: 0,
      );
    }
  }

  /// جلب تفاصيل شكوى معينة
  ///
  /// Parameters:
  /// - [complaintId]: معرف الشكوى
  static Future<ApiResponse> getComplaintDetails(int complaintId) async {
    try {
      final url = ApiConfig.adminComplaintDetail(complaintId);

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب تفاصيل الشكوى: $e',
        statusCode: 0,
      );
    }
  }

  /// بدء مراجعة شكوى (تغيير الحالة من PENDING إلى IN_REVIEW)
  ///
  /// Parameters:
  /// - [complaintId]: معرف الشكوى
  static Future<ApiResponse> startReviewComplaint(int complaintId) async {
    try {
      final url = ApiConfig.adminStartReviewComplaint(complaintId);

      final response = await ApiClient.post(
        url,
        body: {},
        needsAuth: true,
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في بدء المراجعة: $e',
        statusCode: 0,
        rawResponse: null,
      );
    }
  }

  /// جلب الشكوى المرتبطة بحجز معين
  ///
  /// Parameters:
  /// - [bookingId]: معرف الحجز
  static Future<ApiResponse> getComplaintByBooking(int bookingId) async {
    try {
      final url = ApiConfig.adminComplaintByBooking(bookingId);

      final response = await ApiClient.get(url, needsAuth: true);

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في جلب الشكوى: $e',
        statusCode: 0,
      );
    }
  }

  /// حل شكوى
  ///
  /// Parameters:
  /// - [complaintId]: معرف الشكوى
  /// - [resolution]: الحل المتخذ
  static Future<ApiResponse> resolveComplaint(
      int complaintId, String resolution) async {
    try {
      final url = ApiConfig.adminResolveComplaint(complaintId);

      final response = await ApiClient.post(
        url,
        body: {'resolution': resolution},
        needsAuth: true,
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في حل الشكوى: $e',
        statusCode: 0,
      );
    }
  }

  /// الحصول على المحادثة حسب معرف الحجز
  ///
  /// Parameters:
  /// - [bookingId]: معرف الحجز
  static Future<ApiResponse> getConversationByBooking(int bookingId) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/chat/conversations/by-booking/$bookingId/';

      final response = await ApiClient.get(
        url,
        needsAuth: true,
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'خطأ في تحميل المحادثة: $e',
        statusCode: 0,
        rawResponse: null,
      );
    }
  }
}
