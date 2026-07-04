class Rating {
  final int id;
  final int bookingId;
  final int ratedById; // User who gave the rating
  final int ratedUserId; // User who received the rating
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;

  // بيانات العميل اللي كتب التقييم
  final String? ratedByName;
  final String? ratedByProfilePicture;

  Rating({
    required this.id,
    required this.bookingId,
    required this.ratedById,
    required this.ratedUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.ratedByName,
    this.ratedByProfilePicture,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    // طباعة البيانات الخام للتحقق

    // البيانات قد تأتي من API بصيغ مختلفة
    // الصيغة 1: rated_by_details كـ object
    // الصيغة 2: rater_info كـ object (من endpoint /provider/{id}/)
    // الصيغة 3: rated_by_name و rated_by_profile_picture مباشرة

    final ratedByDetails = json['rated_by_details'] as Map<String, dynamic>?;
    final raterInfo = json['rater_info'] as Map<String, dynamic>?;
    final clientDetails = ratedByDetails ?? raterInfo;

    // استخراج اسم العميل
    final ratedByName = clientDetails != null
        ? (clientDetails['full_name'] as String? ??
           '${clientDetails['first_name'] ?? ''} ${clientDetails['last_name'] ?? ''}'.trim())
        : (json['rated_by_name'] as String?);

    // استخراج صورة العميل
    final ratedByProfilePicture = clientDetails?['profile_picture_url'] as String?
        ?? clientDetails?['profile_picture'] as String?
        ?? json['rated_by_profile_picture'] as String?;

    // استخراج التعليق (comment أو review)
    final comment = json['comment'] as String? ?? json['review'] as String?;

    // Handle different field names from different endpoints
    final ratedBy = json['rated_by'] as int? ?? json['rater'] as int? ?? 0;
    final ratedUser = json['rated_user'] as int? ?? json['rated'] as int? ?? 0;


    return Rating(
      id: json['id'] as int,
      bookingId: json['booking'] as int,
      ratedById: ratedBy,
      ratedUserId: ratedUser,
      rating: json['rating'] as int,
      comment: comment,
      createdAt: DateTime.parse(json['created_at'] as String),
      ratedByName: ratedByName,
      ratedByProfilePicture: ratedByProfilePicture,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking': bookingId,
      'rated_user': ratedUserId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'review': comment,  // Changed from 'comment' to 'review'
    };
  }
}

class CreateRatingRequest {
  final int bookingId;
  final int ratedUserId;
  final int rating;
  final String? comment;

  CreateRatingRequest({
    required this.bookingId,
    required this.ratedUserId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'booking': bookingId,
      'rated_user': ratedUserId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'review': comment,  // Changed from 'comment' to 'review'
    };
  }
}
