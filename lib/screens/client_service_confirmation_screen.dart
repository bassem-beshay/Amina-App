import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

/// شاشة تأكيد إكمال الخدمة للعميل
/// تظهر للعميل لما العاملة تخلص الخدمة
class ClientServiceConfirmationScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic>? bookingData;

  const ClientServiceConfirmationScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<ClientServiceConfirmationScreen> createState() =>
      _ClientServiceConfirmationScreenState();
}

class _ClientServiceConfirmationScreenState
    extends State<ClientServiceConfirmationScreen> {
  bool _isLoading = false;
  bool _isConfirming = false;
  Map<String, dynamic>? _bookingData;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
    if (_bookingData == null) {
      _loadBookingData();
    }
  }

  Future<void> _loadBookingData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        '/api/bookings/${widget.bookingId}/',
        needsAuth: true,
      );

      if (!mounted) return;

      if (response.success && response.rawResponse != null) {
        setState(() {
          _bookingData = response.rawResponse as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerName = _bookingData?['provider_info']?['full_name'] ?? 'العاملة';
    final serviceName = _bookingData?['service_title'] ?? 'الخدمة';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('confirmServiceCompletion') ?? 'تأكيد إكمال الخدمة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF59E0B),
              ),
            )
          : Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'الخدمة منتهية',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'العاملة "$providerName" أبلغت بإنهاء الخدمة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الخدمة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.cleaning_services,
                                  color: Color(0xFF4F46E5),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الخدمة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      serviceName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
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
                                      'العاملة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      providerName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirmation message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'يرجى التأكد من إكمال الخدمة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'قبل التأكيد، يرجى التحقق من أن الخدمة قد تم إنجازها بشكل كامل ومُرضي.\n\nبعد التأكيد، سيتم إغلاق الحجز وسيمكنك تقييم العاملة.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ConnectivityIconButton(
                      onPressed: _isConfirming ? null : _confirmCompletion,
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 24),
                      label: Text(
                        _isConfirming ? 'جاري التأكيد...' : 'نعم، تم إكمال الخدمة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Report issue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _reportIssue,
                      icon: const Icon(Icons.report_problem_outlined, size: 24),
                      label: const Text(
                        'الإبلاغ عن مشكلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCompletion() async {
    setState(() {
      _isConfirming = true;
    });

    try {
      final response = await ApiClient.post(
        '/api/bookings/${widget.bookingId}/confirm-completion/',
        needsAuth: true,
      );

      if (!mounted) return;

      setState(() {
        _isConfirming = false;
      });

      if (response.success) {
        // Show success message and return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم تأكيد إكمال الخدمة بنجاح'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${response.error ?? "فشل تأكيد الإكمال"}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _reportIssue() {
    final complaintController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('الإبلاغ عن مشكلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى وصف المشكلة:'),
            const SizedBox(height: 12),
            TextField(
              controller: complaintController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب المشكلة هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              complaintController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final complaint = complaintController.text.trim();
              if (complaint.isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              complaintController.dispose();
              
              // Wait a bit for dialog to close before showing snackbar
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              
              _submitComplaint(complaint);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(String complaint) async {
    try {
      final response = await ApiClient.post(
        '/api/bookings/complaints/create/',
        needsAuth: true,
        body: {
          'booking': widget.bookingId,
          'title': 'شكوى على الخدمة',
          'description': complaint,
        },
      );

      if (!mounted) return;

      if (response.success) {
        // Show success dialog instead of snackbar
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
                Expanded(child: Text('تم إرسال الشكوى')),
              ],
            ),
            content: const Text(
              'تم تقديم الشكوى بنجاح.\n\nسيتم مراجعتها من قبل الإدارة والتواصل معك قريباً.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            actions: [
              ElevatedButton(
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${response.error ?? "فشل إرسال البلاغ"}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

