import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class AdminRejectedProvidersScreen extends StatefulWidget {
  final String token;
  const AdminRejectedProvidersScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminRejectedProvidersScreenState createState() =>
      _AdminRejectedProvidersScreenState();
}

class _AdminRejectedProvidersScreenState
    extends State<AdminRejectedProvidersScreen> {
  List<Map<String, dynamic>> providers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadRejectedProviders();
  }

  Future<void> loadRejectedProviders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // جلب المزودين المرفوضين فقط
      final response = await ApiClient.get(
        '${ApiConfig.adminProviders}?status=REJECTED',
        needsAuth: true,
      );

      if (response.success) {
        final data = response.rawResponse ?? response.data;

        if (data is List) {
          setState(() {
            providers = data.map((e) => e as Map<String, dynamic>).toList();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.error ?? 'Failed to load providers');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  Future<void> changeProviderStatus(
      Map<String, dynamic> provider, String newStatus) async {
    final userId = provider['user']?['id'];
    if (userId == null) return;

    String statusText = '';
    String endpoint = '';

    if (newStatus == 'VERIFIED') {
      statusText = 'توثيق';
      endpoint = ApiConfig.adminApproveProvider(userId);
    } else if (newStatus == 'PENDING') {
      statusText = 'إعادة للمراجعة';
      // نستخدم reject ثم approve للتغيير للـ PENDING
      endpoint = ApiConfig.adminRejectProvider(userId);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$statusText المزود'),
        content: Text(
            'هل أنت متأكد من $statusText ${provider['user']?['first_name']}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'VERIFIED' ? Colors.green : Colors.orange,
            ),
            child: Text(statusText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.post(
        endpoint,
        needsAuth: true,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم $statusText المزود بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        loadRejectedProviders(); // Reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل $statusText المزود: \u200F${response.error}\u200F'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.rejectedProviders ?? 'المزودين المرفوضين',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadRejectedProviders,
          ),
        ],
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
                        onPressed: loadRejectedProviders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : providers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد مزودين مرفوضين',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadRejectedProviders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: providers.length,
                        itemBuilder: (ctx, index) {
                          final provider = providers[index];
                          return _buildProviderCard(provider);
                        },
                      ),
                    ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final user = provider['user'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundImage: provider['profile_picture_url'] != null
                      ? NetworkImage(provider['profile_picture_url'])
                      : null,
                  child: provider['profile_picture_url'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cancel, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'مرفوض',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User details
            _buildDetailRow(Icons.email, user?['email'] ?? ''),
            _buildDetailRow(Icons.phone, user?['phone_number'] ?? ''),
            if (provider['city'] != null)
              _buildDetailRow(Icons.location_city, provider['city']),
            if (provider['bio'] != null && provider['bio'].toString().isNotEmpty)
              _buildDetailRow(Icons.info_outline, provider['bio']),

            const Divider(height: 24),

            // Action button - توثيق فقط
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ConnectivityIconButton(
                  onPressed: () => changeProviderStatus(provider, 'VERIFIED'),
                  icon: const Icon(Icons.verified),
                  label: const Text('توثيق المزود'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
