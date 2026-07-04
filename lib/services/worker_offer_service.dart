import '../models/worker_offer_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class WorkerOfferService {
  // Create a worker offer
  static Future<WorkerOfferResult> createOffer({
    required int bookingRequestId,
    required String priceAction, // 'accept' or 'counter'
    required double offeredPrice,
    String? message,
    int? estimatedDuration,
  }) async {
    try {

      final response = await ApiClient.post<WorkerOffer>(
        ApiConfig.createWorkerOffer,
        needsAuth: true,
        body: {
          'booking_request': bookingRequestId,
          'price_action': priceAction,
          'offered_price': offeredPrice,
          if (message != null && message.isNotEmpty) 'message': message,
          if (estimatedDuration != null) 'estimated_duration': estimatedDuration,
        },
        fromJson: (json) {

          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return WorkerOffer.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              // If no 'data' key, assume the whole json is the offer
              return WorkerOffer.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return WorkerOfferResult(
          success: true,
          message: response.message ?? 'تم إرسال عرضك بنجاح',
          offer: response.data,
        );
      } else {
        return WorkerOfferResult(
          success: false,
          error: response.error ?? 'فشل إرسال العرض',
        );
      }
    } catch (e) {
      return WorkerOfferResult(
        success: false,
        error: 'خطأ في الاتصال: ${e.toString()}',
      );
    }
  }

  // Get single worker offer details by ID
  static Future<WorkerOffer?> getOfferById(int offerId) async {
    try {

      final response = await ApiClient.get<WorkerOffer>(
        ApiConfig.workerOfferDetail(offerId),
        needsAuth: true,
        fromJson: (json) {

          // Handle different response structures
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return WorkerOffer.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              return WorkerOffer.fromJson(json);
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

  // Get worker offers (for provider: their offers, for client: offers on their requests)
  static Future<List<WorkerOffer>> getOffers({
    int? bookingRequestId,
  }) async {
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

          // Handle different response structures
          List<dynamic> data;
          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              data = json['data'] as List;
            } else if (json.containsKey('results')) {
              data = json['results'] as List;
            } else {
              return <WorkerOffer>[];
            }
          } else if (json is List) {
            data = json;
          } else {
            return <WorkerOffer>[];
          }

          return data.map((item) => WorkerOffer.fromJson(item as Map<String, dynamic>)).toList();
        },
      );

      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // Withdraw an offer
  static Future<WorkerOfferResult> withdrawOffer(int offerId) async {
    try {

      final response = await ApiClient.post(
        ApiConfig.withdrawWorkerOffer(offerId),
        needsAuth: true,
      );

      if (response.success) {
        return WorkerOfferResult(
          success: true,
          message: response.message ?? 'تم سحب العرض بنجاح',
        );
      } else {
        return WorkerOfferResult(
          success: false,
          error: response.error ?? 'فشل سحب العرض',
        );
      }
    } catch (e) {
      return WorkerOfferResult(
        success: false,
        error: 'خطأ في الاتصال: ${e.toString()}',
      );
    }
  }

  // Accept an offer (for client)
  static Future<WorkerOfferResult> acceptOffer(int offerId) async {
    try {

      final response = await ApiClient.post<WorkerOffer>(
        ApiConfig.acceptWorkerOffer(offerId),
        needsAuth: true,
        fromJson: (json) {

          if (json is Map<String, dynamic>) {
            if (json.containsKey('data') && json['data'] != null) {
              return WorkerOffer.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              return WorkerOffer.fromJson(json);
            }
          }
          throw Exception('Invalid response structure');
        },
      );

      if (response.success) {
        return WorkerOfferResult(
          success: true,
          message: response.message ?? 'تم قبول العرض بنجاح',
          offer: response.data,
        );
      } else {
        return WorkerOfferResult(
          success: false,
          error: response.error ?? 'فشل قبول العرض',
        );
      }
    } catch (e) {
      return WorkerOfferResult(
        success: false,
        error: 'خطأ في الاتصال: ${e.toString()}',
      );
    }
  }
}

class WorkerOfferResult {
  final bool success;
  final String? message;
  final String? error;
  final WorkerOffer? offer;

  WorkerOfferResult({
    required this.success,
    this.message,
    this.error,
    this.offer,
  });
}
