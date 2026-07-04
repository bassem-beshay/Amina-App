class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role; // CLIENT, PROVIDER, ADMIN
  final bool isActive;
  final DateTime dateJoined;
  final ClientProfile? clientProfile;
  final ServiceProviderProfile? providerProfile;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.dateJoined,
    this.clientProfile,
    this.providerProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'] as String)
          : DateTime.now(),
      clientProfile: json['client_profile'] != null
          ? ClientProfile.fromJson(json['client_profile'] as Map<String, dynamic>)
          : null,
      providerProfile: json['provider_profile'] != null
          ? ServiceProviderProfile.fromJson(json['provider_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'date_joined': dateJoined.toIso8601String(),
      if (clientProfile != null) 'client_profile': clientProfile!.toJson(),
      if (providerProfile != null) 'provider_profile': providerProfile!.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';

  bool get isClient => role == 'CLIENT';
  bool get isProvider => role == 'PROVIDER';
  bool get isAdmin => role == 'ADMIN';
}

class ClientProfile {
  final User? user;
  final String? displayName;
  final String? profilePicture;
  final String? profilePictureUrl;
  final double? latitude;
  final double? longitude;
  final List<double>? locationCoordinates;
  final String? formattedAddress;
  final String? city;
  final String? country;
  final List<int>? preferredServiceCategories;
  final List<String>? preferredServiceCategoriesList;
  final List<Address>? addresses;
  final double? averageRating;
  final int? totalRatings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientProfile({
    this.user,
    this.displayName,
    this.profilePicture,
    this.profilePictureUrl,
    this.latitude,
    this.longitude,
    this.locationCoordinates,
    this.formattedAddress,
    this.city,
    this.country,
    this.preferredServiceCategories,
    this.preferredServiceCategoriesList,
    this.addresses,
    this.averageRating,
    this.totalRatings,
    this.createdAt,
    this.updatedAt,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      displayName: json['display_name'] as String?,
      profilePicture: json['profile_picture'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      locationCoordinates: json['location_coordinates'] != null
          ? (json['location_coordinates'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : null,
      formattedAddress: json['formatted_address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      preferredServiceCategories: json['preferred_service_categories'] != null
          ? (json['preferred_service_categories'] as List)
              .map((e) => e as int)
              .toList()
          : null,
      preferredServiceCategoriesList:
          json['preferred_service_categories_list'] != null
              ? (json['preferred_service_categories_list'] as List)
                  .map((e) => e as String)
                  .toList()
              : null,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
              .map((addr) => Address.fromJson(addr as Map<String, dynamic>))
              .toList()
          : null,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalRatings: json['total_ratings'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (preferredServiceCategories != null)
        'preferred_service_categories': preferredServiceCategories,
      if (addresses != null)
        'addresses': addresses!.map((a) => a.toJson()).toList(),
      if (averageRating != null) 'average_rating': averageRating,
      if (totalRatings != null) 'total_ratings': totalRatings,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper getters
  String get name => displayName ?? user?.fullName ?? 'مستخدم';
  String get displayCity => city ?? 'غير محدد';
  String get displayAddress => formattedAddress ?? 'لم يتم تحديد العنوان';
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasProfilePicture => profilePictureUrl != null;
}

class ServiceProviderProfile {
  final int? id;
  final int? userId;
  final String? bio;
  final String? profilePicture;
  final String? identityDocument;
  final String? healthCertificate;
  final String? city;
  final String? country;
  final String? verificationStatus; // PENDING, VERIFIED, REJECTED
  final List<int>? preferredServiceCategories;
  final List<String>? preferredServiceCategoriesList;
  final double? averageRating;
  final int? totalRatings;
  final int? completedJobs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceProviderProfile({
    this.id,
    this.userId,
    this.bio,
    this.profilePicture,
    this.identityDocument,
    this.healthCertificate,
    this.city,
    this.country,
    this.verificationStatus,
    this.preferredServiceCategories,
    this.preferredServiceCategoriesList,
    this.averageRating,
    this.totalRatings,
    this.completedJobs,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceProviderProfile.fromJson(Map<String, dynamic> json) {
    return ServiceProviderProfile(
      id: json['id'] as int?,
      userId: json['user'] is Map ? json['user']['id'] as int? : json['user'] as int?,
      bio: json['bio'] as String?,
      profilePicture: json['profile_picture_url'] as String? ?? json['profile_picture'] as String?,
      identityDocument: json['identity_document_url'] as String? ?? json['identity_document'] as String?,
      healthCertificate: json['health_certificate_url'] as String? ?? json['health_certificate'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      verificationStatus: json['verification_status'] as String?,
      preferredServiceCategories: json['preferred_service_categories'] != null
          ? (json['preferred_service_categories'] as List).map((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e) ?? 0;
              return 0;
            }).toList()
          : null,
      preferredServiceCategoriesList: json['preferred_service_categories_list'] != null
          ? (json['preferred_service_categories_list'] as List).map((e) => e as String).toList()
          : null,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalRatings: json['total_ratings'] as int?,
      completedJobs: json['completed_jobs'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user': userId,
      if (bio != null) 'bio': bio,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (identityDocument != null) 'identity_document': identityDocument,
      if (healthCertificate != null) 'health_certificate': healthCertificate,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (averageRating != null) 'average_rating': averageRating,
      if (totalRatings != null) 'total_ratings': totalRatings,
      if (completedJobs != null) 'completed_jobs': completedJobs,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isPending => verificationStatus == 'PENDING';
  bool get isRejected => verificationStatus == 'REJECTED';
}

class Address {
  final int id;
  final int clientProfileId;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final String? country;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.clientProfileId,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postalCode,
    this.country,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int,
      clientProfileId: json['client_profile'] as int,
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String? ?? '',
      city: json['city'] as String,
      postalCode: json['postal_code'] as String? ?? '',
      country: json['country'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_profile': clientProfileId,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      if (country != null) 'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2.isNotEmpty) parts.add(addressLine2);
    parts.add(city);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }
}
