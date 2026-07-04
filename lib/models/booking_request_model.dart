class BookingRequest {
  final int id;
  final int client;
  final ClientInfo? clientInfo;
  final String requestType; // catalog or custom
  final int? service; // service ID
  final String? serviceTitle;
  final String? serviceTitleEn; // English service title
  final String? serviceImage; // صورة الخدمة من الـ API
  final String? customServiceTitle; // for custom requests
  final String? customServiceDescription; // for custom requests
  final int? serviceCategory;
  final String? categoryName;
  final String? categoryNameEn; // English category name
  final DateTime bookingDate;
  final String bookingTime;
  final int durationHours;
  final String address; // required field from backend
  final String? city;
  final double? clientBudget;
  final String? notes;
  final String status; // pending, in_progress, completed, canceled
  final String statusDisplay;
  final int offersCount;
  final int viewsCount;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  BookingRequest({
    required this.id,
    required this.client,
    this.clientInfo,
    required this.requestType,
    this.service,
    this.serviceTitle,
    this.serviceTitleEn,
    this.serviceImage,
    this.customServiceTitle,
    this.customServiceDescription,
    this.serviceCategory,
    this.categoryName,
    this.categoryNameEn,
    required this.bookingDate,
    required this.bookingTime,
    required this.durationHours,
    required this.address,
    this.city,
    this.clientBudget,
    this.notes,
    required this.status,
    required this.statusDisplay,
    required this.offersCount,
    required this.viewsCount,
    required this.isExpired,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    // Note: Service images are now fetched separately via ServiceService.getServiceDetails()
    // The serviceImage field is kept for backward compatibility but may be null
    String? serviceImage;
    if (json.containsKey('service_image')) {
      serviceImage = json['service_image'] as String?;
    } else if (json.containsKey('service_details') && json['service_details'] is Map) {
      final serviceDetails = json['service_details'] as Map<String, dynamic>;
      serviceImage = serviceDetails['image'] as String?;
    } else if (json.containsKey('service') && json['service'] is Map) {
      final serviceData = json['service'] as Map<String, dynamic>;
      serviceImage = serviceData['image'] as String?;
    }

    return BookingRequest(
      id: json['id'] as int,
      client: json['client'] as int,
      clientInfo: json['client_info'] != null
          ? ClientInfo.fromJson(json['client_info'] as Map<String, dynamic>)
          : null,
      requestType: json['request_type'] as String? ?? 'catalog',
      service: json['service'] is int ? json['service'] as int : null,
      serviceTitle: json['service_title'] as String?,
      serviceTitleEn: json['service_title_en'] as String?,
      serviceImage: serviceImage,
      customServiceTitle: json['custom_service_title'] as String?,
      customServiceDescription: json['custom_service_description'] as String?,
      serviceCategory: json['service_category'] as int?,
      categoryName: json['category_name'] as String?,
      categoryNameEn: json['category_name_en'] as String?,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      bookingTime: json['booking_time'] as String,
      durationHours: (json['duration_hours'] as num?)?.toInt() ?? 1,
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      clientBudget: json['client_budget'] != null
          ? double.tryParse(json['client_budget'].toString())
          : null,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      statusDisplay: json['status_display'] as String? ?? 'قيد الانتظار',
      offersCount: (json['offers_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isExpired: json['is_expired'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELED':
        return 'ملغي';
      default:
        return statusDisplay;
    }
  }

  // Get location for display
  String get location => address;

  // Get service title based on locale
  String getLocalizedServiceTitle(String locale) {
    if (locale == 'en' && serviceTitleEn != null && serviceTitleEn!.isNotEmpty) {
      return serviceTitleEn!;
    }
    return serviceTitle ?? customServiceTitle ?? '';
  }

  // Get category name based on locale
  String getLocalizedCategoryName(String locale) {
    if (locale == 'en' && categoryNameEn != null && categoryNameEn!.isNotEmpty) {
      return categoryNameEn!;
    }
    return categoryName ?? '';
  }
}

class ClientInfo {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final String phoneNumber;
  final String? profilePicture;
  final String? profilePictureUrl;
  final double? rating; // Client rating
  final int? totalBookings; // Total completed bookings

  ClientInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    required this.phoneNumber,
    this.profilePicture,
    this.profilePictureUrl,
    this.rating,
    this.totalBookings,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    String? profilePicture;
    String? profilePictureUrl;

    if (json.containsKey('client_profile') && json['client_profile'] is Map) {
      final clientProfile = json['client_profile'] as Map<String, dynamic>;
      profilePicture = clientProfile['profile_picture'] as String?;
      profilePictureUrl = clientProfile['profile_picture_url'] as String?;
    }

    // Extract rating and total bookings from client_profile
    double? rating;
    int? totalBookings;

    if (json.containsKey('client_profile') && json['client_profile'] is Map) {
      final clientProfile = json['client_profile'] as Map<String, dynamic>;
      rating = clientProfile['rating'] != null
        ? double.tryParse(clientProfile['rating'].toString())
        : null;
      totalBookings = clientProfile['total_bookings'] as int?;
    }

    return ClientInfo(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      profilePicture: profilePicture,
      profilePictureUrl: profilePictureUrl,
      rating: rating,
      totalBookings: totalBookings,
    );
  }
}
