import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/connectivity_button.dart';

/// شاشة إدارة التقييمات - Admin
class AdminRatingsScreen extends StatefulWidget {
  final String token;

  const AdminRatingsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminRatingsScreenState createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends State<AdminRatingsScreen> {
  List<Map<String, dynamic>> ratings = [];
  bool isLoading = true;
  String errorMessage = '';
  int? selectedRatingFilter; // null = all, 1-5 = specific rating

  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadRatings();
  }

  Future<void> loadRatings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AdminService.getAllRatings(
        minRating: selectedRatingFilter,
        maxRating: selectedRatingFilter,
      );

      if (response.success) {
        final responseData = response.rawResponse;

        if (responseData is List) {
          setState(() {
            ratings = List<Map<String, dynamic>>.from(responseData);
            isLoading = false;
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          setState(() {
            ratings = List<Map<String, dynamic>>.from(dataList);
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }

      } else {
        throw Exception(response.error ?? 'فشل تحميل التقييمات');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل التقييمات: $e';
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          'إدارة التقييمات',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Rating Filter
          PopupMenuButton<int?>(
            icon: Icon(
              selectedRatingFilter == null
                  ? Icons.filter_list
                  : Icons.filter_list_alt,
              color: Theme.of(context).colorScheme.surface,
            ),
            onSelected: (rating) {
              setState(() {
                selectedRatingFilter = rating;
              });
              loadRatings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.star_border),
                    SizedBox(width: 8),
                    Text('كل التقييمات'),
                  ],
                ),
              ),
              ...List.generate(
                5,
                (index) => PopupMenuItem<int?>(
                  value: 5 - index,
                  child: Row(
                    children: [
                      ...List.generate(
                        5 - index,
                        (_) => const Icon(Icons.star, size: 16, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      Text('${5 - index} نجوم'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadRatings,
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
                        onPressed: loadRatings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRatings,
                  child: ratings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                selectedRatingFilter == null
                                    ? 'لا توجد تقييمات'
                                    : 'لا توجد تقييمات بـ $selectedRatingFilter نجوم',
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
                          itemCount: ratings.length,
                          itemBuilder: (context, index) {
                            final rating = ratings[index];
                            return _buildRatingCard(rating);
                          },
                        ),
                ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final raterInfo = rating['rater_info'] as Map<String, dynamic>?;
    final ratedInfo = rating['rated_info'] as Map<String, dynamic>?;
    final bookingId = rating['booking']; // This is just an ID (integer)
    final ratingValue = rating['rating'] ?? 0;
    final comment = rating['review'] ?? '';

    final raterName = raterInfo != null
        ? '${raterInfo['first_name'] ?? ''} ${raterInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final ratedName = ratedInfo != null
        ? '${ratedInfo['first_name'] ?? ''} ${ratedInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final raterRole = raterInfo?['role'] == 'CLIENT' ? 'عميل' : 'مزود خدمة';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Rater → Ratee
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              raterName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '($raterRole)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ratedName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      if (bookingId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'حجز #$bookingId',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(rating);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Rating Stars
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < ratingValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$ratingValue/5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
            // Date
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formatDate(rating['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> rating) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا التقييم؟\n\nلن يمكن استرجاعه بعد الحذف.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRating(rating['id']);
    }
  }

  Future<void> _deleteRating(int ratingId) async {
    try {
      final response = await AdminService.deleteRating(ratingId);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم حذف التقييم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await loadRatings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل حذف التقييم'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف التقييم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
