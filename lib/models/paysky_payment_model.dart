/// PaySky Payment Models
/// Data models for PaySky payment integration

class PaySkySessionRequest {
  final int bookingId;
  final String amount;
  final String currency; // Always 'EGP' (Egyptian Pound)
  final String environment; // 'TESTING' or 'PRODUCTION'

  PaySkySessionRequest({
    required this.bookingId,
    required this.amount,
    this.currency = 'EGP', // Default currency is Egyptian Pound
    this.environment = 'PRODUCTION', // Force PRODUCTION only
  });

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'amount': amount,
        'currency': currency,
        'environment': environment,
      };
}

class PaySkySessionResponse {
  final bool success;
  final String transactionReference;
  final String paymentUrl; // Legacy redirect URL (fallback)
  final String? lightboxUrl; // LightBox JavaScript URL
  final String? paymentPage; // Payment page base URL
  final String merchantId;
  final String terminalId;
  final String amount;
  final String currencyCode;
  final String currencyName;
  final String secureHash;
  final String datetimeLocal;
  final String environment; // 'TESTING' or 'PRODUCTION'
  final int bookingId;
  final String? error;

  PaySkySessionResponse({
    required this.success,
    required this.transactionReference,
    required this.paymentUrl,
    this.lightboxUrl,
    this.paymentPage,
    required this.merchantId,
    required this.terminalId,
    required this.amount,
    required this.currencyCode,
    required this.currencyName,
    required this.secureHash,
    required this.datetimeLocal,
    required this.environment,
    required this.bookingId,
    this.error,
  });

  factory PaySkySessionResponse.fromJson(Map<String, dynamic> json) {
    return PaySkySessionResponse(
      success: json['success'] ?? false,
      transactionReference: json['transaction_reference'] ?? '',
      paymentUrl: json['payment_url'] ?? '',
      lightboxUrl: json['lightbox_url'],
      paymentPage: json['payment_page'],
      merchantId: json['merchant_id'] ?? '',
      terminalId: json['terminal_id'] ?? '',
      amount: json['amount'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      currencyName: json['currency_name'] ?? '',
      secureHash: json['secure_hash'] ?? '',
      datetimeLocal: json['datetime_local'] ?? '',
      environment: json['environment'] ?? 'PRODUCTION',
      bookingId: json['booking_id'] ?? 0,
      error: json['error'],
    );
  }

  factory PaySkySessionResponse.error(String errorMessage) {
    return PaySkySessionResponse(
      success: false,
      transactionReference: '',
      paymentUrl: '',
      lightboxUrl: null,
      paymentPage: null,
      merchantId: '',
      terminalId: '',
      amount: '',
      currencyCode: '',
      currencyName: '',
      secureHash: '',
      datetimeLocal: '',
      environment: 'PRODUCTION',
      bookingId: 0,
      error: errorMessage,
    );
  }

  bool get isTesting => environment == 'TESTING';
  bool get isProduction => environment == 'PRODUCTION';

  /// Get the correct payment URL for LightBox integration
  /// Returns the HTML page URL that loads the LightBox
  String getPaymentFormUrl(String baseUrl) {
    return '$baseUrl/api/payments/paysky/pay/$transactionReference/';
  }
}

class PaySkyPaymentResult {
  final bool success;
  final String transactionReference;
  final String? systemReference;
  final String? networkReference;
  final String? actionCode;
  final String? message;

  PaySkyPaymentResult({
    required this.success,
    required this.transactionReference,
    this.systemReference,
    this.networkReference,
    this.actionCode,
    this.message,
  });

  factory PaySkyPaymentResult.fromCallback(Map<String, dynamic> data) {
    return PaySkyPaymentResult(
      success: data['action_code'] == '000',
      transactionReference: data['transaction_reference'] ?? '',
      systemReference: data['system_reference'],
      networkReference: data['network_reference'],
      actionCode: data['action_code'],
      message: data['message'],
    );
  }

  factory PaySkyPaymentResult.success({
    required String transactionReference,
    String? systemReference,
    String? networkReference,
  }) {
    return PaySkyPaymentResult(
      success: true,
      transactionReference: transactionReference,
      systemReference: systemReference,
      networkReference: networkReference,
      actionCode: '000',
      message: 'Payment completed successfully',
    );
  }

  factory PaySkyPaymentResult.failure({
    required String transactionReference,
    String? message,
  }) {
    return PaySkyPaymentResult(
      success: false,
      transactionReference: transactionReference,
      message: message ?? 'Payment failed',
    );
  }

  bool get isSuccessful => success && actionCode == '000';
}

class PaySkyPaymentStatus {
  final bool success;
  final String transactionReference;
  final String status;
  final String amount;
  final String currencyCode;
  final String currencyName;
  final String? systemReference;
  final String? networkReference;
  final String? actionCode;
  final String? message;
  final String? paidThrough;
  final bool isSuccessful;
  final DateTime? createdAt;
  final DateTime? paymentCompletedAt;
  final int bookingId;
  final String? error;

  PaySkyPaymentStatus({
    required this.success,
    required this.transactionReference,
    required this.status,
    required this.amount,
    required this.currencyCode,
    required this.currencyName,
    this.systemReference,
    this.networkReference,
    this.actionCode,
    this.message,
    this.paidThrough,
    required this.isSuccessful,
    this.createdAt,
    this.paymentCompletedAt,
    required this.bookingId,
    this.error,
  });

  factory PaySkyPaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaySkyPaymentStatus(
      success: json['success'] ?? false,
      transactionReference: json['transaction_reference'] ?? '',
      status: json['status'] ?? '',
      amount: json['amount'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      currencyName: json['currency_name'] ?? '',
      systemReference: json['system_reference'],
      networkReference: json['network_reference'],
      actionCode: json['action_code'],
      message: json['message'],
      paidThrough: json['paid_through'],
      isSuccessful: json['is_successful'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      paymentCompletedAt: json['payment_completed_at'] != null
          ? DateTime.parse(json['payment_completed_at'])
          : null,
      bookingId: json['booking_id'] ?? 0,
      error: json['error'],
    );
  }

  bool get isPending => status == 'PENDING' || status == 'PAYMENT_PAGE_SHOWN' || status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}
