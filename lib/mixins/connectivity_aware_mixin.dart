import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../screens/no_internet_screen.dart';

/// 🌐 Mixin يضاف على أي StatefulWidget يعمل API calls
/// يراقب الاتصال بالإنترنت ويعيد المحاولة تلقائياً عند رجوع الاتصال
mixin ConnectivityAwareMixin<T extends StatefulWidget> on State<T> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _hasConnection = true;
  bool _wasDisconnected = false;

  /// Override this method في الـ Screen
  /// هذه الدالة تُستدعى:
  /// 1. عند أول تحميل للصفحة
  /// 2. عند رجوع الاتصال بعد فقدانه
  Future<void> fetchData();

  /// دالة اختيارية: تُستدعى عند فقدان الاتصال
  void onConnectionLost() {
    if (mounted) {
      // عرض SnackBar بدلاً من Dialog لتجربة أفضل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// دالة اختيارية: تُستدعى عند رجوع الاتصال
  void onConnectionRestored() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم استعادة الاتصال',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'جاري إعادة تحميل البيانات...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ بدون فحص فوري - نفترض وجود الإنترنت عند البداية
    // سيتم الفحص فقط عند حدوث تغيير فعلي في الاتصال

    // الاستماع للتغييرات
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (hasConnection) {
        if (!mounted) return;

        final hadConnection = _hasConnection;
        _hasConnection = hasConnection;

        if (!hasConnection && hadConnection) {
          // فقدنا الاتصال
          _wasDisconnected = true;
          onConnectionLost();
        } else if (hasConnection && !hadConnection && _wasDisconnected) {
          // رجع الاتصال بعد ما كان مفقود
          onConnectionRestored();

          // إعادة جلب البيانات تلقائياً
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              fetchData();
            }
          });
        }
      },
    );

    // بدء المراقبة (بدون فحص فوري)
    _connectivityService.startMonitoring();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Getter للتحقق من وجود اتصال
  bool get hasConnection => _hasConnection;

  /// Widget helper لعرض error state مع retry
  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    IconData icon = Icons.error_outline,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget helper لعرض no data state
  Widget buildEmptyState({
    required String message,
    IconData icon = Icons.inbox_outlined,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget helper لعرض loading state
  Widget buildLoadingState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🌐 دالة للتحقق من الاتصال قبل تنفيذ أي action
  /// مثال: await executeWithConnectivityCheck(() async { ... });
  Future<void> executeWithConnectivityCheck(
    Future<void> Function() action, {
    bool showLoadingDialog = false,
    String? loadingMessage,
  }) async {
    // فحص الاتصال
    final hasConnection = await _connectivityService.checkConnection();

    if (!mounted) return;

    if (!hasConnection) {
      // عرض صفحة الصاروخ البنفسجي
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoInternetScreen(
            onRetry: () {
              Navigator.of(context).pop();
            },
          ),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    // تنفيذ الـ action
    if (showLoadingDialog) {
      // عرض loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                    if (loadingMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      try {
        await action();
      } finally {
        if (mounted) {
          Navigator.of(context).pop(); // إغلاق loading dialog
        }
      }
    } else {
      await action();
    }
  }

  /// 🌐 دالة للتحقق من الاتصال قبل تنفيذ action مع return value
  /// مثال: final result = await executeWithConnectivityCheckResult(() async { return value; });
  Future<T?> executeWithConnectivityCheckResult<T>(
    Future<T> Function() action, {
    bool showLoadingDialog = false,
    String? loadingMessage,
  }) async {
    // فحص الاتصال
    final hasConnection = await _connectivityService.checkConnection();

    if (!mounted) return null;

    if (!hasConnection) {
      // عرض صفحة الصاروخ البنفسجي
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoInternetScreen(
            onRetry: () {
              Navigator.of(context).pop();
            },
          ),
          fullscreenDialog: true,
        ),
      );
      return null;
    }

    // تنفيذ الـ action
    if (showLoadingDialog) {
      // عرض loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                    if (loadingMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      try {
        final result = await action();
        return result;
      } finally {
        if (mounted) {
          Navigator.of(context).pop(); // إغلاق loading dialog
        }
      }
    } else {
      return await action();
    }
  }
}
