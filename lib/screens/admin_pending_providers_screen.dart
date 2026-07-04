import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';
import 'document_viewer_screen.dart';

class AdminPendingProvidersScreen extends StatefulWidget {
  final String token;
  const AdminPendingProvidersScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminPendingProvidersScreenState createState() =>
      _AdminPendingProvidersScreenState();
}

class _AdminPendingProvidersScreenState
    extends State<AdminPendingProvidersScreen> {
  List<Map<String, dynamic>> pendingProviders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadPendingProviders();
  }

  Future<void> loadPendingProviders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      final resp = await ApiClient.get(
        '${ApiConfig.adminProviders}?status=PENDING',
        needsAuth: true,
      );

      if (resp.success && resp.rawResponse != null) {
        final List<dynamic> data = resp.rawResponse as List<dynamic>;

        setState(() {
          pendingProviders = data.map((item) {
            final provider = item as Map<String, dynamic>;
            final user = provider['user'] as Map<String, dynamic>?;

            // Flatten the structure for easier access
            return {
              'id': provider['id'],
              'user_id': user?['id'] ?? provider['user'],
              'first_name': user?['first_name'] ?? '',
              'last_name': user?['last_name'] ?? '',
              'email': user?['email'] ?? '',
              'phone_number': user?['phone_number'] ?? '',
              'bio': provider['bio'] ?? '',
              'profile_picture_url': provider['profile_picture_url'],
              'identity_document_url': provider['identity_document_url'],
              'health_certificate_url': provider['health_certificate_url'],
              'verification_status': provider['verification_status'],
              'average_rating': provider['average_rating'] ?? 0.0,
              'total_ratings': provider['total_ratings'] ?? 0,
              'completed_jobs': provider['completed_jobs'] ?? 0,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception(resp.error ?? 'Failed to load providers');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  Future<void> approveProvider(int userId) async {
    try {
      final resp = await ApiClient.post(
        ApiConfig.adminApproveProvider(userId),
        needsAuth: true,
      );

      if (resp.success) {

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('تم قبول المزود بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // إزالة من القائمة
        setState(() {
          pendingProviders.removeWhere((p) => p['user_id'] == userId);
        });
      } else {
        throw Exception(resp.error ?? 'Failed to approve provider');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> rejectProvider(int userId) async {
    try {
      final resp = await ApiClient.post(
        ApiConfig.adminRejectProvider(userId),
        needsAuth: true,
      );

      if (resp.success) {

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.white),
                  SizedBox(width: 12),
                  Text('تم رفض المزود'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        // إزالة من القائمة
        setState(() {
          pendingProviders.removeWhere((p) => p['user_id'] == userId);
        });
      } else {
        throw Exception(resp.error ?? 'Failed to reject provider');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(
          AppLocalizations.of(context)?.reviewProviders ?? 'مراجعة مزودي الخدمة',
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage),
                      const SizedBox(height: 16),
                      ConnectivityIconButton(
                        onPressed: loadPendingProviders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : pendingProviders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات قيد المراجعة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadPendingProviders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingProviders.length,
                        itemBuilder: (context, index) {
                          final provider = pendingProviders[index];
                          return _buildProviderCard(provider);
                        },
                      ),
                    ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange[100],
                  child: Text(
                    provider['first_name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider['first_name']} ${provider['last_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider['email'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty,
                          size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'قيد المراجعة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // معلومات التواصل
            _buildInfoRow(Icons.phone, provider['phone_number']),
            const SizedBox(height: 8),

            if (provider['bio'] != null && provider['bio'].isNotEmpty) ...[
              _buildInfoRow(Icons.info_outline, provider['bio']),
              const SizedBox(height: 12),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // الوثائق
            const Text(
              'الوثائق المرفوعة:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDocumentButton(
                    title: 'وثيقة الهوية',
                    icon: Icons.badge,
                    color: Colors.blue,
                    docUrl: provider['identity_document_url'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDocumentButton(
                    title: 'الشهادة الصحية',
                    icon: Icons.medical_information,
                    color: Colors.green,
                    docUrl: provider['health_certificate_url'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // أزرار القبول والرفض
            Row(
              children: [
                Expanded(
                  child: ConnectivityIconButton(
                    onPressed: () => _showRejectDialog(provider['user_id']),
                    icon: const Icon(Icons.cancel),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConnectivityIconButton(
                    onPressed: () => _showApproveDialog(provider['user_id']),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentButton({
    required String title,
    required IconData icon,
    required Color color,
    String? docUrl,
  }) {
    final bool hasDoc = docUrl != null && docUrl.isNotEmpty;

    return ConnectivityButton(
      onPressed: hasDoc
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => DocumentViewerScreen(
                    documentUrl: docUrl,
                    title: title,
                  ),
                ),
              );
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasDoc ? color.withOpacity( 0.1) : Colors.grey[200],
        foregroundColor: hasDoc ? color : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: hasDoc ? color : Colors.grey[400]!,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveDialog(int providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('قبول المزود'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من قبول هذا المزود؟\nسيتمكن من تقديم خدماته للعملاء.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await approveProvider(providerId);
    }
  }

  Future<void> _showRejectDialog(int providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('رفض المزود'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رفض هذا المزود؟\nسيتم إخطاره بالرفض ويمكنه إعادة رفع الوثائق.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await rejectProvider(providerId);
    }
  }
}
