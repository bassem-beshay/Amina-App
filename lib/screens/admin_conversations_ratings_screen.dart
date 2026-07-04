import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart' as intl;
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

/// شاشة إدارة المحادثات، التقييمات، والشكاوى معاً - Admin
class AdminConversationsRatingsScreen extends StatefulWidget {
  final String token;

  const AdminConversationsRatingsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminConversationsRatingsScreenState createState() =>
      _AdminConversationsRatingsScreenState();
}

class _AdminConversationsRatingsScreenState
    extends State<AdminConversationsRatingsScreen> {
  List<Map<String, dynamic>> conversations = [];
  Map<int, List<Map<String, dynamic>>> conversationRatings = {};
  Map<int, List<Map<String, dynamic>>> conversationComplaints = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load conversations
      final convResponse = await AdminService.getAllConversations();

      if (convResponse.success) {
        final responseData = convResponse.rawResponse;

        List<Map<String, dynamic>> loadedConversations = [];
        if (responseData is List) {
          loadedConversations = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          loadedConversations = List<Map<String, dynamic>>.from(dataList);
        }

        // Load all ratings
        final ratingsResponse = await AdminService.getAllRatings();
        Map<int, List<Map<String, dynamic>>> loadedRatings = {};

        if (ratingsResponse.success) {
          final ratingsData = ratingsResponse.rawResponse;
          List<Map<String, dynamic>> allRatings = [];

          if (ratingsData is List) {
            allRatings = List<Map<String, dynamic>>.from(ratingsData);
          } else if (ratingsData is Map && ratingsData.containsKey('data')) {
            final dataList = ratingsData['data'] as List;
            allRatings = List<Map<String, dynamic>>.from(dataList);
          }

          // Group ratings by booking ID
          for (var rating in allRatings) {
            final bookingId = rating['booking'];
            if (bookingId != null) {
              if (!loadedRatings.containsKey(bookingId)) {
                loadedRatings[bookingId] = [];
              }
              loadedRatings[bookingId]!.add(rating);
            }
          }
        }

        // Load all complaints
        final complaintsResponse = await AdminService.getAllComplaints();
        Map<int, List<Map<String, dynamic>>> loadedComplaints = {};

        if (complaintsResponse.success) {
          final complaintsData = complaintsResponse.rawResponse;
          List<Map<String, dynamic>> allComplaints = [];

          if (complaintsData is List) {
            allComplaints = List<Map<String, dynamic>>.from(complaintsData);
          } else if (complaintsData is Map && complaintsData.containsKey('data')) {
            final dataList = complaintsData['data'] as List;
            allComplaints = List<Map<String, dynamic>>.from(dataList);
          }

          // Group complaints by booking ID
          for (var complaint in allComplaints) {
            final bookingId = complaint['booking'];
            if (bookingId != null) {
              if (!loadedComplaints.containsKey(bookingId)) {
                loadedComplaints[bookingId] = [];
              }
              loadedComplaints[bookingId]!.add(complaint);
            }
          }
        }

        setState(() {
          conversations = loadedConversations;
          conversationRatings = loadedRatings;
          conversationComplaints = loadedComplaints;
          isLoading = false;
        });

      } else {
        throw Exception(convResponse.error ?? 'فشل تحميل البيانات');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      final response = await AdminService.deleteRating(ratingId);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف التقييم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload data
        loadData();
      } else {
        throw Exception(response.error ?? 'فشل حذف التقييم');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف التقييم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return intl.DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        return 'أمس';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} أيام';
      } else {
        return intl.DateFormat('dd/MM/yyyy').format(date);
      }
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
          AppLocalizations.of(context)?.translate('conversationsRatingsComplaints') ?? 'المحادثات، التقييمات، والشكاوى',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadData,
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
                        onPressed: loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد محادثات',
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
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            final bookingId = conversation['booking_id'] ?? conversation['booking'];
                            final ratings = conversationRatings[bookingId] ?? [];
                            final complaints = conversationComplaints[bookingId] ?? [];
                            return _buildConversationCard(conversation, ratings, complaints);
                          },
                        ),
                ),
    );
  }

  Widget _buildConversationCard(
      Map<String, dynamic> conversation,
      List<Map<String, dynamic>> ratings,
      List<Map<String, dynamic>> complaints) {
    final client = conversation['client'] as Map<String, dynamic>?;
    final provider = conversation['provider'] as Map<String, dynamic>?;
    final bookingId = conversation['booking_id'] ?? conversation['booking'];
    final lastMessage = conversation['last_message'] as Map<String, dynamic>?;
    final unreadCount = conversation['unread_count'] ?? 0;

    final clientName = client != null
        ? '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim()
        : 'عميل محذوف';
    final providerName = provider != null
        ? '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'.trim()
        : 'مزود محذوف';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        children: [
          // Conversation Header
          InkWell(
            onTap: () => _viewConversationDetails(conversation),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Participants
                  Row(
                    children: [
                      // Client Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 24),
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
                                    clientName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    providerName,
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
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Last Message
                  if (lastMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage['content'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDate(lastMessage['created_at']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Ratings Section
          if (ratings.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'التقييمات (${ratings.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...ratings.map((rating) => _buildRatingItem(rating)).toList(),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.star_border, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Complaints Section
          if (complaints.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'الشكاوى (${complaints.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Show badge if there are PENDING complaints
                      if (complaints.any((c) => c['status'] == 'PENDING'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'معلقة',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...complaints.map((complaint) => _buildComplaintItem(complaint)).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingItem(Map<String, dynamic> rating) {
    final raterInfo = rating['rater_info'] as Map<String, dynamic>?;
    final ratedInfo = rating['rated_info'] as Map<String, dynamic>?;
    final ratingValue = rating['rating'] ?? 0;
    final comment = rating['review'] ?? '';

    final raterName = raterInfo != null
        ? '${raterInfo['first_name'] ?? ''} ${raterInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final ratedName = ratedInfo != null
        ? '${ratedInfo['first_name'] ?? ''} ${ratedInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          raterName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_back, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          ratedName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < ratingValue ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteRating(rating['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplaintItem(Map<String, dynamic> complaint) {
    final complainantInfo = complaint['complainant_info'] as Map<String, dynamic>?;
    final againstInfo = complaint['against_info'] as Map<String, dynamic>?;
    final title = complaint['title'] ?? '';
    final status = complaint['status'] ?? 'PENDING';
    final statusDisplay = complaint['status_display'] ?? status;

    final complainantName = complainantInfo != null
        ? '${complainantInfo['first_name'] ?? ''} ${complainantInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final againstName = againstInfo != null
        ? '${againstInfo['first_name'] ?? ''} ${againstInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';

    // Status colors
    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'PENDING':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      case 'IN_REVIEW':
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        break;
      case 'RESOLVED':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          complainantName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_back, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          againstName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusDisplay,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteRating(int ratingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التقييم؟'),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () {
              Navigator.pop(context);
              deleteRating(ratingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _viewConversationDetails(Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (context) => _ConversationDetailsDialog(
        conversation: conversation,
        token: widget.token,
      ),
    );
  }
}

class _ConversationDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final String token;

  const _ConversationDetailsDialog({
    Key? key,
    required this.conversation,
    required this.token,
  }) : super(key: key);

  @override
  _ConversationDetailsDialogState createState() => _ConversationDetailsDialogState();
}

class _ConversationDetailsDialogState extends State<_ConversationDetailsDialog> {
  List<Map<String, dynamic>> messages = [];
  Map<String, dynamic>? complaint;
  bool isLoading = true;
  bool isSubmitting = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadMessagesAndComplaint();
  }

  Future<void> loadMessagesAndComplaint() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final conversationId = widget.conversation['id'];
      final bookingId = widget.conversation['booking_id'] ?? widget.conversation['booking'];


      // Load messages
      final response = await AdminService.getConversationMessages(conversationId);

      if (response.success) {
        final data = response.rawResponse;

        List<dynamic> messagesList;
        if (data is Map && data.containsKey('messages')) {
          // Backend returns: { "conversation": {...}, "messages": [...] }
          messagesList = data['messages'] as List;
        } else if (data is List) {
          // Backend returns: [...]
          messagesList = data;
        } else {
          throw Exception('Invalid response format: $data');
        }

        // Load complaint if booking exists
        Map<String, dynamic>? loadedComplaint;
        if (bookingId != null) {
          try {
            final complaintResponse = await AdminService.getComplaintByBooking(bookingId);

            if (complaintResponse.success) {
              loadedComplaint = complaintResponse.rawResponse is Map
                  ? (complaintResponse.rawResponse['data'] ?? complaintResponse.rawResponse)
                  : null;

            } else {
            }
          } catch (e) {
          }
        } else {
        }

        setState(() {
          messages = List<Map<String, dynamic>>.from(messagesList);
          complaint = loadedComplaint;
          isLoading = false;
        });

      } else {
        throw Exception(response.error ?? 'فشل تحميل الرسائل');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
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
    final client = widget.conversation['client'] as Map<String, dynamic>?;
    final provider = widget.conversation['provider'] as Map<String, dynamic>?;
    final bookingId = widget.conversation['booking_id'] ?? widget.conversation['booking'];

    final clientName = client != null
        ? '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim()
        : 'عميل محذوف';
    final providerName = provider != null
        ? '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'.trim()
        : 'مزود محذوف';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat, color: Theme.of(context).colorScheme.surface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'محادثة #${widget.conversation['id']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.surface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'العميل: $clientName',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'المزود: $providerName',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'حجز #$bookingId',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Content (Complaint + Messages + Action Buttons)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(errorMessage),
                              const SizedBox(height: 16),
                              ConnectivityIconButton(
                                onPressed: loadMessagesAndComplaint,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Complaint Section (if exists)
                              if (complaint != null) ...[
                                _buildComplaintSection(),
                                const SizedBox(height: 24),
                                const Divider(thickness: 2),
                                const SizedBox(height: 16),
                              ],

                              // Messages Section
                              if (messages.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد رسائل',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...messages.map((message) => _buildMessageBubble(message)),

                              // Action Buttons Section (if complaint exists and not closed)
                              if (complaint != null && complaint!['status'] != 'CLOSED') ...[
                                const SizedBox(height: 24),
                                const Divider(thickness: 2),
                                const SizedBox(height: 16),
                                _buildActionButtons(),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for complaint status
  Color _getStatusColor(String status) {
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

  String _getStatusText(String status) {
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

  // Build Complaint Section
  Widget _buildComplaintSection() {
    if (complaint == null) return const SizedBox.shrink();

    final complainantInfo = complaint!['complainant_info'] as Map<String, dynamic>?;
    final againstInfo = complaint!['against_info'] as Map<String, dynamic>?;
    final status = complaint!['status'] ?? 'PENDING';
    final title = complaint!['title'] ?? '';
    final resolution = complaint!['resolution'];
    final createdAt = complaint!['created_at'];

    final complainantName = complainantInfo != null
        ? '${complainantInfo['first_name'] ?? ''} ${complainantInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final againstUserName = againstInfo != null
        ? '${againstInfo['first_name'] ?? ''} ${againstInfo['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status).withOpacity(0.1),
                  _getStatusColor(status).withOpacity(0.05),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.report_problem_outlined,
                    color: _getStatusColor(status),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الشكوى',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
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

          // Complaint details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parties involved
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المشتكي',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complainantName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back, size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'المشكو ضده',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            againstUserName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Complaint description
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

                // Resolution (if exists)
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Action Buttons Section
  Widget _buildActionButtons() {
    if (complaint == null) return const SizedBox.shrink();

    final status = complaint!['status'] ?? 'PENDING';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              const Text(
                'إجراءات الأدمن',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (status == 'PENDING') ...[
            SizedBox(
              width: double.infinity,
              child: ConnectivityIconButton(
                onPressed: isSubmitting ? null : _startReview,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.rate_review),
                label: Text(isSubmitting ? 'جاري البدء...' : 'بدء مراجعة الشكوى'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          if (status == 'IN_REVIEW') ...[
            SizedBox(
              width: double.infinity,
              child: ConnectivityIconButton(
                onPressed: isSubmitting ? null : _showResolveDialog,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(isSubmitting ? 'جاري الحل...' : 'حل الشكوى وإرسال الرد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          if (status == 'RESOLVED') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تم حل هذه الشكوى',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Action: Start Review
  Future<void> _startReview() async {
    if (complaint == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final complaintId = complaint!['id'];
      final response = await AdminService.startReviewComplaint(complaintId);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم بدء مراجعة الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data
        await loadMessagesAndComplaint();
      } else {
        throw Exception(response.error ?? 'فشل بدء المراجعة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  // Action: Show Resolve Dialog
  Future<void> _showResolveDialog() async {
    final TextEditingController resolutionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('حل الشكوى'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى كتابة الحل الذي تم اتخاذه لحل هذه الشكوى:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'اكتب الحل هنا...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () {
              if (resolutionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠ يرجى كتابة الحل'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الحل'),
          ),
        ],
      ),
    );

    if (confirmed == true && resolutionController.text.trim().isNotEmpty) {
      await _resolveComplaint(resolutionController.text.trim());
    }
  }

  // Action: Resolve Complaint
  Future<void> _resolveComplaint(String resolution) async {
    if (complaint == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final complaintId = complaint!['id'];
      final response = await AdminService.resolveComplaint(
        complaintId,
        resolution,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم حل الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data
        await loadMessagesAndComplaint();
      } else {
        throw Exception(response.error ?? 'فشل حل الشكوى');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final sender = message['sender'] as Map<String, dynamic>?;
    final content = message['content'] ?? '';
    final createdAt = message['created_at'];
    final isRead = message['is_read'] ?? false;

    final senderName = sender != null
        ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
        : 'مستخدم محذوف';
    final senderRole = sender?['role'] ?? '';

    // Determine if sender is client or provider
    final isClient = senderRole.toUpperCase() == 'CLIENT';
    final bubbleColor = isClient ? Colors.blue[50] : Colors.green[50];
    final textColor = isClient ? Colors.blue[900] : Colors.green[900];
    final nameColor = isClient ? Colors.blue[700] : Colors.green[700];

    return Align(
      alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        child: Column(
          crossAxisAlignment: isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: nameColor,
                ),
              ),
            ),
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isClient ? Colors.blue : Colors.green).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
