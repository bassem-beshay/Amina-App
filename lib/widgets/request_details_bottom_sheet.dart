import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/booking_request_model.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import 'connectivity_button.dart';

class RequestDetailsBottomSheet extends StatelessWidget {
  final BookingRequest request;
  final VoidCallback onSubmitOffer;

  const RequestDetailsBottomSheet({
    Key? key,
    required this.request,
    required this.onSubmitOffer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get service image URL
    String? serviceImageUrl = request.serviceImage;
    if (serviceImageUrl != null && serviceImageUrl.isNotEmpty && !serviceImageUrl.startsWith('http')) {
      serviceImageUrl = '${ApiConfig.baseUrl}$serviceImageUrl';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Service Image Header (if available)
                  if (serviceImageUrl != null && serviceImageUrl.isNotEmpty)
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: serviceImageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                        ),
                        // Service title
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            request.serviceTitle ?? 'طلب حجز #${request.id}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Header without image
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.serviceTitle ?? 'طلب حجز #${request.id}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Client Info Card with Profile Picture
                  if (request.clientInfo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF374151).withOpacity(0.5)
                              : const Color(0xFF10B981).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : const Color(0xFF10B981).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Client profile picture
                            _buildClientProfileImage(request.clientInfo!),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.clientInfo!.fullName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Show rating if available
                                  if (request.clientInfo?.rating != null && request.clientInfo!.rating! > 0)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${request.clientInfo!.rating!.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (request.clientInfo?.totalBookings != null && request.clientInfo!.totalBookings! > 0)
                                          Text(
                                            ' (${request.clientInfo!.totalBookings} حجز)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'عميل جديد',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildDetailRow(context, 'الفئة', request.categoryName ?? '---', isDark),
                        _buildDetailRow(
                          context,
                          'التاريخ',
                          '${request.bookingDate.day}/${request.bookingDate.month}/${request.bookingDate.year}',
                          isDark,
                        ),
                        _buildDetailRow(context, 'الوقت', request.bookingTime, isDark),
                        _buildDetailRow(context, 'المدة', '${request.durationHours} ساعات', isDark),
                        _buildDetailRow(context, 'الموقع', request.location, isDark),
                        _buildDetailRow(
                          context,
                          'الميزانية',
                          '${request.clientBudget?.toStringAsFixed(0) ?? '---'} جنيه',
                          isDark,
                        ),
                        _buildDetailRow(context, 'الحالة', request.statusLabel, isDark),
                        _buildDetailRow(context, 'عدد العروض', '${request.offersCount} عرض', isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.cancel ?? 'إغلاق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ConnectivityIconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onSubmitOffer();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.send, size: 18),
                            label: Text(
                              AppLocalizations.of(context)?.submit ?? 'قدم عرضك الآن',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientProfileImage(ClientInfo clientInfo) {
    String? profilePicUrl = clientInfo.profilePictureUrl ?? clientInfo.profilePicture;

    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      String imageUrl = profilePicUrl;

      // Add base URL if not absolute
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF10B981).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 28,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ),
      );
    }

    // No image available, show default icon
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10B981).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 28,
        color: Color(0xFF10B981),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
