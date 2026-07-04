class Booking {
  final int id;
  final int clientId;
  final int providerId;
  final int? serviceId; // Can be null for custom service requests
  final DateTime bookingDate;
  final String bookingTime;
  final String location;
  final double agreedPrice;
  final String status; // CONFIRMED, IN_PROGRESS, COMPLETED, CANCELED
  final String? clientNotes;
  final String? providerNotes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;
  final String? cancelReason;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.providerId,
    this.serviceId, // Made optional
    required this.bookingDate,
    required this.bookingTime,
    required this.location,
    required this.agreedPrice,
    required this.status,
    this.clientNotes,
    this.providerNotes,
    this.startedAt,
    this.completedAt,
    this.canceledAt,
    this.cancelReason,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse price from String or num
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Booking(
      id: json['id'] as int,
      clientId: json['client'] as int,
      providerId: json['provider'] as int,
      serviceId: json['service'] as int?, // Can be null
      bookingDate: DateTime.parse(json['booking_date'] as String),
      bookingTime: json['booking_time'] as String,
      // Django uses 'address' but we call it 'location' in Flutter
      location: json['address'] as String,
      // Django uses 'final_price' but we call it 'agreedPrice' in Flutter
      // Parse safely from both String and num
      agreedPrice: parsePrice(json['final_price']),
      status: json['status'] as String,
      clientNotes: json['client_notes'] as String?,
      providerNotes: json['provider_notes'] as String?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      canceledAt: json['canceled_at'] != null ? DateTime.parse(json['canceled_at'] as String) : null,
      cancelReason: json['cancel_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': clientId,
      'provider': providerId,
      'service': serviceId,
      'booking_date': bookingDate.toIso8601String(),
      'booking_time': bookingTime,
      'location': location,
      'agreed_price': agreedPrice,
      'status': status,
      'client_notes': clientNotes,
      'provider_notes': providerNotes,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'canceled_at': canceledAt?.toIso8601String(),
      'cancel_reason': cancelReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'CONFIRMED':
        return 'مؤكد';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELED':
        return 'ملغي';
      default:
        return status;
    }
  }
}

class BookingReschedule {
  final int id;
  final int bookingId;
  final int requestedById;
  final DateTime newDate;
  final String newTime;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime createdAt;

  BookingReschedule({
    required this.id,
    required this.bookingId,
    required this.requestedById,
    required this.newDate,
    required this.newTime,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory BookingReschedule.fromJson(Map<String, dynamic> json) {
    return BookingReschedule(
      id: json['id'] as int,
      bookingId: json['booking'] as int,
      requestedById: json['requested_by'] as int,
      newDate: DateTime.parse(json['new_date'] as String),
      newTime: json['new_time'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking': bookingId,
      'requested_by': requestedById,
      'new_date': newDate.toIso8601String(),
      'new_time': newTime,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'APPROVED':
        return 'تمت الموافقة';
      case 'REJECTED':
        return 'مرفوض';
      default:
        return status;
    }
  }
}

class Rating {
  final int id;
  final int bookingId;
  final int raterId;
  final int ratedId;
  final int rating; // 1-5
  final String? review;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.bookingId,
    required this.raterId,
    required this.ratedId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      bookingId: json['booking'] as int,
      raterId: json['rater'] as int,
      ratedId: json['rated'] as int,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking': bookingId,
      'rater': raterId,
      'rated': ratedId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Complaint {
  final int id;
  final int bookingId;
  final int complainantId;
  final int againstId;
  final String title;
  final String description;
  final String? evidence;
  final String status; // PENDING, UNDER_REVIEW, RESOLVED
  final String? resolution;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.bookingId,
    required this.complainantId,
    required this.againstId,
    required this.title,
    required this.description,
    this.evidence,
    required this.status,
    this.resolution,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      bookingId: json['booking'] as int,
      complainantId: json['complainant'] as int,
      againstId: json['against'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      evidence: json['evidence'] as String?,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking': bookingId,
      'complainant': complainantId,
      'against': againstId,
      'title': title,
      'description': description,
      'evidence': evidence,
      'status': status,
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'UNDER_REVIEW':
        return 'قيد المراجعة';
      case 'RESOLVED':
        return 'تم الحل';
      default:
        return status;
    }
  }
}

class BookingNotification {
  final int id;
  final int userId;
  final int? bookingId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  BookingNotification({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory BookingNotification.fromJson(Map<String, dynamic> json) {
    return BookingNotification(
      id: json['id'] as int,
      userId: json['user'] as int,
      bookingId: json['booking'] as int?,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'booking': bookingId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
