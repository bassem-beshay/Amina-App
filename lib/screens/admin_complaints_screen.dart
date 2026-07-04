import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/connectivity_button.dart';

/// شاشة إدارة الشكاوي - Admin
class AdminComplaintsScreen extends StatefulWidget {
  final String token;

  const AdminComplaintsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminComplaintsScreenState createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  String errorMessage = '';
  String statusFilter = 'all'; // all, PENDING, IN_REVIEW, RESOLVED, CLOSED

  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AdminService.getAllComplaints(
        status: statusFilter == 'all' ? null : statusFilter,
      );

      if (response.success) {
        final responseData = response.rawResponse;

        if (responseData is List) {
          setState(() {
            complaints = List<Map<String, dynamic>>.from(responseData);
            isLoading = false;
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          setState(() {
            complaints = List<Map<String, dynamic>>.from(dataList);
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }

      } else {
        throw Exception(response.error ?? 'فشل تحميل الشكاوي');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل الشكاوي: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredComplaints {
    if (statusFilter == 'all') return complaints;
    return complaints
        .where((c) => c['status'] == statusFilter)
        .toList();
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return intl.DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_REVIEW':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'IN_REVIEW':
        return 'قيد المراجعة';
      case 'RESOLVED':
        return 'تم الحل';
      case 'CLOSED':
        return 'مغلق';
      default:
        return status;
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
          'إدارة الشكاوي',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Status Filter
          PopupMenuButton<String>(
            icon: Icon(
              statusFilter == 'all'
                  ? Icons.filter_list
                  : Icons.filter_list_alt,
              color: Theme.of(context).colorScheme.surface,
            ),
            onSelected: (status) {
              setState(() {
                statusFilter = status;
              });
              loadComplaints();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('كل الشكاوي'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'PENDING',
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('قيد الانتظار'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'IN_REVIEW',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('قيد المراجعة'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'RESOLVED',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تم الحل'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'CLOSED',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('مغلق'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadComplaints,
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
                        onPressed: loadComplaints,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadComplaints,
                  child: filteredComplaints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.report_problem_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                statusFilter == 'all'
                                    ? 'لا توجد شكاوي'
                                    : 'لا توجد شكاوي ${getStatusText(statusFilter)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = filteredComplaints[index];
                            return _buildComplaintCard(complaint);
                          },
                        ),
                ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final complainantInfo = complaint['complainant_info'] as Map<String, dynamic>?;
    final againstInfo = complaint['against_info'] as Map<String, dynamic>?;
    final bookingId = complaint['booking']; // This is just an ID (integer)
    final status = complaint['status'] ?? 'PENDING';
    final title = complaint['title'] ?? '';
    final resolution = complaint['resolution'];

    final complainantName = complainantInfo != null
        ? '${complainantInfo['first_name'] ?? ''} ${complainantInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final againstUserName = againstInfo != null
        ? '${againstInfo['first_name'] ?? ''} ${againstInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with gradient background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getStatusColor(status).withOpacity(0.1),
                    getStatusColor(status).withOpacity(0.05),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.report_problem_outlined,
                      color: getStatusColor(status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                complainantName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.arrow_back, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                againstUserName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (bookingId != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.bookmark_outline, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'حجز #$bookingId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: getStatusColor(status).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      getStatusText(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Complaint Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'تفاصيل الشكوى',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Resolution (if resolved)
                  if (resolution != null && resolution.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'الحل المتخذ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            resolution,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Footer: Date only
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(complaint['created_at']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
