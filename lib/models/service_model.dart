class ServiceCategory {
  final int id;
  final String name;
  final String nameEn;
  final String? description;
  final String? icon;
  final String? image;
  final bool isActive;
  final int displayOrder;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    this.description,
    this.icon,
    this.image,
    required this.isActive,
    required this.displayOrder,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'description': description,
      'icon': icon,
      'image': image,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class Service {
  final int id;
  final ServiceCategory category;
  final String name;
  final String nameEn;
  final String description;
  final double basePrice;
  final String unit; // HOUR, DAY, TASK
  final int estimatedDuration;
  final String? image;
  final bool isActive;
  final bool isFeatured;
  final double averageRating;
  final int totalRatings;
  final DateTime? createdAt;

  Service({
    required this.id,
    required this.category,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.basePrice,
    required this.unit,
    required this.estimatedDuration,
    this.image,
    required this.isActive,
    required this.isFeatured,
    required this.averageRating,
    required this.totalRatings,
    this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // Helper function to parse number from dynamic (can be String or num)
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Handle category - can be object or just id
    ServiceCategory category;
    if (json['category'] is Map) {
      category = ServiceCategory.fromJson(json['category'] as Map<String, dynamic>);
    } else {
      // If category is just an id, create a minimal category object
      final categoryId = json['category'] as int;
      final categoryName = json['category_name'] as String? ?? 'Unknown';
      category = ServiceCategory(
        id: categoryId,
        name: categoryName,
        nameEn: categoryName,
        isActive: true,
        displayOrder: 0,
      );
    }

    return Service(
      id: json['id'] as int,
      category: category,
      name: json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String,
      description: json['description'] as String? ?? json['short_description'] as String? ?? '',
      basePrice: parseDouble(json['base_price'] ?? json['suggested_price']),
      unit: json['unit'] as String? ?? 'TASK',
      estimatedDuration: parseInt(json['estimated_duration'] ?? json['suggested_duration_hours']),
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      averageRating: parseDouble(json['average_rating']),
      totalRatings: parseInt(json['total_ratings'] ?? json['total_requests']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toJson(),
      'name': name,
      'name_en': nameEn,
      'description': description,
      'base_price': basePrice,
      'unit': unit,
      'estimated_duration': estimatedDuration,
      'image': image,
      'is_active': isActive,
      'is_featured': isFeatured,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get unitLabel {
    switch (unit) {
      case 'HOUR':
        return 'ساعة';
      case 'DAY':
        return 'يوم';
      case 'TASK':
        return 'مهمة';
      default:
        return unit;
    }
  }
}

class BookingRequest {
  final int id;
  final int serviceId;
  final int clientId;
  final DateTime preferredDate;
  final String preferredTime;
  final String? location;
  final String? notes;
  final String status; // pending, received_offers, accepted, cancelled
  final DateTime createdAt;

  BookingRequest({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.preferredDate,
    required this.preferredTime,
    this.location,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] as int,
      serviceId: json['service'] as int,
      clientId: json['client'] as int,
      preferredDate: DateTime.parse(json['preferred_date'] as String),
      preferredTime: json['preferred_time'] as String,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': serviceId,
      'client': clientId,
      'preferred_date': preferredDate.toIso8601String(),
      'preferred_time': preferredTime,
      'location': location,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'received_offers':
        return 'تم استلام عروض';
      case 'accepted':
        return 'تم القبول';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}

class WorkerOffer {
  final int id;
  final int bookingRequestId;
  final int workerId;
  final double offeredPrice;
  final String? message;
  final String status; // pending, accepted, rejected, withdrawn
  final DateTime createdAt;

  WorkerOffer({
    required this.id,
    required this.bookingRequestId,
    required this.workerId,
    required this.offeredPrice,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory WorkerOffer.fromJson(Map<String, dynamic> json) {
    return WorkerOffer(
      id: json['id'] as int,
      bookingRequestId: json['booking_request'] as int,
      workerId: json['worker'] as int,
      offeredPrice: (json['offered_price'] as num).toDouble(),
      message: json['message'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_request': bookingRequestId,
      'worker': workerId,
      'offered_price': offeredPrice,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
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
}
