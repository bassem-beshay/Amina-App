import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Widget لعرض ملاحظة رسوم بوابة الدفع بشكل احترافي
/// يعرض أن هناك خصم 15% رسوم بوابة الدفع
class PaymentFeeNotice extends StatelessWidget {
  final double? amount;
  final bool showCalculation;
  final bool compact;

  const PaymentFeeNotice({
    Key? key,
    this.amount,
    this.showCalculation = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _buildCompactNotice(isDark, context);
    }

    return _buildFullNotice(isDark, context);
  }

  Widget _buildCompactNotice(bool isDark, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withOpacity(isDark ? 0.15 : 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              localizations?.translate('paymentFeeDeductionShort') ?? 'يتم خصم 15% رسوم بوابة الدفع',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullNotice(bool isDark, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currency = localizations?.translate('currency') ?? 'جنيه';
    final feePercentage = 0.15;
    final feeAmount = amount != null ? amount! * feePercentage : null;
    final netAmount = amount != null ? amount! - feeAmount! : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF78350F).withOpacity(0.3),
                  const Color(0xFF451A03).withOpacity(0.2),
                ]
              : [
                  const Color(0xFFFEF3C7),
                  const Color(0xFFFDE68A).withOpacity(0.5),
                ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 8,
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
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.translate('paymentGatewayFee') ?? 'رسوم بوابة الدفع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations?.translate('paymentFeeDeduction') ?? 'يتم خصم 15% من إجمالي المبلغ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber[200] : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '15%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          if (showCalculation && amount != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildCalculationRow(
                    localizations?.translate('totalAmount') ?? 'المبلغ الإجمالي',
                    '${amount!.toStringAsFixed(0)} $currency',
                    isDark,
                    isTotal: false,
                  ),
                  const SizedBox(height: 8),
                  _buildCalculationRow(
                    localizations?.translate('gatewayFee') ?? 'رسوم البوابة (15%)',
                    '- ${feeAmount!.toStringAsFixed(0)} $currency',
                    isDark,
                    isDeduction: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      thickness: 1,
                    ),
                  ),
                  _buildCalculationRow(
                    localizations?.translate('netAmountDue') ?? 'صافي المبلغ المستحق',
                    '${netAmount!.toStringAsFixed(0)} $currency',
                    isDark,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, bool isDark, {bool isTotal = false, bool isDeduction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDark
                ? (isTotal ? Colors.white : Colors.grey[400])
                : (isTotal ? const Color(0xFF1F2937) : Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isDeduction
                ? Colors.red[400]
                : (isTotal
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white : const Color(0xFF1F2937))),
          ),
        ),
      ],
    );
  }
}

/// Widget بسيط لعرض رسالة الرسوم في سطر واحد
class PaymentFeeInline extends StatelessWidget {
  const PaymentFeeInline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: isDark ? Colors.amber[300] : Colors.amber[700],
        ),
        const SizedBox(width: 4),
        Text(
          localizations?.translate('paymentFeeDeductionFromAmount') ?? 'يتم خصم 15% رسوم بوابة الدفع من المبلغ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.amber[300] : Colors.amber[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
