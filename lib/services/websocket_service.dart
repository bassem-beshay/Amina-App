/// WebSocket Service for Real-time Chat
/// Manages WebSocket connections, reconnections, and message handling

import 'dart:async';
import 'dart:convert';
import 'dart:io'; // 🔧 FIX: Import dart:io for WebSocket
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // 🔧 FIX: Import IOWebSocketChannel
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';
import '../models/websocket_message.dart';
import '../models/chat_model.dart';

enum WebSocketState {
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;
  StreamController<WebSocketTypingMessage>? _typingController;
  StreamController<WebSocketState>? _stateController;
  StreamController<String>? _errorController;
  StreamController<WebSocketMessageReadUpdate>? _readUpdateController;

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  final Duration _reconnectDelay = const Duration(seconds: 3);
  static const int _maxReconnectAttempts = 10; // Maximum reconnection attempts
  bool _isDisposed = false; // Track if service is disposed

  int? _conversationId;
  String? _authToken;
  WebSocketState _currentState = WebSocketState.disconnected;

  // Getters for streams
  Stream<Message> get messageStream => _messageController!.stream;
  Stream<WebSocketTypingMessage> get typingStream => _typingController!.stream;
  Stream<WebSocketState> get stateStream => _stateController!.stream;
  Stream<String> get errorStream => _errorController!.stream;
  Stream<WebSocketMessageReadUpdate> get readUpdateStream => _readUpdateController!.stream;
  WebSocketState get currentState => _currentState;
  bool get isConnected => _currentState == WebSocketState.connected;

  WebSocketService() {
    _messageController = StreamController<Message>.broadcast();
    _typingController = StreamController<WebSocketTypingMessage>.broadcast();
    _stateController = StreamController<WebSocketState>.broadcast();
    _errorController = StreamController<String>.broadcast();
    _readUpdateController = StreamController<WebSocketMessageReadUpdate>.broadcast();
  }

  /// Connect to WebSocket for a specific conversation
  Future<void> connect(int conversationId, String authToken) async {
    // Don't connect if disposed
    if (_isDisposed) {
      return;
    }

    if (_currentState == WebSocketState.connected &&
        _conversationId == conversationId) {
      return;
    }

    // Disconnect from previous conversation if any
    if (_currentState == WebSocketState.connected) {
      await disconnect();
    }

    _conversationId = conversationId;
    _authToken = authToken;

    _updateState(WebSocketState.connecting);

    try {
      // Build WebSocket URL with token
      final baseWsUrl = ApiConfig.chatWebSocket(conversationId);

      // 🔧 WEBSOCKET FIX: Parse URI properly to handle WSS scheme
      // Uri.parse with wss:// can cause issues, so we build it manually
      final uri = Uri.parse(baseWsUrl).replace(
        queryParameters: {'token': authToken},
      );

      print('🔌 Connecting to WebSocket: $uri'); // Debug log

      // 🔧 FIX: Use native dart:io WebSocket.connect for proper WSS support
      // IOWebSocketChannel was still converting wss:// to https://
      final webSocket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Host': uri.host,
        },
      );

