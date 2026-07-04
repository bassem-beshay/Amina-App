import 'package:flutter/material.dart';
import '../models/worker_offer_model.dart';
import '../services/worker_offer_stream_service.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

/// صفحة عرض العروض للعميل مع تحديثات real-time
/// العروض الجديدة تظهر تلقائيًا بدون الحاجة لـ refresh
class ClientOffersStreamScreen extends StatefulWidget {
  final int bookingRequestId; // معرف طلب الحجز

  const ClientOffersStreamScreen({
    Key? key,
    required this.bookingRequestId,
  }) : super(key: key);

  @override
  State<ClientOffersStreamScreen> createState() => _ClientOffersStreamScreenState();
}

class _ClientOffersStreamScreenState extends State<ClientOffersStreamScreen> {
  final WorkerOfferStreamService _streamService = WorkerOfferStreamService();

  @override
  void initState() {
    super.initState();

    // بدء الاستماع للتحديثات - يشبه Firestore snapshots()
    // سيتم جلب العروض كل 8 ثواني تلقائيًا
    _streamService.startListening(
      bookingRequestId: widget.bookingRequestId,
      pollInterval: const Duration(seconds: 8),
      immediate: true,
    );
  }

  @override
  void dispose() {
    // إيقاف الاستماع عند الخروج من الصفحة
    _streamService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)?.translate('offersReceived') ?? 'العروض المقدمة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            // عرض عداد العروض الجديدة
            StreamBuilder<int>(
              stream: _streamService.newOffersCountStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: RefreshIndicator(
        onRefresh: () => _streamService.refresh(),
        child: StreamBuilder<List<WorkerOffer>>(
          // 🔥 هنا السحر - التحديثات التلقائية!
          stream: _streamService.offersStream,
          builder: (context, snapshot) {
            // حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4F46E5),
                ),
              );
            }

            // حالة الخطأ
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ في جلب العروض',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _streamService.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                      ),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final offers = snapshot.data ?? [];

            // حالة عدم وجود عروض
            if (offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عروض بعد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم عرض العروض هنا عند تقديمها',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'العروض الجديدة ستظهر تلقائيًا',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // عرض العروض
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return OfferCard(
                  offer: offer,
                  onAccept: () => _handleAcceptOffer(offer),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAcceptOffer(WorkerOffer offer) async {
    // تأكيد قبول العرض
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد قبول العرض'),
        content: Text(
          'هل أنت متأكد من قبول هذا العرض؟\n\nالسعر: ${offer.offeredPrice} جنيه',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
            ),
            child: const Text('قبول العرض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // عرض loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );

    // قبول العرض عبر الـ stream service
    final result = await _streamService.acceptOffer(offer.id);

    // إخفاء loading
    if (!mounted) return;
    Navigator.pop(context);

    // عرض النتيجة
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surface),
              const SizedBox(width: 8),
              Text(result.message ?? 'تم قبول العرض بنجاح'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // العودة للصفحة السابقة
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Theme.of(context).colorScheme.surface),
              const SizedBox(width: 8),
              Text(result.error ?? 'فشل قبول العرض'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget لعرض بطاقة عرض واحد
class OfferCard extends StatelessWidget {
  final WorkerOffer offer;
  final VoidCallback onAccept;

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPending = offer.status == 'pending';
    final isAccepted = offer.status == 'accepted';
    final isNew = DateTime.now().difference(offer.createdAt).inMinutes < 5;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isNew && isPending
            ? Border.all(color: const Color(0xFF4F46E5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // معرف العاملة
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF4F46E5).withOpacity( 0.1),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عاملة #${offer.workerId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDateTime(offer.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge للعرض الجديد
                if (isNew && isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'جديد',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // السعر المقدم
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر المقترح',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${offer.offeredPrice} جنيه',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.priceActionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // الرسالة
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'رسالة من العاملة:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.message!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // المدة المقدرة
            if (offer.estimatedDuration != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'المدة المقدرة: ${offer.estimatedDuration} دقيقة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // حالة العرض
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getStatusIcon(offer.status),
                  size: 16,
                  color: _getStatusColor(offer.status),
                ),
                const SizedBox(width: 4),
                Text(
                  'الحالة: ${offer.statusLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(offer.status),
                  ),
                ),
              ],
            ),

            // زر قبول العرض
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'عرض تفاصيل الحجز',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // رسالة للعرض المقبول
            if (isAccepted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم قبول هذا العرض وإنشاء حجز',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ \u200F${difference.inMinutes}\u200F دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ \u200F${difference.inHours}\u200F ساعة';
    } else {
      return DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(dateTime);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'withdrawn':
        return Icons.remove_circle;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
