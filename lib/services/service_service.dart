import '../models/service_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class ServiceService {
  // Get all categories
  static Future<List<ServiceCategory>> getCategories() async {
    try {
      final response = await ApiClient.get<List<ServiceCategory>>(
        ApiConfig.categories,
        fromJson: (json) {
          // json here is already the 'data' array from ApiClient._handleResponse
          if (json is List) {
            return json.map((item) => ServiceCategory.fromJson(item as Map<String, dynamic>)).toList();
          }
          // Fallback: if json is still the full response object
          final data = json['data'] as List;
          return data.map((item) => ServiceCategory.fromJson(item as Map<String, dynamic>)).toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get category details with services
  static Future<ServiceCategory?> getCategoryDetails(int id) async {
    try {
      final response = await ApiClient.get<ServiceCategory>(
        ApiConfig.categoryDetail(id),
        fromJson: (json) {
          final categoryData = json['data']['category'] as Map<String, dynamic>;
          return ServiceCategory.fromJson(categoryData);
        },
      );

      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Get all services
  static Future<List<Service>> getServices({
    int? categoryId,
    bool? isFeatured,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category'] = categoryId.toString();
      if (isFeatured == true) queryParams['is_featured'] = 'true';
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await ApiClient.get<List<Service>>(
        ApiConfig.services,
        queryParams: queryParams,
        fromJson: (json) {
          // json here is already the 'data' array from ApiClient._handleResponse
          try {
            if (json is List) {
              final services = <Service>[];
              for (var item in json) {
                try {
                  services.add(Service.fromJson(item as Map<String, dynamic>));
                } catch (e) {
                }
              }
              return services;
            }
            // Fallback: if json is still the full response object
            final data = json['data'] as List;
            return data.map((item) => Service.fromJson(item as Map<String, dynamic>)).toList();
          } catch (e) {
            return <Service>[];
          }
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get service details
  static Future<Service?> getServiceDetails(int id) async {
    try {
      final response = await ApiClient.get<Service>(
        ApiConfig.serviceDetail(id),
        fromJson: (json) => Service.fromJson(json as Map<String, dynamic>),
      );

      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Create booking request
  static Future<ServiceResult> createBookingRequest({
    required int serviceId,
    required String preferredDate,
    required String preferredTime,
    String? location,
    String? notes,
  }) async {
    try {
      final response = await ApiClient.post<BookingRequest>(
        ApiConfig.createBookingRequest,
        needsAuth: true,
        body: {
          'service': serviceId,
          'preferred_date': preferredDate,
          'preferred_time': preferredTime,
          'location': location,
          'notes': notes,
        },
        fromJson: (json) => BookingRequest.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return ServiceResult(
          success: true,
          message: response.message ?? 'تم إنشاء طلب الحجز بنجاح',
          bookingRequest: response.data,
        );
      } else {
        return ServiceResult(
          success: false,
          error: response.error ?? 'فشل إنشاء طلب الحجز',
        );
      }
    } catch (e) {
      return ServiceResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Get booking requests
  static Future<List<BookingRequest>> getBookingRequests() async {
    try {
      final response = await ApiClient.get<List<BookingRequest>>(
        ApiConfig.bookingRequests,
        needsAuth: true,
        fromJson: (json) {
          final data = json['data'] as List;
          return data.map((item) => BookingRequest.fromJson(item as Map<String, dynamic>)).toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get booking request details
  static Future<BookingRequest?> getBookingRequestDetails(int id) async {
    try {
      final response = await ApiClient.get<BookingRequest>(
        ApiConfig.bookingRequestDetail(id),
        needsAuth: true,
        fromJson: (json) => BookingRequest.fromJson(json['data'] as Map<String, dynamic>),
      );

      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Cancel booking request
  static Future<ServiceResult> cancelBookingRequest(int id) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.cancelBookingRequest(id),
        needsAuth: true,
      );

      if (response.success) {
        return ServiceResult(
          success: true,
          message: response.message ?? 'تم إلغاء الطلب بنجاح',
        );
      } else {
        return ServiceResult(
          success: false,
          error: response.error ?? 'فشل إلغاء الطلب',
        );
      }
    } catch (e) {
      return ServiceResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Get worker offers for a booking request
  static Future<List<WorkerOffer>> getWorkerOffers({int? bookingRequestId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bookingRequestId != null) {
        queryParams['booking_request'] = bookingRequestId.toString();
      }

      final response = await ApiClient.get<List<WorkerOffer>>(
        ApiConfig.workerOffers,
        needsAuth: true,
        queryParams: queryParams,
        fromJson: (json) {
          final data = json['data'] as List;
          return data.map((item) => WorkerOffer.fromJson(item as Map<String, dynamic>)).toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Accept worker offer
  static Future<ServiceResult> acceptWorkerOffer(int offerId) async {
    try {
      final response = await ApiClient.post<WorkerOffer>(
        ApiConfig.acceptWorkerOffer(offerId),
        needsAuth: true,
        fromJson: (json) => WorkerOffer.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return ServiceResult(
          success: true,
          message: response.message ?? 'تم قبول العرض بنجاح',
          workerOffer: response.data,
        );
      } else {
        return ServiceResult(
          success: false,
          error: response.error ?? 'فشل قبول العرض',
        );
      }
    } catch (e) {
      return ServiceResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }

  // Create worker offer (for providers)
  static Future<ServiceResult> createWorkerOffer({
    required int bookingRequestId,
    required double offeredPrice,
    String? message,
  }) async {
    try {
      final response = await ApiClient.post<WorkerOffer>(
        ApiConfig.createWorkerOffer,
        needsAuth: true,
        body: {
          'booking_request': bookingRequestId,
          'offered_price': offeredPrice,
          'message': message,
        },
        fromJson: (json) => WorkerOffer.fromJson(json['data'] as Map<String, dynamic>),
      );

      if (response.success) {
        return ServiceResult(
          success: true,
          message: response.message ?? 'تم إنشاء العرض بنجاح',
          workerOffer: response.data,
        );
      } else {
        return ServiceResult(
          success: false,
          error: response.error ?? 'فشل إنشاء العرض',
        );
      }
    } catch (e) {
      return ServiceResult(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
      );
    }
  }
}

class ServiceResult {
  final bool success;
  final String? message;
  final String? error;
  final BookingRequest? bookingRequest;
  final WorkerOffer? workerOffer;

  ServiceResult({
    required this.success,
    this.message,
    this.error,
    this.bookingRequest,
    this.workerOffer,
  });
}
