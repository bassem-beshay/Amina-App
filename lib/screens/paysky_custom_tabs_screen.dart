/// PaySky Custom Tabs Payment Screen
/// Uses Custom Tabs (Chrome Custom Tabs / SFSafariViewController)
/// for better payment experience and full browser support

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'dart:async';
import '../services/paysky_payment_service.dart';
import '../services/payment_polling_service.dart';
import '../models/paysky_payment_model.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaySkyCustomTabsScreen {
  /// Completer to handle payment result from deep link
  static Completer<PaySkyPaymentResult>? _paymentCompleter;
  static String? _currentTransactionReference;

  /// Open PaySky payment in Custom Tabs
  ///
  /// This method will:
  /// 1. Create payment session via API
  /// 2. Open payment URL in Custom Tabs (Chrome/Safari)
  /// 3. Wait for user to complete payment
  /// 4. Return when deep link callback is received
  ///
  /// Returns PaySkyPaymentResult with success/failure
  static Future<PaySkyPaymentResult?> openPayment({
    required BuildContext context,
    required int bookingId,
    required String amount,
    String currency = 'EGP',
    String environment = 'TESTING',
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF4F46E5),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'جاري تحضير صفحة الدفع...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Step 1: Create payment session
      final response = await PaySkyPaymentService.createPaymentSession(
        bookingId: bookingId,
        amount: amount,
        currency: currency,
        environment: environment,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (!response.success || response.data == null) {

        // Show error dialog
        if (context.mounted) {
          _showErrorDialog(
            context,
            response.error ?? 'فشل في إنشاء جلسة الدفع',
          );
        }
        return PaySkyPaymentResult.failure(
          transactionReference: '',
          message: response.error ?? 'فشل في إنشاء جلسة الدفع',
        );
      }

      final sessionData = response.data!;
      _currentTransactionReference = sessionData.transactionReference;


      // Build the correct payment form URL (LightBox HTML page)
      final paymentFormUrl = sessionData.getPaymentFormUrl('https://amina.bdcbiz.com');

      // Step 2: Open payment URL in Custom Tabs & Start polling

      try {
        // Launch Custom Tabs (non-blocking)
        launchUrl(
          Uri.parse(paymentFormUrl),
          customTabsOptions: CustomTabsOptions(
            colorSchemes: CustomTabsColorSchemes.defaults(
              toolbarColor: const Color(0xFF4F46E5),
            ),
            shareState: CustomTabsShareState.off,
            urlBarHidingEnabled: true,
            showTitle: true,
            closeButton: CustomTabsCloseButton(
              icon: CustomTabsCloseButtonIcons.back,
            ),
          ),
          safariVCOptions: SafariViewControllerOptions(
            preferredBarTintColor: const Color(0xFF4F46E5),
            preferredControlTintColor: Colors.white,
            barCollapsingEnabled: true,
            dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
          ),
        );

      } catch (e) {

        if (context.mounted) {
          _showErrorDialog(context, 'فشل في فتح صفحة الدفع');
        }
        return PaySkyPaymentResult.failure(
          transactionReference: sessionData.transactionReference,
          message: 'فشل في فتح صفحة الدفع',
        );
      }

      // Step 3: Start polling for payment status

      try {
        final paymentStatus = await PaymentPollingService.startPolling(
          transactionReference: sessionData.transactionReference,
          pollingInterval: const Duration(seconds: 3),
          timeout: const Duration(minutes: 10),
        );

        if (paymentStatus == null) {
          return PaySkyPaymentResult.failure(
            transactionReference: sessionData.transactionReference,
            message: 'انتهت مهلة الدفع أو تم الإلغاء',
          );
        }


        if (paymentStatus.isSuccessful) {
          // Show success screen
          if (context.mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PaymentSuccessScreen(
                  transactionReference: paymentStatus.transactionReference,
                  amount: paymentStatus.amount,
                  systemReference: paymentStatus.systemReference,
                  onContinue: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }

          return PaySkyPaymentResult.success(
            transactionReference: paymentStatus.transactionReference,
            systemReference: paymentStatus.systemReference,
            networkReference: paymentStatus.networkReference,
          );
        } else {
          // Show failure screen
          if (context.mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PaymentFailureScreen(
                  errorMessage: paymentStatus.message ?? 'فشل الدفع',
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }

          return PaySkyPaymentResult.failure(
            transactionReference: paymentStatus.transactionReference,
            message: paymentStatus.message ?? 'فشل الدفع',
          );
        }
      } catch (e) {
        return PaySkyPaymentResult.failure(
          transactionReference: sessionData.transactionReference,
          message: 'حدث خطأ أثناء التحقق من الدفع',
        );
      }
    } catch (e, stackTrace) {

      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }

      if (context.mounted) {
        _showErrorDialog(context, 'حدث خطأ: ${e.toString()}');
      }

      return PaySkyPaymentResult.failure(
        transactionReference: '',
        message: e.toString(),
      );
    }
  }

  /// Handle payment callback from deep link
  ///
  /// This is called by main.dart when app receives deep link
  static void handlePaymentCallback({
    required bool isSuccess,
    required Map<String, String> queryParameters,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    if (_paymentCompleter == null || _paymentCompleter!.isCompleted) {
      return;
    }

    final transactionReference = queryParameters['MerchantReference'] ??
        queryParameters['transaction_reference'] ??
        _currentTransactionReference ??
        '';


    if (isSuccess) {
      final systemReference = queryParameters['SystemReference'];
      final networkReference = queryParameters['NetworkReference'];
      final actionCode = queryParameters['ActionCode'];
      final message = queryParameters['Message'];


      // Complete with success result
      _paymentCompleter!.complete(
        PaySkyPaymentResult.success(
          transactionReference: transactionReference,
          systemReference: systemReference,
          networkReference: networkReference,
        ),
      );
    } else {
      final message = queryParameters['Message'] ?? 'فشل الدفع';

      // Complete with failure result
      _paymentCompleter!.complete(
        PaySkyPaymentResult.failure(
          transactionReference: transactionReference,
          message: message,
        ),
      );
    }

  }

  /// Show error screen
  static void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaymentFailureScreen(
          errorMessage: message,
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Verify payment completion on backend
  ///
  /// Called after successful callback to double-check with backend
  static Future<bool> verifyPaymentCompletion(
    String transactionReference,
  ) async {
    final timestamp = DateTime.now().toIso8601String();

    try {
      final isVerified = await PaySkyPaymentService.verifyPaymentCompletion(
        transactionReference,
      );

      if (isVerified) {
      } else {
      }

      return isVerified;
    } catch (e) {
      return false;
    }
  }

  /// Cancel active payment session
  static void cancelPayment() {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(
        PaySkyPaymentResult.failure(
          transactionReference: _currentTransactionReference ?? '',
          message: 'تم إلغاء الدفع',
        ),
      );
    }
    _paymentCompleter = null;
    _currentTransactionReference = null;
  }
}
