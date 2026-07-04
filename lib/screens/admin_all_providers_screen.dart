import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';

class AdminAllProvidersScreen extends StatefulWidget {
  final String token;
  const AdminAllProvidersScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminAllProvidersScreenState createState() =>
      _AdminAllProvidersScreenState();
}

class _AdminAllProvidersScreenState extends State<AdminAllProvidersScreen> {
  List<Map<String, dynamic>> providers = [];
  List<Map<String, dynamic>> filteredProviders = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedFilter = 'all'; // all, verified, pending, rejected, active, inactive

  @override
  void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // جلب جميع مزودي الخدمة
      final response = await ApiClient.get(
        ApiConfig.adminProviders,
        needsAuth: true,
      );

      if (response.success) {
        final data = response.rawResponse ?? response.data;

        if (data is List) {
          setState(() {
            providers = data.map((e) => e as Map<String, dynamic>).toList();
            filteredProviders = List.from(providers);
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

  void applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      if (filter == 'all') {
        filteredProviders = List.from(providers);
      } else if (filter == 'verified') {
        filteredProviders = providers
            .where((p) => p['verification_status'] == 'VERIFIED')
            .toList();
      } else if (filter == 'pending') {
        filteredProviders = providers
            .where((p) => p['verification_status'] == 'PENDING')
            .toList();
      } else if (filter == 'rejected') {
        filteredProviders = providers
            .where((p) => p['verification_status'] == 'REJECTED')
            .toList();
      } else if (filter == 'active') {
        filteredProviders = providers
            .where((p) => p['user']?['is_active'] == true)
            .toList();
      } else if (filter == 'inactive') {
        filteredProviders = providers
            .where((p) => p['user']?['is_active'] == false)
            .toList();
      }
    });
  }

  Future<void> toggleProviderActive(Map<String, dynamic> provider) async {
    final userId = provider['user']?['id'];
    if (userId == null) return;

    final isActive = provider['user']?['is_active'] ?? false;
    final action = isActive ? 'تعطيل' : 'تفعيل';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action الحساب'),
        content: Text('هل أنت متأكد من $action حساب ${provider['user']?['first_name']}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.post(
        ApiConfig.adminToggleProviderActive(userId),
        needsAuth: true,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.rawResponse?['message'] ?? 'تم $action الحساب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        loadProviders(); // Reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل $action الحساب: \u200F${response.error}\u200F'),
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
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          'إدارة مزودي الخدمة',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadProviders,
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
                        onPressed: loadProviders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('الكل', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('موثق', 'verified'),
                            const SizedBox(width: 8),
                            _buildFilterChip('قيد المراجعة', 'pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('مرفوض', 'rejected'),
                            const SizedBox(width: 8),
                            _buildFilterChip('نشط', 'active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('معطل', 'inactive'),
                          ],
                        ),
                      ),
                    ),

                    // Providers list
                    Expanded(
                      child: filteredProviders.isEmpty
                          ? const Center(
                              child: Text('لا توجد نتائج'),
                            )
                          : RefreshIndicator(
                              onRefresh: loadProviders,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredProviders.length,
                                itemBuilder: (ctx, index) {
                                  final provider = filteredProviders[index];
                                  return _buildProviderCard(provider);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => applyFilter(value),
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final user = provider['user'] as Map<String, dynamic>?;
    final isActive = user?['is_active'] ?? false;
    final verificationStatus = provider['verification_status'] ?? 'PENDING';

    // Debug: print verification status

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (verificationStatus) {
      case 'VERIFIED':
        statusColor = Colors.green;
        statusText = 'موثق';
        statusIcon = Icons.verified;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد المراجعة';
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
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
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Active/Inactive badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'معطل',
                    style: TextStyle(
                      color: isActive ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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

            const Divider(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle active/inactive
                Expanded(
                  child: ConnectivityIconButton(
                    onPressed: () => toggleProviderActive(provider),
                    icon: Icon(isActive ? Icons.block : Icons.check_circle),
                    label: Text(isActive ? 'تعطيل' : 'تفعيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.red : Colors.green,
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
