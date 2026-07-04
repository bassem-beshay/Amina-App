class WorkerOffer {
  final int id;
  final int bookingRequestId;
  final int workerId;
  final String priceAction; // 'accept' or 'counter'
  final double offeredPrice;
  final String? message;
  final int? estimatedDuration;
  final String status; // 'pending', 'accepted', 'rejected', 'withdrawn'
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkerOffer({
    required this.id,
    required this.bookingRequestId,
    required this.workerId,
    required this.priceAction,
    required this.offeredPrice,
    this.message,
    this.estimatedDuration,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkerOffer.fromJson(Map<String, dynamic> json) {
    return WorkerOffer(
      id: json['id'] as int,
      bookingRequestId: json['booking_request'] as int,
      workerId: json['worker'] as int,
      priceAction: json['price_action'] as String,
      offeredPrice: double.parse(json['offered_price'].toString()),
      message: json['message'] as String?,
      estimatedDuration: json['estimated_duration'] as int?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_request': bookingRequestId,
      'worker': workerId,
      'price_action': priceAction,
      'offered_price': offeredPrice,
      'message': message,
      'estimated_duration': estimatedDuration,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'withdrawn':
        return 'تم السحب';
      default:
        return status;
    }
  }

  String get priceActionLabel {
    switch (priceAction) {
      case 'accept':
        return 'قبول سعر العميل';
      case 'counter':
        return 'اقتراح سعر آخر';
      default:
        return priceAction;
    }
  }
}
