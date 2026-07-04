import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../widgets/connectivity_button.dart';

/// شاشة تفاصيل حجز معين - Admin
class AdminBookingDetailScreen extends StatefulWidget {
  final String token;
  final int bookingId;

  const AdminBookingDetailScreen({
    Key? key,
    required this.token,
    required this.bookingId,
  }) : super(key: key);

  @override
  _AdminBookingDetailScreenState createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  Map<String, dynamic>? booking;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadBookingDetails();
  }

  Future<void> loadBookingDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AdminService.getBookingDetails(widget.bookingId);

      if (response.success) {
        // الـ API بيرجع object فيه data key
        final responseData = response.rawResponse as Map<String, dynamic>?;
        final dataMap = responseData?['data'] as Map<String, dynamic>?;

        setState(() {
          booking = dataMap;
          isLoading = false;
        });
      } else {
        throw Exception(response.error ?? 'فشل تحميل تفاصيل الحجز');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل التفاصيل: $e';
        isLoading = false;
      });
    }
  }

  Future<void> cancelBooking() async {
    // إظهار dialog لإدخال السبب
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('إلغاء الحجز'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('تراجع'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // إظهار loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        final response = await AdminService.cancelBooking(
          widget.bookingId,
          reasonController.text.isEmpty
              ? 'تم الإلغاء من قبل الإدارة'
              : reasonController.text,
        );

        // إغلاق loading
        if (mounted) Navigator.of(context).pop();

        if (response.success) {
          // إظهار رسالة نجاح
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إلغاء الحجز بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // إعادة تحميل التفاصيل
          loadBookingDetails();
        } else {
          // إظهار رسالة خطأ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.error ?? 'فشل إلغاء الحجز'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // إغلاق loading
        if (mounted) Navigator.of(context).pop();

        // إظهار رسالة خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          'حجز #${widget.bookingId}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadBookingDetails,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (booking == null) return const SizedBox();

    final status = booking!['status'] as String;
    final statusColor = getStatusColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة الحالة
          _buildStatusCard(status, statusColor),
          const SizedBox(height: 16),

          // معلومات الخدمة
          _buildSection(
            title: 'معلومات الخدمة',
            icon: Icons.home_repair_service,
            children: [
              _buildInfoRow('الخدمة', booking!['service_title'] ?? ''),
              _buildInfoRow('الوصف', booking!['service_description'] ?? ''),
              _buildInfoRow('التاريخ', booking!['booking_date'] ?? ''),
              _buildInfoRow('الوقت', booking!['booking_time'] ?? ''),
              _buildInfoRow(
                  'المدة', '${booking!['duration_hours']} ساعة'),
              _buildInfoRow('المدينة', booking!['city'] ?? ''),
              _buildInfoRow('العنوان', booking!['address'] ?? ''),
            ],
          ),
          const SizedBox(height: 16),

          // معلومات العميل
          _buildClientSection(),
          const SizedBox(height: 16),

          // معلومات مزود الخدمة
          _buildProviderSection(),
          const SizedBox(height: 16),

          // معلومات السعر
          _buildPriceSection(),
          const SizedBox(height: 16),

          // الملاحظات
          if (booking!['client_notes']?.toString().isNotEmpty == true ||
              booking!['provider_notes']?.toString().isNotEmpty == true)
            _buildNotesSection(),
          const SizedBox(height: 16),

          // معلومات الإلغاء
          if (status == 'CANCELED') _buildCancellationSection(),
          const SizedBox(height: 16),

          // الإحصائيات
          _buildStatsRow(),
          const SizedBox(height: 16),

          // أزرار الإجراءات
          if (status != 'CANCELED' && status != 'COMPLETED')
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            status == 'COMPLETED'
                ? Icons.check_circle
                : status == 'CANCELED'
                    ? Icons.cancel
                    : status == 'IN_PROGRESS'
                        ? Icons.hourglass_empty
                        : Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.surface,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            booking!['status_display'] ?? status,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تاريخ التأكيد: ${booking!['confirmed_at'] ?? ''}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity( 0.1),
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
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    final clientInfo = booking!['client_info'] as Map<String, dynamic>?;
    if (clientInfo == null) return const SizedBox();

    return _buildSection(
      title: 'معلومات العميل',
      icon: Icons.person,
      children: [
        _buildInfoRow('الاسم',
            '${clientInfo['first_name']} ${clientInfo['last_name']}'),
        _buildInfoRow('البريد الإلكتروني', clientInfo['email'] ?? ''),
        _buildInfoRow('رقم الهاتف', clientInfo['phone_number'] ?? ''),
      ],
    );
  }

  Widget _buildProviderSection() {
    final providerInfo = booking!['provider_info'] as Map<String, dynamic>?;
    if (providerInfo == null) return const SizedBox();

    final profile = providerInfo['profile'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'معلومات مزود الخدمة',
      icon: Icons.work,
      children: [
        _buildInfoRow('الاسم',
            '${providerInfo['first_name']} ${providerInfo['last_name']}'),
        _buildInfoRow('البريد الإلكتروني', providerInfo['email'] ?? ''),
        _buildInfoRow('رقم الهاتف', providerInfo['phone_number'] ?? ''),
        if (profile != null) ...[
          _buildInfoRow('التقييم',
              '${profile['average_rating']?.toStringAsFixed(1) ?? '0'} / 5 (${profile['total_ratings']} تقييم)'),
          _buildInfoRow(
              'الخدمات المكتملة', '${profile['completed_jobs']} خدمة'),
          _buildInfoRow(
              'حالة التوثيق', profile['verification_status'] ?? ''),
        ],
      ],
    );
  }

  Widget _buildPriceSection() {
    final acceptedOfferDetails =
        booking!['accepted_offer_details'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'معلومات السعر',
      icon: Icons.payments,
      children: [
        if (acceptedOfferDetails != null) ...[
          _buildInfoRow('السعر الأصلي',
              '${acceptedOfferDetails['original_price']} جنيه'),
          _buildInfoRow('السعر المعروض',
              '${acceptedOfferDetails['offered_price']} جنيه'),
          _buildInfoRow('الفرق',
              '${acceptedOfferDetails['price_difference']} جنيه'),
        ],
        _buildInfoRow('السعر النهائي', '${booking!['final_price']} جنيه'),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'الملاحظات',
      icon: Icons.notes,
      children: [
        if (booking!['client_notes']?.toString().isNotEmpty == true)
          _buildInfoRow('ملاحظات العميل', booking!['client_notes'] ?? ''),
        if (booking!['provider_notes']?.toString().isNotEmpty == true)
          _buildInfoRow(
              'ملاحظات المزود', booking!['provider_notes'] ?? ''),
      ],
    );
  }

  Widget _buildCancellationSection() {
    return _buildSection(
      title: 'معلومات الإلغاء',
      icon: Icons.cancel,
      children: [
        _buildInfoRow(
            'ألغي بواسطة', booking!['canceled_by_info']?['email'] ?? 'غير معروف'),
        _buildInfoRow('تاريخ الإلغاء', booking!['canceled_at'] ?? ''),
        _buildInfoRow('السبب', booking!['cancellation_reason'] ?? ''),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 28),
                const SizedBox(height: 8),
                Text(
                  '${booking!['ratings_count'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'تقييمات',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.report, color: Colors.red, size: 28),
                const SizedBox(height: 8),
                Text(
                  '${booking!['complaints_count'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'شكاوى',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ConnectivityIconButton(
        onPressed: cancelBooking,
        icon: const Icon(Icons.cancel),
        label: const Text('إلغاء الحجز'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorMessage),
          const SizedBox(height: 16),
          ConnectivityIconButton(
            onPressed: loadBookingDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
