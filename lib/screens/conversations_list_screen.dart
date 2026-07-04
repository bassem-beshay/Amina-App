import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadConversations();
    // Auto-refresh conversations every 5 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadConversations();
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await ChatService.getConversations();

      if (mounted) {
        // Only update UI if data actually changed (to prevent unnecessary rebuilds and image reloads)
        bool hasChanges = _conversations.length != conversations.length;

        // Check if unread counts or last message changed
        if (!hasChanges && _conversations.isNotEmpty) {
          for (int i = 0; i < conversations.length; i++) {
            if (_conversations[i].unreadCount != conversations[i].unreadCount ||
                _conversations[i].lastMessage?.id != conversations[i].lastMessage?.id) {
              hasChanges = true;
              break;
            }
          }
        }

        if (hasChanges || _isLoading) {
          setState(() {
            _conversations = conversations;
            _isLoading = false;
          });
        } else {
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF4F46E5) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Chats',
          style: TextStyle(
            color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: Color(0xFF4F46E5),
                  child: ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationCard(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF4F46E5).withOpacity( 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Color(0xFF4F46E5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'noData',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر المحادثات هنا عند بدء التواصل مع العملاء أو مقدمي الخدمات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    // Determine which user to display (the other person in conversation)
    final displayUser = _currentUser != null && _currentUser!.id == conversation.client.id
        ? conversation.provider
        : conversation.client;
    final unreadCount = conversation.unreadCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity( 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  bookingId: conversation.bookingId,
                  otherUserName: '${displayUser.firstName} ${displayUser.lastName}',
                ),
              ),
            ).then((_) {
              // Reload conversations after returning from chat
              _loadConversations();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with real profile picture
                Stack(
                  children: [
                    _buildAvatar(displayUser),
                    // Online indicator (placeholder)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${displayUser.firstName} ${displayUser.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (conversation.lastMessage != null)
                            Text(
                              _formatTime(conversation.lastMessage!.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.cleaning_services,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                                final serviceName = isEnglish && conversation.serviceNameEn != null && conversation.serviceNameEn!.isNotEmpty
                                    ? conversation.serviceNameEn!
                                    : conversation.serviceName;
                                return Text(
                                  serviceName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (conversation.lastMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          conversation.lastMessage!.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Unread badge
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ \u200F${diff.inDays}\u200F يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildAvatar(User user) {
    // Get profile picture URL based on user role
    String? profilePictureUrl;

    if (user.role.toUpperCase() == 'CLIENT' && user.clientProfile?.profilePicture != null) {
      profilePictureUrl = '${ApiConfig.baseUrl}${user.clientProfile!.profilePicture}';
    } else if (user.role.toUpperCase() == 'PROVIDER' && user.providerProfile?.profilePicture != null) {
      profilePictureUrl = '${ApiConfig.baseUrl}${user.providerProfile!.profilePicture}';
    }

    // Show text avatar if no profile picture
    if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFF4F46E5).withOpacity( 0.1),
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    // Use CachedNetworkImage for profile picture
    return CachedNetworkImage(
      imageUrl: profilePictureUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 30,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFF4F46E5).withOpacity( 0.1),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFF4F46E5).withOpacity( 0.1),
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }
}
