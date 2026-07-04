import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/connectivity_button.dart';

/// شاشة إدارة المحادثات - Admin
class AdminConversationsScreen extends StatefulWidget {
  final String token;

  const AdminConversationsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminConversationsScreenState createState() =>
      _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    ApiClient.setAuthToken(widget.token);
    loadConversations();
  }

  Future<void> loadConversations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AdminService.getAllConversations();

      if (response.success) {
        final responseData = response.rawResponse;

        if (responseData is List) {
          setState(() {
            conversations = List<Map<String, dynamic>>.from(responseData);
            isLoading = false;
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          setState(() {
            conversations = List<Map<String, dynamic>>.from(dataList);
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }

      } else {
        throw Exception(response.error ?? 'فشل تحميل المحادثات');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في تحميل المحادثات: $e';
        isLoading = false;
      });
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
          'إدارة المحادثات',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: loadConversations,
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
                        onPressed: loadConversations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadConversations,
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
                            return _buildConversationCard(conversation);
                          },
                        ),
                ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final client = conversation['client'] as Map<String, dynamic>?;
    final provider = conversation['provider'] as Map<String, dynamic>?;
    final bookingId = conversation['booking_id'] ?? conversation['booking']; // booking_id is the actual ID
    final lastMessage = conversation['last_message'] as Map<String, dynamic>?;
    final unreadCount = conversation['unread_count'] ?? 0;

    final clientName = client != null
        ? '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim()
        : 'عميل محذوف';
    final providerName = provider != null
        ? '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'.trim()
        : 'مزود محذوف';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewConversationDetails(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Client & Provider
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
    );
  }

  Future<void> _viewConversationDetails(Map<String, dynamic> conversation) async {
    final conversationId = conversation['id'];
    final bookingId = conversation['booking_id'] ?? conversation['booking'];


    try {
      // جلب الرسائل
      final messagesResponse = await AdminService.getConversationMessages(conversationId);

      if (messagesResponse.success && mounted) {
        final messages = messagesResponse.rawResponse is Map
            ? (messagesResponse.rawResponse['messages'] ?? messagesResponse.rawResponse['data'] ?? [])
            : messagesResponse.rawResponse ?? [];


        // جلب الشكوى إذا كان هناك booking_id
        Map<String, dynamic>? complaint;
        if (bookingId != null) {
          try {
            final complaintResponse = await AdminService.getComplaintByBooking(bookingId);

            if (complaintResponse.success) {
              complaint = complaintResponse.rawResponse is Map
                  ? (complaintResponse.rawResponse['data'] ?? complaintResponse.rawResponse)
                  : null;

            } else {
            }
          } catch (e) {
          }
        } else {
        }


        showDialog(
          context: context,
          builder: (ctx) => _ConversationDetailsDialog(
            conversation: conversation,
            messages: List<Map<String, dynamic>>.from(messages is List ? messages : []),
            complaint: complaint,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(messagesResponse.error ?? 'فشل تحميل الرسائل'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ConversationDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic>? complaint;

  const _ConversationDetailsDialog({
    required this.conversation,
    required this.messages,
    this.complaint,
  });

  @override
  State<_ConversationDetailsDialog> createState() => _ConversationDetailsDialogState();
}

class _ConversationDetailsDialogState extends State<_ConversationDetailsDialog> {
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final client = widget.conversation['client'] as Map<String, dynamic>?;
    final provider = widget.conversation['provider'] as Map<String, dynamic>?;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المحادثة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$clientName ← $providerName',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Complaint Section (if exists) - Expanded Version
            if (widget.complaint != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.1),
                      _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.05),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.report_problem_outlined,
                              color: _getComplaintStatusColor(widget.complaint!['status']),
                              size: 24,
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
                                const SizedBox(height: 2),
                                Text(
                                  'حجز #${widget.conversation['booking_id'] ?? widget.conversation['booking']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getComplaintStatusColor(widget.complaint!['status']),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getComplaintStatusText(widget.complaint!['status']),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Complaint Body
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Parties Involved
                          _buildComplaintInfoRow(
                            Icons.person,
                            'مقدم الشكوى',
                            widget.complaint!['complainant_info'] != null
                                ? '${widget.complaint!['complainant_info']['first_name'] ?? ''} ${widget.complaint!['complainant_info']['last_name'] ?? ''}'.trim()
                                : 'غير متاح',
                          ),
                          const SizedBox(height: 8),
                          _buildComplaintInfoRow(
                            Icons.person_outline,
                            'الشكوى ضد',
                            widget.complaint!['against_info'] != null
                                ? '${widget.complaint!['against_info']['first_name'] ?? ''} ${widget.complaint!['against_info']['last_name'] ?? ''}'.trim()
                                : 'غير متاح',
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Complaint Details
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Text(
                              widget.complaint!['title'] ?? 'لا يوجد وصف',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ),

                          // Description (if available)
                          if (widget.complaint!['description'] != null && widget.complaint!['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.complaint!['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],

                          // Resolution (if exists)
                          if (widget.complaint!['resolution'] != null && widget.complaint!['resolution'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  '✓ تم حل الشكوى',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
                              ),
                              child: Text(
                                widget.complaint!['resolution'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[900],
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.complaint!['resolved_at'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.event_available, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تاريخ الحل: ${_formatDateTime(widget.complaint!['resolved_at'])}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],

                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Separator before messages
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'المحادثة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
              ),
            ],

            // Messages List
            Expanded(
              child: widget.messages.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد رسائل',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.messages.length,
                            itemBuilder: (context, index) {
                              final message = widget.messages[index];
                              final sender = message['sender'] as Map<String, dynamic>?;
                              final senderName = sender != null
                                  ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
                                  : 'مستخدم';
                              final isClient = sender?['role'] == 'CLIENT';

                              return Align(
                                alignment: isClient
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isClient
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isClient ? Colors.blue : Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message['content'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateTime(message['created_at']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Complaint Resolution Section (if complaint exists and not resolved)
                          if (widget.complaint != null &&
                              widget.complaint!['status'] != 'RESOLVED' &&
                              widget.complaint!['status'] != 'CLOSED') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, color: Colors.blue[700], size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'إجراءات الأدمن',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Status indicator
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getComplaintStatusColor(widget.complaint!['status']).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: _getComplaintStatusColor(widget.complaint!['status']),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'الحالة: ${_getComplaintStatusText(widget.complaint!['status'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getComplaintStatusColor(widget.complaint!['status']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Action buttons based on status
                                  if (widget.complaint!['status'] == 'PENDING')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ConnectivityIconButton(
                                        onPressed: isSubmitting ? null : () => _startReview(),
                                        icon: isSubmitting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.rate_review, size: 18),
                                        label: const Text('بدء مراجعة الشكوى'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),

                                  if (widget.complaint!['status'] == 'IN_REVIEW')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ConnectivityIconButton(
                                        onPressed: isSubmitting ? null : () => _showResolveDialog(),
                                        icon: isSubmitting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.check_circle, size: 18),
                                        label: const Text('حل الشكوى وإرسال الرد'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getComplaintStatusColor(String? status) {
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

  String _getComplaintStatusText(String? status) {
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
        return status ?? '';
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return intl.DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  Future<void> _startReview() async {
    setState(() => isSubmitting = true);

    try {
      final response = await AdminService.startReviewComplaint(widget.complaint!['id']);

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء مراجعة الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Close dialog
        // Reload parent screen
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'فشل بدء المراجعة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _showResolveDialog() async {
    final resolutionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'يرجى كتابة الحل المتخذ لهذه الشكوى:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resolutionController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'الحل *',
                hintText: 'اكتب تفاصيل الحل المتخذ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة الحل'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('حفظ الحل'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resolveComplaint(resolutionController.text.trim());
    }

    resolutionController.dispose();
  }

  Future<void> _resolveComplaint(String resolution) async {
    setState(() => isSubmitting = true);

    try {
      final response = await AdminService.resolveComplaint(
        widget.complaint!['id'],
        resolution,
      );

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حل الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Close dialog
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'فشل حل الشكوى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}
