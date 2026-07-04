import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class AdminVerifiedProvidersScreen extends StatefulWidget {
  final String token;
  const AdminVerifiedProvidersScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminVerifiedProvidersScreenState createState() =>
      _AdminVerifiedProvidersScreenState();
}

class _AdminVerifiedProvidersScreenState
    extends State<AdminVerifiedProvidersScreen> {
  List<Map<String, dynamic>> providers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadVerifiedProviders();
  }

  Future<void> loadVerifiedProviders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // جلب المزودين الموثقين فقط
      final response = await ApiClient.get(
        '${ApiConfig.adminProviders}?status=VERIFIED',
        needsAuth: true,
      );

      if (response.success) {
        final data = response.rawResponse ?? response.data;
        if (data is List) {
          setState(() {
            providers = List<Map<String, dynamic>>.from(data);
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
    try {
      final userName =
          '${provider['user']['first_name']} ${provider['user']['last_name']}';

      // تأكيد الرفض
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('تأكيد الرفض'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رفض توثيق "$userName"؟',
            style: const TextStyle(fontSize: 16),
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
              child: const Text('رفض التوثيق'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // تغيير الحالة إلى مرفوض
      final userId = provider['user']['id'];
      final response = await ApiClient.post(
        ApiConfig.adminRejectProvider(userId),
        needsAuth: true,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض توثيق "$userName" بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // إعادة تحميل القائمة
        loadVerifiedProviders();
      } else {
        throw Exception(response.error ?? 'فشل في تغيير الحالة');
      }
    } catch (e) {
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
        backgroundColor: Colors.green,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.verifiedProviders ?? 'المزودين الموثقين',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadVerifiedProviders,
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
                        onPressed: loadVerifiedProviders,
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
                        children: const [
                          Icon(Icons.verified_user,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد مزودين موثقين',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadVerifiedProviders,
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
                          Icon(Icons.verified, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'موثق',
                            style: TextStyle(
                              color: Colors.green,
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

            // Action button - رفض التوثيق
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ConnectivityIconButton(
                  onPressed: () => changeProviderStatus(provider, 'REJECTED'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('رفض التوثيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
