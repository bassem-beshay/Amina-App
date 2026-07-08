import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import 'connectivity_button.dart';

/// Helper class للتحقق من اكتمال البيانات قبل الحجز
class ProfileCompletionChecker {
  /// التحقق من وجود رقم هاتف وعنوان للمستخدم
  static Future<Map<String, bool>> checkProfileCompletion() async {
    try {
      // جلب بيانات المستخدم
      final userResponse = await ApiClient.get(
        ApiConfig.me,
        needsAuth: true,
      );

      // جلب بيانات الملف الشخصي للعميل
      final profileResponse = await ApiClient.get(
        ApiConfig.clientProfile,
        needsAuth: true,
      );

      bool hasPhoneNumber = false;
      bool hasAddress = false;

      if (userResponse.success && userResponse.rawResponse != null) {
        final userData = userResponse.rawResponse as Map<String, dynamic>;
        final phoneNumber = userData['phone_number'];
        hasPhoneNumber = phoneNumber != null && phoneNumber.toString().isNotEmpty;
      }

      if (profileResponse.success && profileResponse.rawResponse != null) {
        final profileData = profileResponse.rawResponse as Map<String, dynamic>;
        final addresses = profileData['addresses'] as List?;
        hasAddress = addresses != null && addresses.isNotEmpty;
      }

      return {
        'hasPhoneNumber': hasPhoneNumber,
        'hasAddress': hasAddress,
        'isComplete': hasPhoneNumber && hasAddress,
      };
    } catch (e) {
      return {
        'hasPhoneNumber': false,
        'hasAddress': false,
        'isComplete': false,
      };
    }
  }

  /// عرض رسالة تحذير إذا البيانات ناقصة والتوجيه لشاشة التعديل
  /// Returns: 'complete' إذا البيانات مكتملة، 'go_to_edit' إذا المستخدم اختار التوجيه للتعديل، null إذا ألغى
  static Future<String?> showCompletionDialogIfNeeded(BuildContext context) async {
    final completion = await checkProfileCompletion();

    if (completion['isComplete'] == true) {
      return 'complete'; // البيانات مكتملة
    }

    // تحديد البيانات الناقصة
    final loc = AppLocalizations.of(context);
    final missingItems = <String>[];
    if (!(completion['hasPhoneNumber'] ?? false)) {
      missingItems.add(loc?.phoneNumber ?? 'Phone Number');
    }
    if (!(completion['hasAddress'] ?? false)) {
      missingItems.add(loc?.address ?? 'Address');
    }

    // عرض رسالة تحذير مع خيار التوجيه لشاشة التعديل
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc?.incompleteData ?? 'Incomplete Data',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.completeDataFirst ?? 'To complete the booking, please complete the following data first:',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc?.completeDataHint ?? 'Press "Complete Data" to go to the profile edit page',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(loc?.cancel ?? 'Cancel'),
          ),
          ConnectivityIconButton(
            onPressed: () {
              // نغلق الـ dialog ونرجع "go_to_edit" كإشارة للتوجيه
              Navigator.of(context).pop('go_to_edit');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(
              loc?.completeDataButton ?? 'Complete Data',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return result;
  }
}
