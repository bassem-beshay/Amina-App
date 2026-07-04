import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_request_model.dart';
import '../l10n/app_localizations.dart';
import 'connectivity_button.dart';
import 'payment_fee_notice.dart';

class OfferBottomSheet extends StatefulWidget {
  final BookingRequest request;

  const OfferBottomSheet({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  State<OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<OfferBottomSheet> {
  String _priceAction = 'accept';
  late TextEditingController _priceController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.request.clientBudget?.toStringAsFixed(0) ?? '0',
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.submit ?? 'تقديم عرض',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Service info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.1),
                          const Color(0xFF10B981).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.cleaning_services,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.request.serviceTitle ?? 'طلب حجز #${widget.request.id}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppLocalizations.of(context)?.price ?? "ميزانية العميل"}: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${widget.request.clientBudget?.toStringAsFixed(0) ?? '---'} جنيه',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Fee Notice
                  const PaymentFeeNotice(compact: true),

                  const SizedBox(height: 20),

                  // Price action selection
                  Text(
                    'اختر نوع العرض:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Accept option
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _priceAction == 'accept'
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: 2,
                      ),
                      color: _priceAction == 'accept'
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: RadioListTile<String>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        AppLocalizations.of(context)?.accept ?? 'قبول سعر العميل',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: Text(
                        '${widget.request.clientBudget?.toStringAsFixed(0) ?? '---'} جنيه',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      value: 'accept',
                      groupValue: _priceAction,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (value) {
                        setState(() {
                          _priceAction = value!;
                          _priceController.text = widget.request.clientBudget?.toStringAsFixed(0) ?? '0';
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Counter option
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _priceAction == 'counter'
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: 2,
                      ),
                      color: _priceAction == 'counter'
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: RadioListTile<String>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        AppLocalizations.of(context)?.submit ?? 'اقتراح سعر مختلف',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: Text(
                        'يجب أن يكون أعلى من ميزانية العميل',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      value: 'counter',
                      groupValue: _priceAction,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (value) {
                        setState(() {
                          _priceAction = value!;
                          final clientBudget = widget.request.clientBudget ?? 0;
                          _priceController.text = (clientBudget + 50).toStringAsFixed(0);
                        });
                      },
                    ),
                  ),

                  // Price input (only for counter)
                  if (_priceAction == 'counter') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)?.price ?? 'السعر المقترح (جنيه)',
                              labelStyle: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981)),
                              suffixText: 'جنيه',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF374151).withOpacity(0.5)
                                  : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر تأكيد لإغلاق الكيبورد (مهم لـ iOS)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
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
                  ],

                  const SizedBox(height: 20),

                  // Message
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.notes ?? 'رسالة للعميل (اختياري)',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      hintText: AppLocalizations.of(context)?.messageToClientHint ?? 'مثال: لدي خبرة 5 سنوات في هذا المجال...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF374151).withOpacity(0.5)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.cancel ?? 'إلغاء',
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
                            // Validate
                            final offeredPrice = double.tryParse(_priceController.text) ?? 0;
                            final clientBudget = widget.request.clientBudget ?? 0;

                            if (_priceAction == 'counter' && offeredPrice <= clientBudget) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('السعر المقترح يجب أن يكون أعلى من ميزانية العميل'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Return result
                            Navigator.pop(context, {
                              'success': true,
                              'priceAction': _priceAction,
                              'offeredPrice': offeredPrice,
                              'message': _messageController.text.trim().isEmpty
                                  ? null
                                  : _messageController.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(
                            AppLocalizations.of(context)?.send ?? 'إرسال العرض',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
