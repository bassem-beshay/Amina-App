import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../models/websocket_message.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/booking_service.dart';
import '../services/rating_service.dart';
import '../utils/currency_helper.dart';
import '../l10n/app_localizations.dart';
import 'paysky_custom_tabs_screen.dart';
import 'paysky_iframe_dialog.dart';
import 'provider_details_screen.dart';
import 'client_details_screen.dart';
import '../widgets/connectivity_button.dart';

class ChatScreen extends StatefulWidget {
  final int bookingId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.bookingId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Conversation? _conversation;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  User? _currentUser;

  // WebSocket support
  WebSocketService? _wsService;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<WebSocketState>? _stateSubscription;
  StreamSubscription<WebSocketTypingMessage>? _typingSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<WebSocketMessageReadUpdate>? _readUpdateSubscription;
  WebSocketState _connectionState = WebSocketState.disconnected;
  int? _typingUserId;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadConversation();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _cleanupWebSocket();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  /// Initialize WebSocket service and subscriptions
  void _initializeWebSocket() {
    _wsService = WebSocketService();

    // Listen for new messages
    _messageSubscription = _wsService!.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark message as read if it's not from me
        if (_currentUser != null && message.sender.id != _currentUser!.id) {
          _wsService!.markMessageRead(message.id);
        }
      }
    });

    // Listen for connection state changes
    _stateSubscription = _wsService!.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });

        // Show connection status with appropriate messaging
        if (state == WebSocketState.connected) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showSnackBar('✓ ${AppLocalizations.of(context)?.online ?? 'متصل'}', isError: false);
        } else if (state == WebSocketState.connecting) {
          // Don't show snackbar for connecting state to avoid spam
        } else if (state == WebSocketState.error) {
          // Only show error once, not repeatedly
          ScaffoldMessenger.of(context).clearSnackBars();
        } else if (state == WebSocketState.disconnected) {
          // Only show disconnected message, not repeatedly
          ScaffoldMessenger.of(context).clearSnackBars();
        }
      }
    });

    // Listen for typing indicators
    _typingSubscription = _wsService!.typingStream.listen((typingMessage) {
      if (mounted && typingMessage.userId != _currentUser?.id) {
        setState(() {
          _typingUserId = typingMessage.isTyping ? typingMessage.userId : null;
        });
      }
    });

    // Listen for errors
    _errorSubscription = _wsService!.errorStream.listen((error) {
      if (mounted) {
        _showSnackBar(error, isError: true);
      }
    });

    // Listen for message read updates
    _readUpdateSubscription = _wsService!.readUpdateStream.listen((readUpdate) {
      if (mounted) {
        setState(() {
          // Find the message and update its read status
          final index = _messages.indexWhere((msg) => msg.id == readUpdate.messageId);
          if (index != -1) {
            final message = _messages[index];
            // Create updated message with isRead = true
            final updatedMessage = Message(
              id: message.id,
              conversation: message.conversation,
              sender: message.sender,
              content: message.content,
              isRead: true,
              createdAt: message.createdAt,
              readAt: readUpdate.readAt != null ? DateTime.parse(readUpdate.readAt!) : null,
            );
            _messages[index] = updatedMessage;
          }
        });
      }
    });
  }

  /// Cleanup WebSocket connections
  Future<void> _cleanupWebSocket() async {
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _typingSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _readUpdateSubscription?.cancel();
    await _wsService?.disconnect();
    _wsService?.dispose();
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  /// Scroll to bottom of chat
  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadConversation() async {
    try {
      setState(() => _isLoading = true);

      final conversation = await ChatService.getConversationByBooking(widget.bookingId);

      setState(() {
        _conversation = conversation;
        _messages = conversation.messages ?? [];
        _isLoading = false;
      });


      // Connect to WebSocket for real-time updates
      await _connectWebSocket();

      // Mark conversation as read (non-blocking)
      if (_conversation != null && _conversation!.unreadCount > 0) {
        try {
          final updatedConversation = await ChatService.markConversationRead(_conversation!.id);
          if (mounted && updatedConversation != null) {
            setState(() {
              _conversation = updatedConversation;
            });
          }
        } catch (e) {
        }
      }

      // Mark existing unread messages as read via WebSocket
      if (_wsService != null && _wsService!.isConnected && _currentUser != null) {
        for (final message in _messages) {
          if (!message.isRead && message.sender.id != _currentUser!.id) {
            _wsService!.markMessageRead(message.id);
          }
        }
      }

      // Scroll to bottom
      _scrollToBottom(animate: false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'}: $e', isError: true);
      }
    }
  }

  /// Connect to WebSocket
  Future<void> _connectWebSocket() async {
    if (_conversation == null || _wsService == null) return;

    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        return;
      }

      await _wsService!.connect(_conversation!.id, token);
    } catch (e) {
    }
  }

  /// Send message via WebSocket
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _conversation == null) {
      return;
    }

    final content = _messageController.text.trim();

    // Check WebSocket connection
    if (_wsService == null || !_wsService!.isConnected) {
      _showSnackBar(AppLocalizations.of(context)?.offline ?? 'غير متصل', isError: true);
      return;
    }

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      // Send via WebSocket (message will be received back via stream)
      _wsService!.sendMessage(content);

      setState(() => _isSending = false);

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('${AppLocalizations.of(context)?.failed ?? 'فشل'}: \u200F$e\u200F', isError: true);
    }
  }

  /// Handle typing indicator
  void _onTextChanged(String text) {
    if (_wsService == null || !_wsService!.isConnected) return;

    // Cancel previous timer
    _typingTimer?.cancel();

    // Send typing = true
    _wsService!.sendTypingIndicator(true);

    // Set timer to send typing = false after 2 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _wsService!.sendTypingIndicator(false);
    });
  }

  Future<void> _showRatingDialog() async {
    // Check if user already rated this booking

    try {
      final response = await RatingService.getBookingRatings(widget.bookingId);

      if (response.success && response.data != null) {
        final ratings = response.data!;
        final currentUserId = _currentUser?.id;

        // Check if current user already rated
        final alreadyRated = ratings.any((rating) => rating.ratedById == currentUserId);

        if (alreadyRated) {
          _showSnackBar(AppLocalizations.of(context)?.alreadyRated ?? 'لقد قمت بالفعل بتقييم هذا الحجز', isError: true);
          return;
        }
      }
    } catch (e) {
      // Continue to show rating dialog even if check fails
    }

    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Text(
                      AppLocalizations.of(context)?.rateOtherParty ?? 'تقييم الطرف الآخر',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.howWasExperience ?? 'كيف كانت تجربتك؟',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Star rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final rating = index + 1;
                            return IconButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedRating = rating;
                                });
                              },
                              icon: Icon(
                                rating <= selectedRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 40,
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          _getRatingText(selectedRating),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Comment field
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)?.commentOptional ?? 'التعليق (اختياري)',
                            hintText: AppLocalizations.of(context)?.shareYourOpinion ?? 'شاركنا رأيك عن التجربة...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ConnectivityTextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                AppLocalizations.of(context)?.cancel ?? 'إلغاء',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ConnectivityButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _submitRating(selectedRating, commentController.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.submitRatingButton ?? 'إرسال التقييم',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return AppLocalizations.of(context)?.veryBad ?? 'سيئ جداً 😞';
      case 2:
        return AppLocalizations.of(context)?.bad ?? 'سيئ 😕';
      case 3:
        return AppLocalizations.of(context)?.acceptable ?? 'مقبول 😐';
      case 4:
        return AppLocalizations.of(context)?.goodRating ?? 'جيد 😊';
      case 5:
        return AppLocalizations.of(context)?.excellent ?? 'ممتاز 🌟';
      default:
        return '';
    }
  }

  Future<void> _submitRating(int rating, String comment) async {

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get the other user ID from the conversation
      int? otherUserId;
      if (_conversation != null) {

        if (_conversation!.client.id == _currentUser?.id) {
          otherUserId = _conversation!.provider.id;
        } else {
          otherUserId = _conversation!.client.id;
        }
      } else {
      }

      if (otherUserId == null) {
        Navigator.pop(context); // Close loading
        _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${AppLocalizations.of(context)?.userInfoNotFound ?? 'لم يتم العثور على معلومات المستخدم'}', isError: true);
        return;
      }


      // Submit rating
      final result = await RatingService.createRating(
        bookingId: widget.bookingId,
        ratedUserId: otherUserId,
        rating: rating,
        comment: comment.trim().isEmpty ? null : comment.trim(),
      );


      Navigator.pop(context); // Close loading

      if (result.success) {
        _showSnackBar('✓ ${AppLocalizations.of(context)?.success ?? 'نجح'}', isError: false);
      } else {
        _showSnackBar(result.error ?? '${AppLocalizations.of(context)?.failed ?? 'فشل'}', isError: true);
      }
    } catch (e, stackTrace) {
      Navigator.pop(context); // Close loading
      _showSnackBar('${AppLocalizations.of(context)?.errorOccurred ?? 'حدث خطأ'}: $e', isError: true);
    }
  }

  /// Start service - Provider marks service as started
  Future<void> _startService() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.startServiceButton ?? 'بدء الخدمة'),
        content: Text(AppLocalizations.of(context)?.startServiceConfirm ?? 'هل أنت متأكد من بدء الخدمة الآن؟'),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(AppLocalizations.of(context)?.startServiceButton ?? 'بدء الخدمة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await BookingService.startBooking(widget.bookingId);
      Navigator.pop(context); // Close loading

      if (result.success) {
        _showSnackBar('✓ ${AppLocalizations.of(context)?.success ?? 'نجح'}', isError: false);
        // Reload conversation to update status
        await _loadConversation();
      } else {
        _showSnackBar(result.error ?? '${AppLocalizations.of(context)?.failed ?? 'فشل'}', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${e.toString()}', isError: true);
    }
  }

  /// Complete service - Provider marks service as completed
  Future<void> _completeService() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.completeServiceButton ?? 'إنهاء الخدمة'),
        content: Text(
          AppLocalizations.of(context)?.completeServiceConfirm ?? 'هل أنت متأكد من إنهاء الخدمة؟\n\nسيتم إرسال إشعار للعميل لتأكيد الإكمال.',
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
            ),
            child: Text(AppLocalizations.of(context)?.completeServiceButton ?? 'إنهاء الخدمة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await BookingService.completeBooking(widget.bookingId);
      Navigator.pop(context); // Close loading

      if (result.success) {
        _showSnackBar('✓ ${AppLocalizations.of(context)?.success ?? 'نجح'}', isError: false);
        // Reload conversation to update status
        await _loadConversation();
      } else {
        _showSnackBar(result.error ?? '${AppLocalizations.of(context)?.failed ?? 'فشل'}', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${e.toString()}', isError: true);
    }
  }

  /// Confirm completion - Client confirms service is completed
  Future<void> _confirmCompletion() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.confirmCompletionButton ?? 'تأكيد اكتمال الخدمة'),
        content: Text(
          AppLocalizations.of(context)?.confirmCompletionMessage ?? 'هل تؤكد أن الخدمة قد تمت بالفعل وبشكل مُرضي؟\n\nبعد التأكيد، سيتم إغلاق الحجز.',
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: Text(AppLocalizations.of(context)?.yesConfirm ?? 'نعم، تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await BookingService.confirmCompletion(widget.bookingId);
      Navigator.pop(context); // Close loading

      if (result.success) {
        _showSnackBar('✓ ${AppLocalizations.of(context)?.success ?? 'نجح'}', isError: false);
        // Reload conversation to update status
        await _loadConversation();

        // Show rating dialog after successful completion
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showRatingDialog();
          }
        });
      } else {
        _showSnackBar(result.error ?? '${AppLocalizations.of(context)?.failed ?? 'فشل'}', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${e.toString()}', isError: true);
    }
  }

  void _navigateToOtherUserProfile() {

    if (_conversation == null || _currentUser == null) {
      return;
    }

    final otherUser = _conversation!.getOtherUser(_currentUser!.id);

    // Navigate based on user role
    if (otherUser.isProvider) {
      // Navigate to Provider Details Screen using otherUser.id
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderDetailsScreen(
            providerId: otherUser.id,
          ),
        ),
      );
    } else if (otherUser.isClient) {
      // Navigate to Client Details Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailsScreen(
            clientUser: otherUser,
          ),
        ),
      );
    }
  }

  void _showPaymentDialog() async {
    // No loading dialog - open payment directly for better UX
    try {
      // Fetch booking details to get the actual agreed price
      final booking = await BookingService.getBookingDetails(widget.bookingId);

      if (booking == null) {
        _showSnackBar('${AppLocalizations.of(context)?.failed ?? 'فشل'} ${AppLocalizations.of(context)?.failedToFetchBooking ?? 'في جلب بيانات الحجز'}', isError: true);
        return;
      }

      // Use the agreed price from the booking
      final amount = booking.agreedPrice.toStringAsFixed(2);

      // Get latest user data to ensure we have the most recent country information
      final latestUser = await StorageService.getUser();

      // Determine currency based on user's country using CurrencyHelper
      final currency = CurrencyHelper.getCurrencyForUser(latestUser ?? _currentUser);

      // Force PRODUCTION environment (no dialog selection)
      final environment = 'PRODUCTION';

      // Open PaySky Payment in iframe dialog (popup)
      // iframe provides better integration and user experience

      final result = await PaySkyIframeDialog.show(
        context: context,
        bookingId: widget.bookingId,
        amount: amount,
        currency: currency,
        environment: environment,
      );

      // Handle payment result
      // The iframe dialog already shows success/failure screens
      // We just need to reload conversation if payment was successful
      if (result != null && result.success) {

        // Reload conversation to update booking status and show provider buttons
        await _loadConversation();
      } else {
        if (result != null) {
        }
      }
    } catch (e) {
      // Show error if booking fetch fails
      _showSnackBar('${AppLocalizations.of(context)?.error ?? 'خطأ'} ${AppLocalizations.of(context)?.errorFetchingBooking ?? 'في جلب بيانات الحجز'}: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print booking status

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _navigateToOtherUserProfile,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connectionState == WebSocketState.connected
                        ? Colors.green
                        : _connectionState == WebSocketState.connecting
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connectionState == WebSocketState.connected
                      ? AppLocalizations.of(context)?.online ?? 'متصل'
                      : _connectionState == WebSocketState.connecting
                          ? AppLocalizations.of(context)?.connectingStatus ?? 'جاري الاتصال...'
                          : AppLocalizations.of(context)?.offline ?? 'غير متصل',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4F46E5),
        actions: [
          // Retry connection button (only show when disconnected or error)
          if (_connectionState == WebSocketState.disconnected ||
              _connectionState == WebSocketState.error)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                if (_wsService != null) {
                  await _wsService!.retry();
                }
              },
              tooltip: AppLocalizations.of(context)?.retry ?? 'إعادة المحاولة',
            ),
          // Rating placeholder button
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: _showRatingDialog,
            tooltip: AppLocalizations.of(context)?.rating ?? 'تقييم',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الخدمة: ${_conversation?.serviceName ?? AppLocalizations.of(context)?.noData ?? "غير محدد"} • حالة الحجز: ${_getBookingStatusText()}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Payment button for clients only
                if (_currentUser != null && _currentUser!.isClient)
                  _AnimatedPaymentButton(
                    onPressed: _showPaymentDialog,
                  ),

                // Start service button for provider after payment completed
                if (_currentUser != null &&
                    !_currentUser!.isClient &&
                    _conversation?.bookingStatus == 'PAYMENT_COMPLETED')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startService,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Theme.of(context).colorScheme.surface,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)?.startServiceButton ?? 'بدء الخدمة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Complete service button for provider during service
                if (_currentUser != null &&
                    !_currentUser!.isClient &&
                    _conversation?.bookingStatus == 'IN_PROGRESS')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B),
                          const Color(0xFFD97706),
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _completeService,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.surface,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)?.completeServiceButton ?? 'إنهاء الخدمة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Confirm completion button for client after provider completes
                if (_currentUser != null &&
                    _currentUser!.isClient &&
                    _conversation?.bookingStatus == 'PENDING_COMPLETION')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6),
                          const Color(0xFF2563EB),
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _confirmCompletion,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Theme.of(context).colorScheme.surface,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)?.confirmCompletionButton ?? 'تأكيد اكتمال الخدمة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)?.noData ?? 'لا توجد بيانات',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابدأ المحادثة بإرسال رسالة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMe = _currentUser != null &&
                                      message.sender.id == _currentUser!.id;

                                  return _buildMessageBubble(message, isMe);
                                },
                              ),
                            ),
                            // Typing indicator
                            if (_typingUserId != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildTypingDot(),
                                        const SizedBox(width: 4),
                                        _buildTypingDot(delay: 200),
                                        const SizedBox(width: 4),
                                        _buildTypingDot(delay: 400),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // Message input
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity( 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.typeMessage ?? 'اكتب رسالة...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: const Color(0xFF4F46E5),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2D2D2D)
                                : Colors.grey[100],
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onChanged: _onTextChanged,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF4F46E5),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.surface),
                                onPressed: _sendMessage,
                                padding: EdgeInsets.zero,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4F46E5) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
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
      return '${AppLocalizations.of(context)?.yesterdayLabel ?? 'أمس'} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getBookingStatusText() {
    if (_conversation == null) return '';

    switch (_conversation!.bookingStatus) {
      case 'CONFIRMED':
        return AppLocalizations.of(context)?.confirmedStatus ?? 'مؤكد';
      case 'PAYMENT_COMPLETED':
        return AppLocalizations.of(context)?.paymentCompletedStatus ?? 'تم الدفع';
      case 'IN_PROGRESS':
        return AppLocalizations.of(context)?.inProgress ?? 'جاري التنفيذ';
      case 'PENDING_COMPLETION':
        return AppLocalizations.of(context)?.pendingCompletionStatus ?? 'في انتظار التأكيد';
      case 'COMPLETED':
        return AppLocalizations.of(context)?.completed ?? 'مكتمل';
      case 'CANCELED':
        return AppLocalizations.of(context)?.cancelled ?? 'ملغي';
      default:
        return _conversation!.bookingStatus;
    }
  }

  /// Build animated typing dot
  Widget _buildTypingDot({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Rebuild to restart animation
        if (mounted && _typingUserId != null) {
          setState(() {});
        }
      },
    );
  }
}

/// Animated Payment Button with bounce effect and shimmer
class _AnimatedPaymentButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedPaymentButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_AnimatedPaymentButton> createState() => _AnimatedPaymentButtonState();
}

class _AnimatedPaymentButtonState extends State<_AnimatedPaymentButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -12.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 75,
      ),
    ]).animate(_bounceController);

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _bounceController.repeat(reverse: false);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF4F46E5),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(18),
                splashColor: const Color(0xFF4F46E5).withOpacity(0.1),
                highlightColor: const Color(0xFF4F46E5).withOpacity(0.05),
                child: Stack(
                  children: [
                    // Shimmer effect overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Transform.translate(
                          offset: Offset(_shimmerAnimation.value * 400, 0),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF4F46E5).withOpacity(0.15),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Button content
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5),
                                  const Color(0xFF4338CA),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.payment_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            AppLocalizations.of(context)?.completePaymentButton ?? 'إتمام الدفع',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Color(0xFF4F46E5),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
