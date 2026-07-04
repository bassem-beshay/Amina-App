import '../config/api_config.dart';
import '../models/rating_model.dart';
import 'api_client.dart';

class RatingService {
  /// Create a new rating for a booking
  ///
  /// Parameters:
  /// - bookingId: The ID of the booking to rate
  /// - ratedUserId: The ID of the user being rated (provider or client)
  /// - rating: Rating value (1-5 stars)
  /// - comment: Optional comment/review text
  ///
  /// Returns: ApiResponse containing the created Rating or error message
  static Future<ApiResponse<Rating>> createRating({
    required int bookingId,
    required int ratedUserId,
    required int rating,
    String? comment,
  }) async {
    try {

      // Validate rating
      if (rating < 1 || rating > 5) {
        return ApiResponse<Rating>(
          success: false,
          error: 'التقييم يجب أن يكون بين 1 و 5 نجوم',
          statusCode: 400,
        );
      }

      // Create request
      final request = CreateRatingRequest(
        bookingId: bookingId,
        ratedUserId: ratedUserId,
        rating: rating,
        comment: comment,
      );

      final requestJson = request.toJson();

      // Send to API
      final response = await ApiClient.post<dynamic>(
        ApiConfig.createRating,
        needsAuth: true,
        body: requestJson,
      );


      if (response.success && response.rawResponse != null) {
        try {
          // Extract data from rawResponse
          final responseData = response.rawResponse!['data'] as Map<String, dynamic>?;

          if (responseData == null) {
            return ApiResponse<Rating>(
              success: false,
              error: 'لا توجد بيانات في الاستجابة',
              statusCode: response.statusCode,
            );
          }

          final ratingData = Rating.fromJson(responseData);
          return ApiResponse<Rating>(
            success: true,
            data: ratingData,
            statusCode: response.statusCode,
          );
        } catch (parseError) {
          return ApiResponse<Rating>(
            success: false,
            error: 'خطأ في معالجة البيانات: \u200F$parseError\u200F',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse<Rating>(
          success: false,
          error: response.error ?? 'فشل إرسال التقييم',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      return ApiResponse<Rating>(
        success: false,
        error: 'حدث خطأ أثناء إرسال التقييم: \u200F$e\u200F',
        statusCode: 0,
      );
    }
  }

  /// Get all ratings for a booking
  ///
  /// Returns: ApiResponse containing list of ratings or error message
  static Future<ApiResponse<List<Rating>>> getBookingRatings(int bookingId) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '${ApiConfig.ratings}?booking=$bookingId',
        needsAuth: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> ratingsJson = response.data is List
            ? response.data
            : (response.data['results'] ?? []);

        final ratings = ratingsJson
            .map((json) => Rating.fromJson(json))
            .toList();

        return ApiResponse<List<Rating>>(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Rating>>(
          success: false,
          error: response.error ?? 'فشل تحميل التقييمات',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Rating>>(
        success: false,
        error: 'حدث خطأ أثناء تحميل التقييمات',
        statusCode: 0,
      );
    }
  }

  /// Get ratings given by a specific user
  static Future<ApiResponse<List<Rating>>> getRatingsByUser(int userId) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '${ApiConfig.ratings}?rated_by=$userId',
        needsAuth: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> ratingsJson = response.data is List
            ? response.data
            : (response.data['results'] ?? []);

        final ratings = ratingsJson
            .map((json) => Rating.fromJson(json))
            .toList();

        return ApiResponse<List<Rating>>(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Rating>>(
          success: false,
          error: response.error ?? 'فشل تحميل التقييمات',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Rating>>(
        success: false,
        error: 'حدث خطأ أثناء تحميل التقييمات',
        statusCode: 0,
      );
    }
  }

  /// Get ratings received by a specific user (their overall rating)
  static Future<ApiResponse<List<Rating>>> getRatingsForUser(int userId) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '${ApiConfig.ratings}?rated_user=$userId',
        needsAuth: true,
      );

      if (response.success && response.data != null) {
        final List<dynamic> ratingsJson = response.data is List
            ? response.data
            : (response.data['results'] ?? []);

        final ratings = ratingsJson
            .map((json) => Rating.fromJson(json))
            .toList();

        return ApiResponse<List<Rating>>(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Rating>>(
          success: false,
          error: response.error ?? 'فشل تحميل التقييمات',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Rating>>(
        success: false,
        error: 'حدث خطأ أثناء تحميل التقييمات',
        statusCode: 0,
      );
    }
  }

  /// Get ratings for a specific provider using the correct endpoint
  /// GET /api/bookings/ratings/provider/{provider_id}/
  static Future<ApiResponse<List<Rating>>> getProviderRatings(int providerId) async {
    try {
      final endpoint = ApiConfig.providerRatings(providerId);

      final response = await ApiClient.get<dynamic>(
        endpoint,
        needsAuth: true,
      );


      if (response.success && response.rawResponse != null) {
        final responseData = response.rawResponse;
        final List<dynamic> ratingsJson = responseData is List
            ? responseData
            : (responseData['data'] ?? responseData['results'] ?? responseData['ratings'] ?? []);


        final ratings = ratingsJson
            .map((json) => Rating.fromJson(json as Map<String, dynamic>))
            .toList();


        return ApiResponse<List<Rating>>(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Rating>>(
          success: false,
          error: response.error ?? 'فشل تحميل التقييمات',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      return ApiResponse<List<Rating>>(
        success: false,
        error: 'حدث خطأ أثناء تحميل التقييمات: \u200F$e\u200F',
        statusCode: 0,
      );
    }
  }

  /// Get ratings for a specific client (ratings received by client from providers)
  /// GET /api/bookings/ratings/?received=true&user_id={client_id}
  static Future<ApiResponse<List<Rating>>> getClientRatings(int clientId) async {
    try {
      final endpoint = ApiConfig.clientRatings(clientId);

      final response = await ApiClient.get<dynamic>(
        endpoint,
        needsAuth: true,
      );


      if (response.success && response.rawResponse != null) {
        final responseData = response.rawResponse;
        final List<dynamic> ratingsJson = responseData is List
            ? responseData
            : (responseData['data'] ?? responseData['results'] ?? responseData['ratings'] ?? []);


        // Print first rating for debugging
        if (ratingsJson.isNotEmpty) {
        }

        final ratings = ratingsJson
            .map((json) => Rating.fromJson(json as Map<String, dynamic>))
            .toList();


        return ApiResponse<List<Rating>>(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Rating>>(
          success: false,
          error: response.error ?? 'فشل تحميل التقييمات',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      return ApiResponse<List<Rating>>(
        success: false,
        error: 'حدث خطأ أثناء تحميل التقييمات: \u200F$e\u200F',
        statusCode: 0,
      );
    }
  }
}
