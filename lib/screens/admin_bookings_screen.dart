import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';
import 'admin_booking_detail_screen.dart';

/// شاشة إدارة الحجوزات - Admin
class AdminBookingsScreen extends StatefulWidget {
  final String token;

  const AdminBookingsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminBookingsScreenState createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Map<String, dynamic>> bookings = [];
  Map<String, dynamic>? stats;
  Map<String, dynamic>? paymentStats; // إحصائيات الدفع
  bool isLoading = true;
  String errorMessage = '';


  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadBookings(),
      loadStats(),
      loadPaymentStats(),
    ]);
  }

  Future<void> loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AdminService.getAllBookings();

      if (response.success) {
        // الـ API بيرجع object فيه data key
        final responseData = response.rawResponse as Map<String, dynamic>?;
        final dataList = responseData?['data'] as List?;

        setState(() {
          // فلترة الحجوزات المدفوعة فقط
          final allBookings = dataList != null
              ? List<Map<String, dynamic>>.from(dataList)
              : <Map<String, dynamic>>[];

          bookings = allBookings.where((booking) {
            final status = booking['status'] as String?;
            return status == 'PAYMENT_COMPLETED' ||
                   status == 'IN_PROGRESS' ||
                   status == 'PENDING_COMPLETION' ||
                   status == 'COMPLETED';
          }).toList().cast<Map<String, dynamic>>();

          isLoading = false;
        });
      } else {
        throw Exception(response.error ?? 'فشل تحميل الحجوزات');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل الحجوزات: $e';
        isLoading = false;
      });
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await AdminService.getBookingStats();

      if (response.success) {
        // الـ API بيرجع object فيه data key
        final responseData = response.rawResponse as Map<String, dynamic>?;
        final dataMap = responseData?['data'] as Map<String, dynamic>?;

        setState(() {
          stats = dataMap ?? {};
        });
      }
    } catch (e) {
    }
  }

  Future<void> loadPaymentStats() async {
    try {
      final response = await ApiClient.get(
        '${ApiConfig.payskySuccessfulPayments}',
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse as Map<String, dynamic>;
        setState(() {
          paymentStats = {
            'total_payments': data['count'] ?? 0,
            'total_amount': (data['total_amount'] ?? 0.0).toDouble(),
          };
        });
      }
    } catch (e) {
    }
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

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'IN_PROGRESS':
        return Icons.hourglass_empty;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toStringAsFixed(0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.toStringAsFixed(0) ?? '0';
    }
    return '0';
  }

  Widget _buildPaymentStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.payment, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              const Text(
                'عمليات دفع ناجحة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${paymentStats!['total_payments']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              const Text(
                'إجمالي المدفوعات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${paymentStats!['total_amount'].toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          'إدارة الحجوزات والمدفوعات',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // الإحصائيات
          if (stats != null) _buildStatsSection(),

          // إحصائيات الدفع
          if (paymentStats != null) _buildPaymentStatsSection(),

          // قائمة الحجوزات
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : bookings.isEmpty
                        ? _buildEmptyWidget()
                        : _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'إحصائيات الحجوزات',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'الكل',
                  '${stats!['total_bookings'] ?? 0}',
                  Icons.event_note,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'مؤكد',
                  '${stats!['confirmed_bookings'] ?? 0}',
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'مكتمل',
                  '${stats!['completed_bookings'] ?? 0}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity( 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'إجمالي الإيرادات',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats!['total_revenue'] ?? 0} جنيه',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'متوسط قيمة الحجز',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(stats!['average_booking_value'])} جنيه',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.surface, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final statusColor = getStatusColor(status);
    final statusIcon = getStatusIcon(status);

    // استخراج معلومات السعر
    final priceDiff = booking['price_difference'];
    final hasPriceChange = priceDiff != null && priceDiff['difference'] != 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AdminBookingDetailScreen(
                token: widget.token,
                bookingId: booking['id'],
              ),
            ),
          ).then((_) => loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر مع الرقم والحالة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          booking['status_display'] ?? status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${booking['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // اسم الخدمة
              Text(
                booking['service_title'] ?? 'خدمة',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // معلومات العميل والبروفايدر
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'عميل: ${booking['client_name'] ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'مزود: ${booking['provider_name'] ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // التاريخ والوقت والمدينة
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${booking['booking_date']} | ${booking['booking_time']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    booking['city'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // السعر
              Row(
                children: [
                  Text(
                    '${booking['final_price']} جنيه',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  if (hasPriceChange) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priceDiff['difference'] > 0
                            ? Colors.orange.withOpacity( 0.1)
                            : Colors.green.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${priceDiff['difference'] > 0 ? '+' : ''}${priceDiff['difference'].toStringAsFixed(0)} جنيه (${priceDiff['percentage'].toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: priceDiff['difference'] > 0
                              ? Colors.orange[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد حجوزات',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
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
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