      _channel = IOWebSocketChannel(webSocket);

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      _updateState(WebSocketState.connected);
      print('✅ WebSocket connected successfully');

    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is WebSocketException) {
        print('❌ WebSocket error: ${e.message}');
      }
      _updateState(WebSocketState.error);

      // Don't show full error to user, just friendly message
      if (!_errorController!.isClosed) {
        _errorController!.add('تعذر الاتصال بالخادم');
      }
      _scheduleReconnect();
    }
  }

  /// Manual retry connection (resets attempt counter)
  Future<void> retry() async {
    print('🔄 Manual retry requested');
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_conversationId != null && _authToken != null && !_isDisposed) {
      await connect(_conversationId!, _authToken!);
    }
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic data) {
    try {
      final jsonData = json.decode(data);
      final wsMessage = WebSocketMessage.fromJson(jsonData);

      switch (wsMessage.type) {
        case WebSocketMessageType.chatMessage:
          // New chat message received
          final chatMessage = WebSocketChatMessage.fromJson(jsonData);
          _messageController!.add(chatMessage.message);
          break;

        case WebSocketMessageType.typing:
          // Typing indicator
          final typingMessage = WebSocketTypingMessage.fromJson(jsonData);
          _typingController!.add(typingMessage);
          break;

        case WebSocketMessageType.messageReadUpdate:
          // Message read status update
          final readUpdate = WebSocketMessageReadUpdate.fromJson(jsonData);
          _readUpdateController!.add(readUpdate);
          break;

        case WebSocketMessageType.connectionEstablished:
          // Connection confirmation
          final connectionMessage = WebSocketConnectionMessage.fromJson(jsonData);
          break;

        case WebSocketMessageType.error:
          // Server error
          final errorMessage = WebSocketErrorMessage.fromJson(jsonData);
          _errorController!.add(errorMessage.message);
          break;

        case WebSocketMessageType.markRead:
          // Message marked as read (optional handling)
          break;
      }
    } catch (e) {
    }
  }

  /// Handle WebSocket errors
  void _onError(dynamic error) {
    _updateState(WebSocketState.error);
    if (_errorController != null && !_errorController!.isClosed) {
      _errorController!.add('حدث خطأ في الاتصال');
    }
    _scheduleReconnect();
  }

  /// Handle WebSocket connection close
  void _onDone() {
    _updateState(WebSocketState.disconnected);
    _stopPingTimer();
    _scheduleReconnect();
  }

  /// Send a chat message
  void sendMessage(String content) {
    if (!isConnected) {
      _errorController!.add('غير متصل بالخادم');
      return;
    }

    try {
      final message = WebSocketMessageFactory.createChatMessage(content);
      _channel!.sink.add(json.encode(message));
    } catch (e) {
      _errorController!.add('فشل إرسال الرسالة');
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(bool isTyping) {
    if (!isConnected) return;

    try {
      final message = WebSocketMessageFactory.createTypingMessage(isTyping);
      _channel!.sink.add(json.encode(message));
    } catch (e) {
    }
  }

  /// Mark message as read
  void markMessageRead(int messageId) {
    if (!isConnected) return;

    try {
      final message = WebSocketMessageFactory.createMarkReadMessage(messageId);
      _channel!.sink.add(json.encode(message));
    } catch (e) {
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        // Send empty message as ping
        try {
          _channel!.sink.add(json.encode({'type': 'ping'}));
        } catch (e) {
        }
      }
    });
  }

  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Schedule reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    // Don't reconnect if disposed
    if (_isDisposed) {
      return;
    }

    // Stop reconnecting after max attempts
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateState(WebSocketState.disconnected);
      if (_errorController != null && !_errorController!.isClosed) {
        _errorController!.add('تعذر الاتصال بعد عدة محاولات. يرجى التحقق من الإنترنت والمحاولة لاحقاً');
      }
      return;
    }

    // Don't give up - keep trying with longer delays
    if (_reconnectTimer?.isActive == true) {
      return; // Already scheduled
    }

    _reconnectAttempts++;

    // Exponential backoff: 3s, 6s, 12s, 24s, 30s (max)
    final delay = Duration(
      seconds: (_reconnectDelay.inSeconds * _reconnectAttempts).clamp(3, 30),
    );

    print('🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s');

    // Show user-friendly message (only if controller is still active)
    if (_errorController != null && !_errorController!.isClosed) {
      if (_reconnectAttempts <= 3) {
        _errorController!.add('جاري إعادة الاتصال...');
      } else if (_reconnectAttempts <= 6) {
        _errorController!.add('محاولة إعادة الاتصال... تأكد من اتصال الإنترنت');
      } else {
        _errorController!.add('محاولة $_reconnectAttempts من $_maxReconnectAttempts...');
      }
    }

    _reconnectTimer = Timer(delay, () {
      if (_conversationId != null && _authToken != null && !_isDisposed) {
        connect(_conversationId!, _authToken!);
      }
    });
  }

  /// Update connection state
  void _updateState(WebSocketState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (_stateController != null && !_stateController!.isClosed) {
        _stateController!.add(newState);
      }
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopPingTimer();

    if (_channel != null) {
      try {
        await _channel!.sink.close(status.goingAway);
      } catch (e) {
      }
      _channel = null;
    }

    _conversationId = null;
    _authToken = null;
    _reconnectAttempts = 0;
    _updateState(WebSocketState.disconnected);
  }

  /// Dispose of all resources
  void dispose() {
    _isDisposed = true; // Mark as disposed to stop reconnections
    disconnect();
    _messageController?.close();
    _typingController?.close();
    _stateController?.close();
    _errorController?.close();
    _readUpdateController?.close();

    _messageController = null;
    _typingController = null;
    _stateController = null;
    _errorController = null;
    _readUpdateController = null;
  }
}
