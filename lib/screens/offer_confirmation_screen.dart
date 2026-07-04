import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/worker_offer_model.dart';
import '../models/booking_request_model.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';

class OfferConfirmationScreen extends StatefulWidget {
  final WorkerOffer offer;
  final BookingRequest bookingRequest;

  const OfferConfirmationScreen({
    super.key,
    required this.offer,
    required this.bookingRequest,
  });

  @override
  State<OfferConfirmationScreen> createState() => _OfferConfirmationScreenState();
}

class _OfferConfirmationScreenState extends State<OfferConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  Map<String, dynamic>? _providerData;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      final response = await ApiClient.get(
        ApiConfig.providerDetail(widget.offer.workerId),
      );

      if (mounted) {
        setState(() {
          if (response.data != null && response.data is Map<String, dynamic>) {
            _providerData = response.data as Map<String, dynamic>;
          } else if (response.rawResponse != null && response.rawResponse is Map<String, dynamic>) {
            _providerData = response.rawResponse as Map<String, dynamic>;
          }
        });
      }
    } catch (e) {
    }
  }

  String get _workerName {
    if (_providerData != null && _providerData!['full_name'] != null) {
      return _providerData!['full_name'];
    }
    return 'مقدم الخدمة #${widget.offer.workerId}';
  }

  double get _workerRating {
    if (_providerData != null && _providerData!['average_rating'] != null) {
      return (_providerData!['average_rating'] as num).toDouble();
    }
    return 0.0;
  }

  int get _workerReviews {
    if (_providerData != null && _providerData!['total_ratings'] != null) {
      return (_providerData!['total_ratings'] as num).toInt();
    }
    return 0;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.confirmOffer ?? 'تأكيد العرض',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4F46E5)
            : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 50,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Center(
                      child: Text(
                        'مراجعة وتأكيد الطلب',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'يرجى مراجعة تفاصيل الطلب قبل التأكيد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Price Summary Card
                    _buildPriceSummaryCard(),

                    const SizedBox(height: 24),

                    // Service Details Card
                    _buildServiceDetailsCard(),

                    // Worker Message (if any)
                    if (widget.offer.message != null && widget.offer.message!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildWorkerMessageCard(),
                    ],

                    const SizedBox(height: 24),

                    // Worker Info Card
                    _buildWorkerInfoCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ConnectivityButton(
                      onPressed: () => _confirmOrder(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    final total = widget.offer.offeredPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'ملخص الطلب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} جنيه',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل الخدمة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.home_repair_service,
            label: 'الخدمة',
            value: widget.bookingRequest.serviceTitle ?? 'غير محدد',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'التاريخ',
            value:
                '${widget.bookingRequest.bookingDate.day}/${widget.bookingRequest.bookingDate.month}/${widget.bookingRequest.bookingDate.year}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'الوقت',
            value: widget.bookingRequest.bookingTime,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'المدة',
            value: '${widget.bookingRequest.durationHours} ساعة',
          ),
          if (widget.bookingRequest.city != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'المدينة',
              value: widget.bookingRequest.city!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerMessageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.message_outlined,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 8),
              Text(
                'رسالة من العاملة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.offer.message!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF78350F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Worker Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5), width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
              ),
            ),
            child: Center(
              child: Text(
                _workerName.isNotEmpty ? _workerName[0].toUpperCase() : '👤',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Worker Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _workerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'موثقة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _workerRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($_workerReviews تقييم)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );

    try {
      // Create the booking directly (this will automatically accept the offer)
      final bookingResponse = await ApiClient.post(
        ApiConfig.createBooking,
        needsAuth: true,
        body: {
          'booking_request_id': widget.bookingRequest.id,
          'accepted_offer_id': widget.offer.id,
        },
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      if (!bookingResponse.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookingResponse.error ?? 'حدث خطأ أثناء تأكيد الحجز'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }


      // Get booking ID from response
      int? bookingId;
      if (bookingResponse.rawResponse != null) {
        if (bookingResponse.rawResponse is Map<String, dynamic>) {
          bookingId = bookingResponse.rawResponse['id'];
        }
      }

      // ملاحظة: الإشعار يجب أن يُرسل من Backend تلقائياً عند إنشاء الحجز
      // إذا لم يصل الإشعار للعاملة، تحقق من:
      // 1. Django signals في Backend (post_save على Booking model)
      // 2. Notification creation في Backend
      // 3. FCM token للعاملة

      // Show success message and close
      if (context.mounted) {
        _showSuccessDialog(context, bookingId);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, int? bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 12),
            Text('تم تأكيد الطلب بنجاح!'),
          ],
        ),
        content: const Text(
          'تم قبول العرض وتأكيد الحجز.\n\nتم إرسال إشعار للعاملة للبدء في تقديم الخدمة.\n\nشكراً لاستخدام خدماتنا!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          ConnectivityButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

}
