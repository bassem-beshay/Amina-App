/// PaySky WebView Payment Screen
/// Displays PaySky payment page in WebView

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/paysky_payment_model.dart';
import '../services/paysky_payment_service.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaySkyWebViewScreen extends StatefulWidget {
  final int bookingId;
  final String amount;
  final String currency;
  final String environment; // 'TESTING' or 'PRODUCTION'
  final String? transactionReference; // Optional: if session already created

  const PaySkyWebViewScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    this.currency = 'EGP',
    this.environment = 'PRODUCTION', // Backend يفرض PRODUCTION دائماً
    this.transactionReference,
  }) : super(key: key);

  @override
  State<PaySkyWebViewScreen> createState() => _PaySkyWebViewScreenState();
}

class _PaySkyWebViewScreenState extends State<PaySkyWebViewScreen> {
  bool _isLoading = true;
  bool _isInitializing = true;
  String? _errorMessage;
  PaySkySessionResponse? _sessionResponse;
  late WebViewController _webViewController;
  double _loadingProgress = 0.0;
  bool _isOnCallbackPage = false; // Flag to track if we're on callback page
  bool _allowAutoClose = false; // Flag to allow auto-close after countdown

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  /// Initialize payment session
  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });


      // Create payment session
      final response = await PaySkyPaymentService.createPaymentSession(
        bookingId: widget.bookingId,
        amount: widget.amount,
        currency: widget.currency,
        environment: widget.environment,
      );

      if (response.success && response.data != null) {

        setState(() {
          _sessionResponse = response.data;
          _isInitializing = false;
        });

        // Initialize WebView
        _initializeWebView();
      } else {
        setState(() {
          _errorMessage = response.error ?? 'فشل في إنشاء جلسة الدفع';
          _isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  /// Initialize WebView controller
  void _initializeWebView() {
    if (_sessionResponse == null || _sessionResponse!.paymentUrl.isEmpty) {
      return;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // تفعيل User Agent مخصص للـ mobile
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) async {

            // Inject JavaScript للتحقق من تحميل PaySky LightBox وتفعيل Fallback
            // تقليل الوقت من 2000ms إلى 500ms لتحسين السرعة
            await _webViewController.runJavaScript('''
              console.log('🔍 Checking PaySky LightBox availability...');

              // الانتظار قليلاً للتأكد من محاولة تحميل الـ script (تم تقليل الوقت من 2000ms إلى 500ms)
              setTimeout(function() {
                // التحقق من وجود LightBox
                if (typeof LightBox === 'undefined') {
                  console.warn('⚠️ PaySky LightBox not loaded - enabling fallback redirect method');

                  // البحث عن زر الدفع وتفعيل Fallback
                  var payButton = document.getElementById('payNowButton');
                  if (payButton) {
                    // تعطيل LightBox وتفعيل Redirect
                    payButton.onclick = function() {
                      console.log('🔄 Using fallback redirect method');
                      var redirectUrl = payButton.getAttribute('data-redirect-url');
                      if (redirectUrl) {
                        window.location.href = redirectUrl;
                      }
                    };
                    console.log('✅ Fallback method activated');
                  }
                } else {
                  console.log('✅ PaySky LightBox loaded successfully');
                }
              }, 500);
            ''');

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // تجاهل أخطاء تحميل PaySky LightBox - سيتم استخدام Fallback
            if (error.url?.contains('paysky.io') == true) {
              return; // لا نعرض رسالة خطأ، الـ Fallback سيتولى الأمر
            }
            // أخطاء أخرى - نعرضها
            if (mounted && !error.url!.contains('paysky.io')) {
              setState(() {
                _errorMessage = 'خطأ في تحميل صفحة الدفع';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {

            // Detect success callback and auto-close after countdown
            if (request.url.contains('/paysky/callback/success')) {
              print('✅ [PaySky] Success callback detected: ${request.url}');

              // Set flag that we're on callback page
              _isOnCallbackPage = true;

              // Allow page to load and display countdown
              // After 10 seconds (matching countdown), close automatically
              Future.delayed(const Duration(seconds: 10), () {
                if (mounted && _isOnCallbackPage) {
                  print('[PaySky] Auto-closing WebView after success (10s)');
                  _allowAutoClose = true;
                  Navigator.pop(context, true); // Close with success result
                }
              });

              return NavigationDecision.navigate; // LOAD the HTML page
            }

            // Detect failure callback and auto-close after countdown
            if (request.url.contains('/paysky/callback/failure')) {
              print('❌ [PaySky] Failure callback detected: ${request.url}');

              // Set flag that we're on callback page
              _isOnCallbackPage = true;

              // Allow page to load and display countdown
              // After 10 seconds (matching countdown), close automatically
              Future.delayed(const Duration(seconds: 10), () {
                if (mounted && _isOnCallbackPage) {
                  print('[PaySky] Auto-closing WebView after failure (10s)');
                  _allowAutoClose = true;
                  Navigator.pop(context, false); // Close with failure result
                }
              });

              return NavigationDecision.navigate; // LOAD the HTML page
            }

            // Reset flag if navigating away from callback page
            _isOnCallbackPage = false;

            // Allow other navigations
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'paymentSuccess',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptSuccess(message.message);
        },
      )
      ..addJavaScriptChannel(
        'paymentFailure',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptFailure(message.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('📨 [PaySky] Received message from WebView: ${message.message}');

          // If we're on callback page and countdown hasn't finished, ignore early close attempts
          if (_isOnCallbackPage && !_allowAutoClose) {
            print('⏱️ [PaySky] Ignoring early close - countdown still running');
            return;
          }

          // Handle payment result from callback page close button
          try {
            final data = message.message;

            // Check if it's payment result JSON
            if (data.contains('transaction_reference') || data.contains('status')) {
              print('✅ [PaySky] Payment result received, closing WebView');

              // Determine if success or failure
              final isSuccess = data.contains('"status":"COMPLETED"') ||
                                data.contains('"status": "COMPLETED"');

              if (mounted) {
                // Close WebView and return result
                Navigator.pop(context, isSuccess);
              }
            }
          } catch (e) {
            print('⚠️ [PaySky] Error parsing message: $e');
          }
        },
      )
      ..loadRequest(Uri.parse(_sessionResponse!.paymentUrl));

    setState(() {});
  }

  /// Handle payment success from URL callback
  void _handlePaymentSuccess(String url) async {

    try {
      // Parse query parameters
      final uri = Uri.parse(url);
      final systemReference = uri.queryParameters['SystemReference'];
      final networkReference = uri.queryParameters['NetworkReference'];
      final actionCode = uri.queryParameters['ActionCode'];


      // Navigate directly to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaymentSuccessScreen(
              amount: widget.amount,
              transactionReference: _sessionResponse?.transactionReference,
              systemReference: systemReference,
              onContinue: () {
                Navigator.pop(context, true); // Return to previous screen with success
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء معالجة الدفع');
    }
  }

  /// Handle payment failure from URL callback
  void _handlePaymentFailure(String url) {

    final uri = Uri.parse(url);
    final message = uri.queryParameters['Message'] ?? 'فشل الدفع';
    final actionCode = uri.queryParameters['ActionCode'];


    // Navigate directly to failure screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PaymentFailureScreen(
            errorMessage: message,
            onRetry: () {
              Navigator.pop(context); // Go back and retry
              _initializePayment();
            },
            onCancel: () {
              Navigator.pop(context, false); // Return to previous screen with failure
            },
          ),
        ),
      );
    }
  }

  /// Handle success from JavaScript channel
  void _handleJavaScriptSuccess(String message) async {

    try {
      // Navigate directly to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaymentSuccessScreen(
              amount: widget.amount,
              transactionReference: _sessionResponse?.transactionReference,
              onContinue: () {
                Navigator.pop(context, true); // Return to previous screen with success
              },
            ),
          ),
        );
      }
    } catch (e) {
    }
  }

  /// Handle failure from JavaScript channel
  void _handleJavaScriptFailure(String message) {

    // Navigate directly to failure screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PaymentFailureScreen(
            errorMessage: 'فشل الدفع',
            onRetry: () {
              Navigator.pop(context); // Go back and retry
              _initializePayment();
            },
            onCancel: () {
              Navigator.pop(context, false); // Return to previous screen with failure
            },
          ),
        ),
      );
    }
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري التحقق من الدفع...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show success screen and close
  void _showSuccessAndClose() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaymentSuccessScreen(
          amount: widget.amount,
          onContinue: () {
            Navigator.pop(context); // Close success screen
          },
        ),
      ),
    );

    // Close WebView with success
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  /// Show error screen
  void _showErrorDialog(String message) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaymentFailureScreen(
          errorMessage: message,
          onRetry: () {
            Navigator.pop(context); // Close failure screen
            _initializePayment(); // Retry payment
          },
          onCancel: () {
            Navigator.pop(context); // Close failure screen
          },
        ),
      ),
    );

    // Close WebView with failure
    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Confirm before closing
          final shouldClose = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('تأكيد الإلغاء'),
              content: const Text('هل تريد إلغاء عملية الدفع؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('لا'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('نعم، إلغاء'),
                ),
              ],
            ),
          );

          if (shouldClose == true && context.mounted) {
            Navigator.pop(context, false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
            onPressed: () async {
              final shouldClose = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('تأكيد الإلغاء'),
                  content: const Text('هل تريد إلغاء عملية الدفع؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('لا'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                      child: const Text('نعم، إلغاء'),
                    ),
                  ],
                ),
              );

              if (shouldClose == true && mounted) {
                Navigator.pop(context, false);
              }
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Show error if any
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializePayment,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      );
    }

    // Show initializing loader
    if (_isInitializing) {
      return Center(
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
              'جاري تحضير صفحة الدفع...',
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
          ],
        ),
      );
    }

    // Show WebView
    if (_sessionResponse != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading || _loadingProgress < 1.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return const Center(child: Text('خطأ في تحميل الصفحة'));
  }
}
