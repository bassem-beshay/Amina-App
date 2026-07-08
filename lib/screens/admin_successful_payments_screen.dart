import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';

class AdminSuccessfulPaymentsScreen extends StatefulWidget {
  final String token;

  const AdminSuccessfulPaymentsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminSuccessfulPaymentsScreenState createState() => _AdminSuccessfulPaymentsScreenState();
}

class _AdminSuccessfulPaymentsScreenState extends State<AdminSuccessfulPaymentsScreen> {
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  String errorMessage = '';
  int totalPayments = 0;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      final resp = await ApiClient.get(
        ApiConfig.payskySuccessfulPayments,
        needsAuth: true,
      );

      if (resp.success && resp.rawResponse != null) {
        final data = resp.rawResponse as Map<String, dynamic>;
        setState(() {
          payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
          totalPayments = data['count'] ?? 0;
          totalAmount = (data['total_amount'] ?? 0.0).toDouble();
          isLoading = false;
        });
      } else {
        throw Exception(resp.error ?? 'فشل تحميل البيانات');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ: $e';
        isLoading = false;
      });
    }
  }

  String formatCurrency(String amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: currencyCode == '818' ? 'ج.م' : 'ر.س',
      decimalDigits: 2,
    );
    return formatter.format(double.tryParse(amount) ?? 0.0);
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: const Text(
          'عمليات الدفع الناجحة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadPayments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage),
                      const SizedBox(height: 16),
                      ConnectivityIconButton(
                        onPressed: loadPayments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPayments,
                  color: const Color(0xFF10B981),
                  child: Column(
                    children: [
                      // إحصائيات عامة
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.payments,
                              label: 'إجمالي العمليات',
                              value: '$totalPayments',
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              icon: Icons.account_balance_wallet,
                              label: 'إجمالي المبلغ',
                              value: '${totalAmount.toStringAsFixed(2)} ج.م',
                            ),
                          ],
                        ),
                      ),

                      // قائمة المدفوعات
                      Expanded(
                        child: payments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد عمليات دفع ناجحة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  final payment = payments[index];
                                  return _buildPaymentCard(payment, isDark);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, bool isDark) {
    final bookingDetails = payment['booking_details'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة - معلومات العميل والمبلغ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['client_name'] ?? 'غير معروف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment['client_email'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatCurrency(payment['amount'], payment['currency_code']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // تفاصيل الدفع
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'رقم الهاتف',
                  value: payment['client_phone'] ?? '--',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.receipt,
                  label: 'رقم المعاملة',
                  value: payment['transaction_reference'] ?? '--',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.confirmation_number,
                  label: 'رقم النظام',
                  value: payment['system_reference'] ?? '--',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.credit_card,
                  label: 'طريقة الدفع',
                  value: payment['paid_through'] ?? 'بطاقة',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'تاريخ الدفع',
                  value: formatDate(payment['payment_completed_at']),
                  isDark: isDark,
                ),

                // معلومات الحجز (إذا كانت متوفرة)
                if (bookingDetails != null) ...[
                  const Divider(height: 24),
                  Text(
                    'تفاصيل الحجز',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.cleaning_services,
                    label: 'الخدمة',
                    value: bookingDetails['service_title'] ?? '--',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'مقدم الخدمة',
                    value: bookingDetails['provider_name'] ?? '--',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.event,
                    label: 'موعد الخدمة',
                    value: '${formatDate(bookingDetails['booking_date'])} ${bookingDetails['booking_time'] ?? ''}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.info_outline,
                    label: 'حالة الحجز',
                    value: _getBookingStatusText(bookingDetails['status']),
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  String _getBookingStatusText(String? status) {
    switch (status) {
      case 'CONFIRMED':
        return 'مؤكد';
      case 'PAYMENT_COMPLETED':
        return 'تم الدفع';
      case 'IN_PROGRESS':
        return 'جاري التنفيذ';
      case 'PENDING_COMPLETION':
        return 'بانتظار التأكيد';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELED':
        return 'ملغي';
      default:
        return status ?? '--';
    }
  }
}
