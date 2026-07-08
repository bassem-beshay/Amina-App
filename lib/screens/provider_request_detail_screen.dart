import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../widgets/payment_fee_notice.dart';

class ProviderRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const ProviderRequestDetailScreen({
    super.key,
    required this.request,
  });

  // Helper method to translate status from backend
  String _translateStatus(BuildContext context, String status) {
    // Remove any numbers and extra spaces for matching
    final cleanStatus = status.trim().toLowerCase();

    // Check common status patterns
    if (cleanStatus.contains('لم') && cleanStatus.contains('عروض') ||
        cleanStatus.contains('no offers') ||
        cleanStatus.contains('لم تستلم') ||
        cleanStatus.contains('لم استلم')) {
      return AppLocalizations.of(context)?.noOffersReceived ?? 'لم تستلم عروض';
    } else if (cleanStatus.contains('تم استلام') || cleanStatus.contains('استلام') || cleanStatus.contains('offer') || cleanStatus.contains('received')) {
      // Extract number of offers if present
      final numbers = RegExp(r'\d+').allMatches(status);
      if (numbers.isNotEmpty) {
        final count = numbers.first.group(0);
        return '${AppLocalizations.of(context)?.receivedOffersText ?? 'تم استلام'} $count ${AppLocalizations.of(context)?.offers ?? 'عروض'}';
      }
      return '${AppLocalizations.of(context)?.receivedOffersText ?? 'تم استلام'} ${AppLocalizations.of(context)?.offers ?? 'عروض'}';
    } else if (cleanStatus.contains('متاح') || cleanStatus.contains('available')) {
      return AppLocalizations.of(context)?.availableForOffers ?? 'متاح للعروض';
    } else if (cleanStatus.contains('جديد') || cleanStatus.contains('new')) {
      return AppLocalizations.of(context)?.newStatus ?? 'جديد';
    }

    // Return original if no match
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.requestDetails ?? 'تفاصيل الطلب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF10B981)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity( 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cleaning_services,
                          color: Theme.of(context).colorScheme.surface,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['service'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['category'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeaderInfo(
                        context,
                        Icons.payments_outlined,
                        AppLocalizations.of(context)?.budget ?? 'الميزانية',
                        '${request['budget'].toStringAsFixed(0)} ${AppLocalizations.of(context)?.egp ?? 'جنيه'}',
                      ),
                      const SizedBox(width: 20),
                      _buildHeaderInfo(
                        context,
                        Icons.people_outline,
                        AppLocalizations.of(context)?.offersSubmitted ?? 'العروض المقدمة',
                        '${request['offersCount']} ${AppLocalizations.of(context)?.offer ?? 'عرض'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Client Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildInfoCard(
                context,
                title: AppLocalizations.of(context)?.clientInformation ?? 'معلومات العميل',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow(
                    context,
                    Icons.person,
                    AppLocalizations.of(context)?.clientName ?? 'اسم العميل',
                    request['client'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.location_on,
                    AppLocalizations.of(context)?.location ?? 'الموقع',
                    request['location'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.home,
                    AppLocalizations.of(context)?.detailedAddress ?? 'العنوان التفصيلي',
                    request['address'],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Booking Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildInfoCard(
                context,
                title: AppLocalizations.of(context)?.bookingDetails ?? 'تفاصيل الحجز',
                icon: Icons.calendar_today,
                children: [
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    AppLocalizations.of(context)?.date ?? 'التاريخ',
                    request['date'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    AppLocalizations.of(context)?.time ?? 'الوقت',
                    request['time'],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.timer_outlined,
                    AppLocalizations.of(context)?.expectedDuration ?? 'المدة المتوقعة',
                    '${request['duration']} ${AppLocalizations.of(context)?.hours ?? 'ساعات'}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.requestStatus ?? 'حالة الطلب',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _translateStatus(context, request['statusDisplay'] ?? request['status'] ?? 'متاح للعروض'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.newStatus ?? 'جديد',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showOfferDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.submitPriceOffer ?? 'قدم عرض السعر',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.surface, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity( 0.8),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {
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
            color: Colors.black.withOpacity( 0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
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

  void _showOfferDialog(BuildContext context) {
    final priceController = TextEditingController();
    final notesController = TextEditingController();

    // Capture the localization strings before showing dialog
    final submitPriceOffer = AppLocalizations.of(context)?.submitPriceOffer ?? 'قدم عرض السعر';
    final requiredPrice = AppLocalizations.of(context)?.requiredPrice ?? 'السعر المطلوب';
    final enterPriceInEGP = AppLocalizations.of(context)?.enterPriceInEGP ?? 'أدخل السعر بالجنيه';
    final messageToClient = AppLocalizations.of(context)?.messageToClient ?? 'رسالة للعميل';
    final messageToClientHint = AppLocalizations.of(context)?.messageToClientHint ?? 'مثال: لدي خبرة 5 سنوات في هذا المجال وأستطيع تقديم خدمة احترافية...';
    final clientBudget = AppLocalizations.of(context)?.clientBudget ?? 'ميزانية العميل';
    final egp = AppLocalizations.of(context)?.egp ?? 'جنيه';
    final cancel = AppLocalizations.of(context)?.cancel ?? 'إلغاء';
    final sendOffer = AppLocalizations.of(context)?.sendOffer ?? 'إرسال العرض';
    final pleaseEnterPrice = AppLocalizations.of(context)?.pleaseEnterPrice ?? 'الرجاء إدخال السعر';
    final offerSubmittedSuccessfully = AppLocalizations.of(context)?.offerSubmittedSuccessfully ?? 'تم إرسال عرضك بنجاح!';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          submitPriceOffer,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requiredPrice,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: enterPriceInEGP,
                        prefixIcon: const Icon(Icons.payments_outlined),
                        suffixText: 'جنيه',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(dialogContext).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر تأكيد لإغلاق الكيبورد (مهم لـ iOS)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        FocusScope.of(dialogContext).unfocus();
                      },
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'تأكيد',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Payment Fee Notice
              const PaymentFeeNotice(compact: true),
              const SizedBox(height: 16),
              Text(
                messageToClient,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: messageToClientHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Theme.of(dialogContext).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity( 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$clientBudget: ${request['budget'].toStringAsFixed(0)} $egp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pleaseEnterPrice),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Close dialog
              Navigator.pop(dialogContext);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(offerSubmittedSuccessfully),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 3),
                ),
              );

              // Go back to home
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(sendOffer),
          ),
        ],
      ),
    );
  }
}
