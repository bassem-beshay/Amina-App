import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../screens/no_internet_screen.dart';

/// 🌐 Widget يلف الشاشات ويتحقق من الاتصال بالإنترنت
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();

    // ✅ لا يوجد فحص تلقائي - نفترض وجود الإنترنت
    // الفحص يتم فقط عند الضغط على زر إعادة المحاولة

    // الاستماع للتغييرات (عند الضغط على زر إعادة المحاولة)
    _connectivityService.connectionStream.listen((hasConnection) {
      if (mounted) {
        setState(() {
          _hasConnection = hasConnection;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا مافيش نت → عرض شاشة NoInternet
    if (!_hasConnection) {
      return NoInternetScreen(
        onRetry: () {
          // عند نجاح إعادة الاتصال، نعيد بناء الـ widget
          setState(() {
            _hasConnection = true;
          });
        },
      );
    }

    // إذا في نت → عرض الشاشة العادية
    return widget.child;
  }
}
