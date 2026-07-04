/// PaySky Payment Dialog with iframe
/// Opens payment form in a dialog overlay with iframe for better integration

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../services/paysky_payment_service.dart';
import '../services/payment_polling_service.dart';
import '../models/paysky_payment_model.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaySkyIframeDialog {
  /// Show PaySky payment in a full-screen dialog with iframe
  static Future<PaySkyPaymentResult?> show({
    required BuildContext context,
    required int bookingId,
    required String amount,
    String currency = 'EGP',
    String environment = 'PRODUCTION',
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    try {
      // Step 1: Create payment session
      final response = await PaySkyPaymentService.createPaymentSession(
        bookingId: bookingId,
        amount: amount,
        currency: currency,
        environment: environment,
      );

      if (!response.success || response.data == null) {

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

      // Build the correct payment form URL (LightBox HTML page)
      // Use the backend HTML page that loads LightBox, not the direct redirect URL
      final paymentFormUrl = sessionData.getPaymentFormUrl('https://amina.bdcbiz.com');

      // Step 2: Show dialog with iframe

      if (!context.mounted) return null;

      // Show the iframe full screen
      final dialogCompleter = Completer<void>();

      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (dialogContext) => _PaySkyIframeDialogContent(
            paymentUrl: paymentFormUrl, // Use LightBox HTML page URL
            transactionReference: sessionData.transactionReference,
            onDismiss: () {
              if (!dialogCompleter.isCompleted) {
                dialogCompleter.complete();
              }
            },
          ),
        ),
      );

      // Step 3: Start polling for payment status

      try {
        final paymentStatus = await PaymentPollingService.startPolling(
          transactionReference: sessionData.transactionReference,
          pollingInterval: const Duration(seconds: 3),
          timeout: const Duration(minutes: 10),
        );

        // Close dialog when polling completes
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (!dialogCompleter.isCompleted) {
          dialogCompleter.complete();
        }

        if (paymentStatus == null) {
          return PaySkyPaymentResult.failure(
            transactionReference: sessionData.transactionReference,
            message: 'انتهت مهلة الدفع أو تم الإلغاء',
          );
        }


        if (paymentStatus.isSuccessful) {
          // Mark payment as completed to update booking status to PAYMENT_COMPLETED
          // This enables the "Start Service" button for the provider
          await PaySkyPaymentService.markPaymentCompleted(
            transactionReference: paymentStatus.transactionReference,
          );

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

        // Close dialog on error
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        return PaySkyPaymentResult.failure(
          transactionReference: sessionData.transactionReference,
          message: 'حدث خطأ أثناء التحقق من الدفع',
        );
      }
    } catch (e, stackTrace) {

      if (context.mounted) {
        _showErrorDialog(context, 'حدث خطأ: ${e.toString()}');
      }

      return PaySkyPaymentResult.failure(
        transactionReference: '',
        message: e.toString(),
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
}

/// Dialog content widget with WebView iframe
class _PaySkyIframeDialogContent extends StatefulWidget {
  final String paymentUrl;
  final String transactionReference;
  final VoidCallback onDismiss;

  const _PaySkyIframeDialogContent({
    required this.paymentUrl,
    required this.transactionReference,
    required this.onDismiss,
  });

  @override
  State<_PaySkyIframeDialogContent> createState() =>
      _PaySkyIframeDialogContentState();
}

class _PaySkyIframeDialogContentState
    extends State<_PaySkyIframeDialogContent> {
  late WebViewController _webViewController;
  bool _isLoading = false; // No loading screen - show payment page immediately

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
          },
          onNavigationRequest: (NavigationRequest request) {

            // Allow all navigation within payment flow
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () {
            // Simply close the dialog and return to chat screen
            // No countdown, no failure page - just go back
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'إتمام الدفع',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // WebView - Full Screen
            WebViewWidget(controller: _webViewController),

            // Beautiful loading overlay
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated payment icon
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          size: 60,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'جاري تحميل صفحة الدفع...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى الانتظار قليلاً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Security badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'دفع آمن ومشفر',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

/// Fullscreen page that shows failure callback with countdown
class _FailureCountdownPage extends StatefulWidget {
  final String url;

  const _FailureCountdownPage({required this.url});

  @override
  State<_FailureCountdownPage> createState() => _FailureCountdownPageState();
}

class _FailureCountdownPageState extends State<_FailureCountdownPage> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) {
          },
          onWebResourceError: (WebResourceError error) {
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
