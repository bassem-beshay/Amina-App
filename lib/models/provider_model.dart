class Provider {
  final int id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? profilePicture;
  final double? averageRating;
  final int? totalRatings;
  final double? hourlyRate;
  final String? bio;
  final String? providerType; // COMPANY, MEMBER
  final bool isAvailable;
  final bool isVerified;

  Provider({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.profilePicture,
    this.averageRating,
    this.totalRatings,
    this.hourlyRate,
    this.bio,
    this.providerType,
    required this.isAvailable,
    required this.isVerified,
  });

  String get fullName {
    // Handle empty or null names
    if ((firstName.isEmpty || firstName == '') && (lastName.isEmpty || lastName == '')) {
      return 'عاملة #$id';
    }
    if (firstName.isEmpty || firstName == '') {
      return lastName;
    }
    if (lastName.isEmpty || lastName == '') {
      return firstName;
    }
    return '$firstName $lastName'.trim();
  }

  factory Provider.fromJson(Map<String, dynamic> json) {
    // Get user data from nested 'user' object if it exists
    final userData = json['user'] as Map<String, dynamic>?;

    // Get profile picture - prefer profile_picture_url (from backend) over profile_picture
    String? profilePicture = json['profile_picture_url'] ?? json['profile_picture'];

    return Provider(
      id: userData?['id'] ?? json['id'] ?? 0,
      firstName: userData?['first_name'] ?? json['first_name'] ?? '',
      lastName: userData?['last_name'] ?? json['last_name'] ?? '',
      phone: userData?['phone_number'] ?? json['phone'],
      email: userData?['email'] ?? json['email'],
      address: json['formatted_address'] ?? json['address'],
      city: json['city'],
      state: json['state'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      profilePicture: profilePicture,
      averageRating: json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) : null,
      totalRatings: json['total_ratings'],
      hourlyRate: json['hourly_rate'] != null ? double.tryParse(json['hourly_rate'].toString()) : null,
      bio: json['bio'],
      providerType: json['provider_type'] as String?,
      isAvailable: json['is_available'] ?? true,
      isVerified: json['verification_status'] == 'VERIFIED' || json['is_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'profile_picture': profilePicture,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'hourly_rate': hourlyRate,
      'bio': bio,
      'provider_type': providerType,
      'is_available': isAvailable,
      'is_verified': isVerified,
    };
  }

  bool get isCompany => providerType == 'COMPANY';
  bool get isMember => providerType == 'MEMBER';
}
