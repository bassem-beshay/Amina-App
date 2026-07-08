import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

/// Widget للتحميل يمكن استخدامه في أي مكان في التطبيق
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final bool showLogo;
  final bool useSkeleton;

  const LoadingWidget({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
    this.showLogo = true,
    this.useSkeleton = true,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام Skeleton Loader بدلاً من CircularProgressIndicator
    if (useSkeleton) {
      return Container(
        color: backgroundColor ?? const Color(0xFFF5F5F5),
        child: const SkeletonScreen(showAppBar: false),
      );
    }

    // النسخة القديمة مع CircularProgressIndicator (للاستخدام النادر)
    return Container(
      color: backgroundColor ?? const Color(0xFF8B5CF6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو (اختياري)
            if (showLogo) ...[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset(
                  'assets/icons/app-icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.home_work,
                      size: 60,
                      color: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],

            // مؤشر التحميل
            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  indicatorColor ?? Colors.white,
                ),
                strokeWidth: 3.5,
              ),
            ),

            // رسالة التحميل (اختيارية)
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: indicatorColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شاشة تحميل كاملة يمكن استخدامها كـ route
class LoadingScreen extends StatefulWidget {
  final String? message;
  final Future<void> Function()? onComplete;
  final VoidCallback? onTimeout;
  final Duration timeout;

  const LoadingScreen({
    super.key,
    this.message,
    this.onComplete,
    this.onTimeout,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // تنفيذ العملية المطلوبة
      if (widget.onComplete != null) {
        await widget.onComplete!().timeout(
          widget.timeout,
          onTimeout: () {
            if (widget.onTimeout != null && mounted) {
              widget.onTimeout!();
            }
          },
        );
      }
    } catch (e) {
      if (widget.onTimeout != null && mounted) {
        widget.onTimeout!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingWidget(
        message: widget.message,
        showLogo: true,
      ),
    );
  }
}

/// Dialog للتحميل يمكن عرضه فوق الشاشة الحالية
class LoadingDialog {
  static void show(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
    bool useSkeleton = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: useSkeleton
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SkeletonCard(height: 60),
                      if (message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // مؤشر التحميل
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 4,
                        ),
                      ),

                      if (message != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Overlay للتحميل يمكن عرضه فوق أي شيء
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    String? message,
    bool showLogo = false,
    bool useSkeleton = true,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: LoadingWidget(
          message: message,
          showLogo: showLogo,
          backgroundColor: Colors.transparent,
          useSkeleton: useSkeleton,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
