import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../screens/no_internet_screen.dart';

/// 🌐 Widget للأزرار مع فحص الاتصال التلقائي
/// يفحص الاتصال قبل تنفيذ أي action ويعرض صفحة الصاروخ البنفسجي إذا لم يكن هناك اتصال

class ConnectivityButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool checkConnectivity;
  final String? loadingMessage;

  const ConnectivityButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.checkConnectivity = true,
    this.loadingMessage,
  });

  Future<void> _handlePress(BuildContext context) async {
    if (onPressed == null) return;

    if (!checkConnectivity) {
      onPressed!();
      return;
    }

    // فحص الاتصال
    final hasConnection = await ConnectivityService().checkConnection();

    if (!context.mounted) return;

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
    } else {
      // تنفيذ الـ action
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null ? null : () => _handlePress(context),
      style: style,
      child: child,
    );
  }
}

/// 🌐 Widget للأزرار مع أيقونة + فحص الاتصال
class ConnectivityIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final ButtonStyle? style;
  final bool checkConnectivity;

  const ConnectivityIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.style,
    this.checkConnectivity = true,
  });

  Future<void> _handlePress(BuildContext context) async {
    if (onPressed == null) return;

    if (!checkConnectivity) {
      onPressed!();
      return;
    }

    // فحص الاتصال
    final hasConnection = await ConnectivityService().checkConnection();

    if (!context.mounted) return;

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
    } else {
      // تنفيذ الـ action
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed == null ? null : () => _handlePress(context),
      icon: icon,
      label: label,
      style: style,
    );
  }
}

/// 🌐 Widget للأزرار النصية مع فحص الاتصال
class ConnectivityTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool checkConnectivity;

  const ConnectivityTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.checkConnectivity = true,
  });

  Future<void> _handlePress(BuildContext context) async {
    if (onPressed == null) return;

    if (!checkConnectivity) {
      onPressed!();
      return;
    }

    // فحص الاتصال
    final hasConnection = await ConnectivityService().checkConnection();

    if (!context.mounted) return;

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
    } else {
      // تنفيذ الـ action
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null ? null : () => _handlePress(context),
      style: style,
      child: child,
    );
  }
}

/// 🌐 Widget للأزرار العائمة مع فحص الاتصال
class ConnectivityFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool checkConnectivity;

  const ConnectivityFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.checkConnectivity = true,
  });

  Future<void> _handlePress(BuildContext context) async {
    if (onPressed == null) return;

    if (!checkConnectivity) {
      onPressed!();
      return;
    }

    // فحص الاتصال
    final hasConnection = await ConnectivityService().checkConnection();

    if (!context.mounted) return;

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
    } else {
      // تنفيذ الـ action
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed == null ? null : () => _handlePress(context),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      child: child,
    );
  }
}

/// 🌐 دالة helper للتحقق من الاتصال قبل تنفيذ أي action
///
/// مثال للاستخدام:
/// ```dart
/// onPressed: () => checkConnectivityBeforeAction(
///   context,
///   action: () async {
///     // كود الـ API call هنا
///   },
/// ),
/// ```
Future<void> checkConnectivityBeforeAction(
  BuildContext context, {
  required Future<void> Function() action,
  bool showLoading = false,
  String? loadingMessage,
}) async {
  // فحص الاتصال
  final hasConnection = await ConnectivityService().checkConnection();

  if (!context.mounted) return;

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
  } else {
    // تنفيذ الـ action
    if (showLoading) {
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
        if (context.mounted) {
          Navigator.of(context).pop(); // إغلاق loading dialog
        }
      }
    } else {
      await action();
    }
  }
}

/// 🌐 Widget Wrapper يضيف فحص الاتصال لأي Widget قابل للضغط
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool checkConnectivity;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.checkConnectivity = true,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (onTap == null) return;

    if (!checkConnectivity) {
      onTap!();
      return;
    }

    // فحص الاتصال
    final hasConnection = await ConnectivityService().checkConnection();

    if (!context.mounted) return;

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
    } else {
      // تنفيذ الـ action
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: child,
    );
  }
}
