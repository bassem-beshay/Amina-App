

/// Payment Polling Service
/// Polls backend to check payment status while Custom Tabs is open

import 'dart:async';
import '../services/paysky_payment_service.dart';
import '../models/paysky_payment_model.dart';

class PaymentPollingService {
  static Timer? _pollingTimer;
  static Completer<PaySkyPaymentStatus>? _statusCompleter;

  /// Start polling for payment status
  ///
  /// Polls every 3 seconds for up to 10 minutes
  /// Returns when payment is completed or timeout
  static Future<PaySkyPaymentStatus?> startPolling({
    required String transactionReference,
    Duration pollingInterval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    // Create completer
    _statusCompleter = Completer<PaySkyPaymentStatus>();

    // Start polling timer
    var pollCount = 0;
    final maxPolls = timeout.inSeconds ~/ pollingInterval.inSeconds;

    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      pollCount++;

      try {
        // Query payment status
        final response = await PaySkyPaymentService.getPaymentStatus(
          transactionReference,
        );

        if (response.success && response.data != null) {
          final status = response.data!;


          // Check if payment is completed (success or failure)
          if (status.isCompleted || status.isFailed) {
            stopPolling();
            if (!_statusCompleter!.isCompleted) {
              _statusCompleter!.complete(status);
            }
            return;
          }

          // Check if still pending
          if (status.isPending) {
          }
        } else {
        }

        // Check if timeout reached
        if (pollCount >= maxPolls) {
          stopPolling();
          if (!_statusCompleter!.isCompleted) {
            _statusCompleter!.completeError('Timeout: Payment status unknown');
          }
        }
      } catch (e) {
      }
    });


    try {
      // Wait for completion or timeout
      final result = await _statusCompleter!.future;
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (_statusCompleter != null && !_statusCompleter!.isCompleted) {
      _statusCompleter!.completeError('Polling stopped manually');
    }
    _statusCompleter = null;
  }
}
