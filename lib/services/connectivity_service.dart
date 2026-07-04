import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 🌐 خدمة فحص الاتصال بالإنترنت
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream للاستماع لتغييرات الاتصال
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  /// ❌ تم إزالة الفحص التلقائي - الفحص يتم فقط عند الضغط على زر إعادة المحاولة

  /// بدء المراقبة - معطلة (لا يوجد فحص تلقائي)
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    // ❌ لا يوجد فحص تلقائي - الفحص يتم فقط عند الضغط على الزر
  }

  /// إيقاف المراقبة - معطلة
  void stopMonitoring() {
    // ❌ لا يوجد شيء لإيقافه
  }

  /// فحص الاتصال بالإنترنت
  Future<bool> checkConnection() async {
    bool previousConnection = _hasConnection;

    try {
      // محاولة الاتصال بـ Google DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _hasConnection = false;
    } on TimeoutException catch (_) {
      _hasConnection = false;
    } catch (e) {
      _hasConnection = false;
      if (kDebugMode) {
        print('❌ Connectivity Check Error: $e');
      }
    }

    // إرسال تحديث فقط إذا تغيرت الحالة
    if (previousConnection != _hasConnection) {
      _connectionController.add(_hasConnection);
      if (kDebugMode) {
        print(_hasConnection ? '✅ Internet Connected' : '❌ Internet Disconnected');
      }
    }

    return _hasConnection;
  }

  /// التخلص من الموارد
  void dispose() {
    _connectionController.close();
  }
}
