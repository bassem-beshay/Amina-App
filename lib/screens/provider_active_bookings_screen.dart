import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'service_in_progress_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/payment_fee_notice.dart';

/// شاشة الحجوزات النشطة للعاملة (Provider)
/// تعرض الحجوزات المدفوعة والجارية والمنتهية
class ProviderActiveBookingsScreen extends StatefulWidget {
  ProviderActiveBookingsScreen({super.key});

  @override
  State<ProviderActiveBookingsScreen> createState() =>
      _ProviderActiveBookingsScreenState();
}

class _ProviderActiveBookingsScreenState
    extends State<ProviderActiveBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        '/api/bookings/?status=CONFIRMED',
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse as Map<String, dynamic>;
        setState(() {
          _bookings = data['data'] as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // الرجوع للـ home
        Navigator.pushNamedAndRemoveUntil(context, '/provider-home', (route) => false);
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.activeBookings ?? 'الحجوزات النشطة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface),
          onPressed: () {
            // الرجوع للـ home بدلاً من pop
            Navigator.pushNamedAndRemoveUntil(context, '/provider-home', (route) => false);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(_bookings[index]);
                    },
                  ),
                ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noData ?? 'لا توجد بيانات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر الحجوزات المدفوعة هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final status = booking['status'] ?? '';
    final clientName = booking['client_info']?['full_name'] ?? 'عميل';
    // Use English service name if language is English
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final serviceName = isEnglish && booking['service_title_en'] != null && booking['service_title_en'].toString().isNotEmpty
        ? booking['service_title_en']
        : (booking['service_title'] ?? 'خدمة');
    final date = booking['booking_date'] ?? '';
    final time = booking['booking_time'] ?? '';
    final city = booking['city'] ?? '';
    final amount = booking['final_price'] ?? '0';
    final currency = AppLocalizations.of(context)?.egpCurrency ?? 'EGP';
    final bookingId = booking['id'];

    Color statusColor;
    String statusText;
    IconData statusIcon;
    Widget? actionButton;

    switch (status) {
      case 'CONFIRMED':
      case 'PAYMENT_COMPLETED':
        statusColor = Color(0xFF10B981);
        statusText = 'accepted';
        statusIcon = Icons.check_circle;
        actionButton = null;
        break;
      case 'IN_PROGRESS':
        statusColor = Color(0xFF3B82F6);
        statusText = 'inProgress';
        statusIcon = Icons.play_circle;
        actionButton = null;
        break;
      case 'PROVIDER_COMPLETED':
        statusColor = Color(0xFFF59E0B);
        statusText = 'pending';
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'COMPLETED':
        statusColor = Color(0xFF10B981);
        statusText = 'accepted';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Service Name
            Text(
              serviceName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),

            // Client Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.surface,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.client ?? 'العميل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Date & Time
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: AppLocalizations.of(context)?.dateAndTime ?? 'التاريخ والوقت',
              value: '$date - $time',
              color: Color(0xFF3B82F6),
            ),
            SizedBox(height: 8),

            // Address
            _buildInfoRow(
              icon: Icons.location_on,
              label: AppLocalizations.of(context)?.city ?? 'المدينة',
              value: city,
              color: Color(0xFFEF4444),
            ),
            SizedBox(height: 12),

            // Amount
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: Color(0xFF4F46E5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)?.amount ?? 'المبلغ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$amount $currency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            if (actionButton != null) ...[
              SizedBox(height: 16),
              actionButton,
            ],

            // Payment Fee Notice at bottom
            const SizedBox(height: 12),
            const PaymentFeeInline(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
