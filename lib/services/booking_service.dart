import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class BookingService {
  /// Update an open booking request. The endpoint is intentionally PATCH so
  /// callers can send only the fields changed on the edit screen.
  static Future<BookingRequestResult> updateBookingRequest(
    int id, {
    DateTime? bookingDate,
    String? bookingTime,
    int? durationHours,
    String? city,
    String? address,
    double? clientBudget,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (bookingDate != null) {
      body['booking_date'] =
          '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
    }
    if (bookingTime != null) body['booking_time'] = bookingTime;
    if (durationHours != null) body['duration_hours'] = durationHours;
    if (city != null) body['city'] = city;
    if (address != null) body['address'] = address;
    if (clientBudget != null) body['client_budget'] = clientBudget;
    if (notes != null) body['notes'] = notes;
    try {
      final response = await ApiClient.patch<BookingRequest>(
        ApiConfig.updateBookingRequest(id),
        needsAuth: true,
        body: body,
        fromJson: (json) => BookingRequest.fromJson(
            json is Map<String, dynamic> && json['data'] is Map<String, dynamic>
                ? json['data'] as Map<String, dynamic>
                : json as Map<String, dynamic>),
      );
      return BookingRequestResult(
          success: response.success,
          message: response.message,
          error: response.error,
          bookingRequest: response.data);
    } catch (e) {
      return BookingRequestResult(success: false, error: e.toString());
    }
  }

  static Future<BookingRequestResult> cancelBookingRequest(int id,
      {String? reason}) async {
    try {
      final response = await ApiClient.post<BookingRequest>(
        ApiConfig.cancelBookingRequest(id),
        needsAuth: true,
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
        fromJson: (json) => BookingRequest.fromJson(
            json is Map<String, dynamic> && json['data'] is Map<String, dynamic>
                ? json['data'] as Map<String, dynamic>
                : json as Map<String, dynamic>),
      );
      return BookingRequestResult(
          success: response.success,
          message: response.message,
          error: response.error,
          bookingRequest: response.data);
    } catch (e) {
      return BookingRequestResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResponse<List<BookingReschedule>>> getReschedules(
      {int? bookingId}) async {
    final response = await ApiClient.get<List<BookingReschedule>>(
      ApiConfig.reschedules,
      needsAuth: true,
      queryParams: {if (bookingId != null) 'booking': bookingId.toString()},
      fromJson: (json) {
        final list = json is List
            ? json
            : (json is Map && json['results'] is List
                ? json['results']
                : <dynamic>[]);
        return list
            .map((e) => BookingReschedule.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return response;
  }

  static Future<ApiResponse<BookingReschedule>> createReschedule(
      {required int bookingId,
      required DateTime date,
      required String time,
      required String reason}) async {
    return ApiClient.post<BookingReschedule>(
      ApiConfig.createReschedule,
      needsAuth: true,
      body: {
        'booking': bookingId,
        'new_date': date.toIso8601String().split('T').first,
        'new_time': time,
        'reason': reason
      },
      fromJson: (json) =>
          BookingReschedule.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<bool> approveReschedule(int id) async =>
      (await ApiClient.post(ApiConfig.approveReschedule(id), needsAuth: true))
          .success;
  static Future<bool> rejectReschedule(int id) async =>
      (await ApiClient.post(ApiConfig.rejectReschedule(id), needsAuth: true))
          .success;

  static Future<ApiResponse<List<Complaint>>> getComplaints() async {
    return ApiClient.get<List<Complaint>>(ApiConfig.complaints, needsAuth: true,
        fromJson: (json) {
      final list = json is List
          ? json
          : (json is Map && json['results'] is List
              ? json['results']
              : <dynamic>[]);
      return list
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<ApiResponse<Complaint>> getComplaint(int id) =>
      ApiClient.get<Complaint>(ApiConfig.complaintDetail(id),
          needsAuth: true,
          fromJson: (json) => Complaint.fromJson(json as Map<String, dynamic>));

  static Future<ApiResponse<Complaint>> createComplaint(
      {required int bookingId,
      required String title,
      required String description,
      int? againstId}) {
    return ApiClient.post<Complaint>(ApiConfig.createComplaint,
        needsAuth: true,
        body: {
          'booking': bookingId,
          'title': title,
          'description': description,
          if (againstId != null) 'against': againstId
        },
        fromJson: (json) => Complaint.fromJson(
            json is Map<String, dynamic> && json['data'] is Map<String, dynamic>
                ? json['data'] as Map<String, dynamic>
                : json as Map<String, dynamic>));
  }

  // Get all booking requests for current user
  static Future<List<BookingRequest>> getBookings({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await ApiClient.get<List<BookingRequest>>(
        ApiConfig.bookings,
        needsAuth: true,
        queryParams: queryParams,
        fromJson: (json) {
          // Handle different response structures
          List<dynamic> data;
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              data = json['data'] as List;
            } else if (json.containsKey('results')) {
              data = json['results'] as List;
            } else {
              // If no data or results key, return empty list
              return <BookingRequest>[];
            }
          } else if (json is List) {
            data = json;
          } else {
            return <BookingRequest>[];
          }

          return data
              .map((item) =>
                  BookingRequest.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Provider/company operational bookings (P19–P24).
  static Future<List<Booking>> getProviderBookings({String? status}) async {
    try {
      final response = await ApiClient.get<List<Booking>>(
        ApiConfig.providerBookings,
        needsAuth: true,
        queryParams: {if (status != null) 'status': status},
        fromJson: (json) {
          final data = json is Map<String, dynamic>
              ? (json['data'] ?? json['results'] ?? const [])
              : json;
          if (data is! List) return <Booking>[];
          return data
              .whereType<Map<String, dynamic>>()
              .map(Booking.fromJson)
              .toList();
        },
      );
      return response.data ?? const [];
    } catch (_) {
      return const [];
    }
  }

  // Create booking request from catalog service
  static Future<BookingRequestResult> createBookingRequest({
    required int serviceId,
    required int categoryId,
    required DateTime bookingDate,
    required String bookingTime,
    required int durationHours,
    required String city,
    required String address,
    required double clientBudget,
  }) async {
    try {
      // Format date as YYYY-MM-DD
      final dateStr =
          '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';

      final requestBody = {
        'request_type': 'catalog',
        'service': serviceId,
        'service_category': categoryId,
        'booking_date': dateStr,
        'booking_time': bookingTime,
        'duration_hours': durationHours,
        'city': city,
        'address': address,
        'client_budget': clientBudget,
      };

      final response = await ApiClient.post<BookingRequest>(
        ApiConfig.createBookingRequest,
        needsAuth: true,
        body: requestBody,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return BookingRequest.fromJson(
                  json['data'] as Map<String, dynamic>);
            } else {
              // If no 'data' key, assume the whole json is the booking request
              return BookingRequest.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return BookingRequestResult(
          success: true,
          message: response.message ?? 'تم إنشاء طلب الحجز بنجاح',
          bookingRequest: response.data,
        );
      } else {
        return BookingRequestResult(
          success: false,
          error: response.error ?? 'فشل إنشاء طلب الحجز',
        );
      }
    } catch (e) {
      // طباعة الخطأ الكامل للـ debug
      print('❌ Booking Request Error: $e');
      print('📋 Stack trace: ${StackTrace.current}');

      return BookingRequestResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Get single booking request details by ID
  static Future<BookingRequest?> getBookingRequestById(int id) async {
    try {
      final response = await ApiClient.get<BookingRequest>(
        ApiConfig.bookingRequestDetail(id),
        needsAuth: true,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return BookingRequest.fromJson(
                  json['data'] as Map<String, dynamic>);
            } else {
              return BookingRequest.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get booking details
  static Future<Booking?> getBookingDetails(int id) async {
    try {
      final response = await ApiClient.get<Booking>(
        ApiConfig.bookingDetail(id),
        needsAuth: true,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            // Check if there's a 'data' key
            if (json.containsKey('data') && json['data'] != null) {
              final bookingData = json['data'];
              return Booking.fromJson(bookingData as Map<String, dynamic>);
            } else {
              // Assume the whole json is the booking data
              return Booking.fromJson(json);
            }
          }

          throw Exception('Invalid response structure');
        },
      );

      if (response.success && response.data != null) {
        return response.data;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      rethrow; // Re-throw to let caller handle it
    }
  }

  // Create booking
  static Future<BookingResult> createBooking({
    required int bookingRequestId,
    required int acceptedOfferId,
  }) async {
    try {
      final response = await ApiClient.post<Booking>(
        ApiConfig.createBooking,
        needsAuth: true,
        body: {
          'booking_request_id': bookingRequestId,
          'accepted_offer_id': acceptedOfferId,
        },
        fromJson: (json) =>
            Booking.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم إنشاء الحجز بنجاح',
          booking: response.data,
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل إنشاء الحجز',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Cancel booking
  static Future<BookingResult> cancelBooking(int id, {String? reason}) async {
    try {
      final response = await ApiClient.post<Booking>(
        ApiConfig.cancelBooking(id),
        needsAuth: true,
        body: {'reason': reason},
        fromJson: (json) =>
            Booking.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم إلغاء الحجز بنجاح',
          booking: response.data,
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل إلغاء الحجز',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Start booking (provider)
  static Future<BookingResult> startBooking(int id) async {
    try {
      final response = await ApiClient.post<Booking>(
        ApiConfig.startBooking(id),
        needsAuth: true,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return Booking.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              return Booking.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم بدء الخدمة',
          booking: response.data,
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل بدء الخدمة',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Complete booking (provider)
  static Future<BookingResult> completeBooking(int id) async {
    try {
      final response = await ApiClient.post<Booking>(
        ApiConfig.completeBooking(id),
        needsAuth: true,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return Booking.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              return Booking.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم إتمام الخدمة بنجاح',
          booking: response.data,
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل إتمام الخدمة',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Confirm completion (client confirms that service is completed)
  static Future<BookingResult> confirmCompletion(int id) async {
    try {
      final response = await ApiClient.post<Booking>(
        ApiConfig.confirmCompletion(id),
        needsAuth: true,
        fromJson: (json) {
          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return Booking.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              return Booking.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم تأكيد إكمال الخدمة بنجاح',
          booking: response.data,
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل تأكيد إكمال الخدمة',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Create rating
  static Future<BookingResult> createRating({
    required int bookingId,
    required int rating,
    String? review,
  }) async {
    try {
      final response = await ApiClient.post<Rating>(
        ApiConfig.createRating,
        needsAuth: true,
        body: {
          'booking': bookingId,
          'rating': rating,
          'review': review,
        },
        fromJson: (json) =>
            Rating.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return BookingResult(
          success: true,
          message: response.message ?? 'تم إضافة التقييم بنجاح',
        );
      } else {
        return BookingResult(
          success: false,
          error: response.error ?? 'فشل إضافة التقييم',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Get notifications
  static Future<List<BookingNotification>> getNotifications(
      {bool? unreadOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (unreadOnly == true) queryParams['unread'] = 'true';

      final response = await ApiClient.get<List<BookingNotification>>(
        ApiConfig.notifications,
        needsAuth: true,
        queryParams: queryParams,
        fromJson: (json) {
          final data = json['data'] as List;
          return data
              .map((item) =>
                  BookingNotification.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.markNotificationAsRead(id),
        needsAuth: true,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await ApiClient.post(
        ApiConfig.markAllNotificationsAsRead,
        needsAuth: true,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }
}

class BookingResult {
  final bool success;
  final String? message;
  final String? error;
  final Booking? booking;

  BookingResult({
    required this.success,
    this.message,
    this.error,
    this.booking,
  });
}

class BookingRequestResult {
  final bool success;
  final String? message;
  final String? error;
  final BookingRequest? bookingRequest;

  BookingRequestResult({
    required this.success,
    this.message,
    this.error,
    this.bookingRequest,
  });
}
