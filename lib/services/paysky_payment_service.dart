/// PaySky Payment Service
/// Service for handling PaySky payment operations

import '../config/api_config.dart';
import '../models/paysky_payment_model.dart';
import 'api_client.dart';

class PaySkyPaymentService {
  /// Create PaySky payment session
  ///
  /// Creates a payment session on the backend and returns payment URL
  /// for WebView
  static Future<ApiResponse<PaySkySessionResponse>> createPaymentSession({
    required int bookingId,
    required String amount,
    String currency = 'EGP',
    String environment = 'PRODUCTION', // Backend يفرض PRODUCTION دائماً
  }) async {
    try {

      final request = PaySkySessionRequest(
        bookingId: bookingId,
        amount: amount,
        currency: currency,
        environment: environment, // Backend سيتجاهله ويستخدم PRODUCTION
      );

      final response = await ApiClient.post<PaySkySessionResponse>(
        ApiConfig.payskyCreateSession,
        needsAuth: true,
        body: request.toJson(),
        fromJson: (json) => PaySkySessionResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        return response;
      } else {
        return ApiResponse<PaySkySessionResponse>(
          success: false,
          error: response.error ?? 'Failed to create payment session',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      return ApiResponse<PaySkySessionResponse>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 500,
      );
    }
  }

  /// Get payment status
  ///
  /// Query the payment status from backend
  static Future<ApiResponse<PaySkyPaymentStatus>> getPaymentStatus(
    String transactionReference,
  ) async {
    try {

      final response = await ApiClient.get<PaySkyPaymentStatus>(
        ApiConfig.payskyPaymentStatus(transactionReference),
        needsAuth: true,
        fromJson: (json) => PaySkyPaymentStatus.fromJson(json),
      );

      if (response.success && response.data != null) {
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse<PaySkyPaymentStatus>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 500,
      );
    }
  }

  /// Verify payment completion
  ///
  /// After WebView closes, verify that payment was actually completed
  static Future<bool> verifyPaymentCompletion(
    String transactionReference,
  ) async {
    try {

      final statusResponse = await getPaymentStatus(transactionReference);

      if (statusResponse.success && statusResponse.data != null) {
        final status = statusResponse.data!;

        // Check if payment is successful
        if (status.isSuccessful && status.isCompleted) {
          return true;
        }

        // Check if still pending
        if (status.isPending) {
          // Wait and retry once
          await Future.delayed(const Duration(seconds: 2));

          final retryResponse = await getPaymentStatus(transactionReference);
          if (retryResponse.success &&
              retryResponse.data != null &&
              retryResponse.data!.isSuccessful) {
            return true;
          }
        }

        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Create and process payment (complete flow)
  ///
  /// High-level method that:
  /// 1. Creates payment session
  /// 2. Returns payment URL for WebView
  /// 3. Caller should open WebView
  /// 4. After WebView closes, caller should call verifyPaymentCompletion
  static Future<ApiResponse<PaySkySessionResponse>> initiatePayment({
    required int bookingId,
    required String amount,
    String currency = 'EGP',
    String environment = 'PRODUCTION', // Backend يفرض PRODUCTION دائماً
  }) async {

    return await createPaymentSession(
      bookingId: bookingId,
      amount: amount,
      currency: currency,
      environment: environment,
    );
  }

  /// Mark payment as completed
  ///
  /// Call this after successful payment to update booking status to PAYMENT_COMPLETED
  /// This enables the "Start Service" button for the provider
  static Future<ApiResponse<Map<String, dynamic>>> markPaymentCompleted({
    required String transactionReference,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        ApiConfig.payskyMarkCompleted,
        needsAuth: true,
        body: {
          'transaction_reference': transactionReference,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'خطأ في تحديث حالة الدفع: \u200F${e.toString()}\u200F',
        statusCode: 500,
      );
    }
  }
}
