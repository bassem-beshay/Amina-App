import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class AdminClientsScreen extends StatefulWidget {
  final String token;
  const AdminClientsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminClientsScreenState createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String errorMessage = '';
  String filter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // جلب جميع العملاء
      final response = await ApiClient.get(
        '/api/users/admin/clients/',
        needsAuth: true,
      );

      if (response.success) {
        final data = response.rawResponse ?? response.data;
        if (data is List) {
          setState(() {
            clients = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.error ?? 'Failed to load clients');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredClients {
    if (filter == 'active') {
      return clients.where((c) => c['is_active'] == true).toList();
    } else if (filter == 'inactive') {
      return clients.where((c) => c['is_active'] == false).toList();
    }
    return clients;
  }

  Future<void> toggleClientActive(Map<String, dynamic> client) async {
    try {
      final clientId = client['id'];
      final isActive = client['is_active'];
      final clientName = '${client['first_name']} ${client['last_name']}';

      // تأكيد
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
            ],
          ),
          content: Text(
            isActive
                ? 'هل أنت متأكد من تعطيل حساب "$clientName"؟\nلن يتمكن من تسجيل الدخول.'
                : 'هل أنت متأكد من تفعيل حساب "$clientName"؟',
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
                backgroundColor: isActive ? Colors.red : Colors.green,
              ),
              child: Text(isActive ? 'تعطيل' : 'تفعيل'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // تغيير الحالة
      final response = await ApiClient.post(
        '/api/users/admin/clients/$clientId/toggle_active/',
        needsAuth: true,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'تم تعطيل حساب "$clientName" بنجاح'
                  : 'تم تفعيل حساب "$clientName" بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // إعادة تحميل القائمة
        loadClients();
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
    final displayedClients = filteredClients;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.manageClients ?? 'إدارة العملاء',
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
            onPressed: loadClients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab('الكل', 'all', clients.length),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'نشط',
                    'active',
                    clients.where((c) => c['is_active'] == true).length,
                  ),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'معطل',
                    'inactive',
                    clients.where((c) => c['is_active'] == false).length,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
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
                              onPressed: loadClients,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : displayedClients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد عملاء',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadClients,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedClients.length,
                              itemBuilder: (ctx, index) {
                                final client = displayedClients[index];
                                return _buildClientCard(client);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, int count) {
    final isSelected = filter == value;
    return InkWell(
      onTap: () {
        setState(() {
          filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final isActive = client['is_active'] ?? true;
    final clientProfile = client['client_profile'] as Map<String, dynamic>?;

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
                  backgroundImage: clientProfile?['profile_picture_url'] != null
                      ? NetworkImage(clientProfile!['profile_picture_url'])
                      : null,
                  child: clientProfile?['profile_picture_url'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity( 0.1)
                                  : Colors.red.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'نشط' : 'معطل',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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

            // Client details
            _buildDetailRow(Icons.email, client['email'] ?? ''),
            _buildDetailRow(Icons.phone, client['phone_number'] ?? 'غير متوفر'),
            if (clientProfile?['city'] != null)
              _buildDetailRow(Icons.location_city, clientProfile!['city']),
            if (clientProfile?['formatted_address'] != null)
              _buildDetailRow(
                  Icons.location_on, clientProfile!['formatted_address']),

            const Divider(height: 24),

            // Action button - تفعيل/تعطيل
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ConnectivityIconButton(
                  onPressed: () => toggleClientActive(client),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle),
                  label: Text(isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red : Colors.green,
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
