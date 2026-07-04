/// WebSocket Message Models for Real-time Chat
/// Handles all message types sent/received via WebSocket

import 'chat_model.dart';

/// WebSocket message types
enum WebSocketMessageType {
  chatMessage,
  typing,
  markRead,
  messageReadUpdate,
  connectionEstablished,
  error,
}

/// Base WebSocket message
class WebSocketMessage {
  final WebSocketMessageType type;
  final dynamic data;

  WebSocketMessage({
    required this.type,
    required this.data,
  });

  /// Create from JSON received from WebSocket
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final String typeStr = json['type'] ?? '';

    WebSocketMessageType type;
    switch (typeStr) {
      case 'chat_message':
        type = WebSocketMessageType.chatMessage;
        break;
      case 'typing':
        type = WebSocketMessageType.typing;
        break;
      case 'mark_read':
        type = WebSocketMessageType.markRead;
        break;
      case 'message_read_update':
        type = WebSocketMessageType.messageReadUpdate;
        break;
      case 'connection_established':
        type = WebSocketMessageType.connectionEstablished;
        break;
      case 'error':
        type = WebSocketMessageType.error;
        break;
      default:
        type = WebSocketMessageType.error;
    }

    return WebSocketMessage(
      type: type,
      data: json,
    );
  }

  /// Convert to JSON to send via WebSocket
  Map<String, dynamic> toJson() {
    String typeStr;
    switch (type) {
      case WebSocketMessageType.chatMessage:
        typeStr = 'chat_message';
        break;
      case WebSocketMessageType.typing:
        typeStr = 'typing';
        break;
      case WebSocketMessageType.markRead:
        typeStr = 'mark_read';
        break;
      case WebSocketMessageType.messageReadUpdate:
        typeStr = 'message_read_update';
        break;
      case WebSocketMessageType.connectionEstablished:
        typeStr = 'connection_established';
        break;
      case WebSocketMessageType.error:
        typeStr = 'error';
        break;
    }

    return {
      'type': typeStr,
      ...data as Map<String, dynamic>,
    };
  }
}

/// Chat message received via WebSocket
class WebSocketChatMessage {
  final Message message;

  WebSocketChatMessage({required this.message});

  factory WebSocketChatMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketChatMessage(
      message: Message.fromJson(json['message']),
    );
  }
}

/// Typing indicator message
class WebSocketTypingMessage {
  final int userId;
  final bool isTyping;

  WebSocketTypingMessage({
    required this.userId,
    required this.isTyping,
  });

  factory WebSocketTypingMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketTypingMessage(
      userId: json['user_id'],
      isTyping: json['is_typing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_typing': isTyping,
    };
  }
}

/// Error message from WebSocket
class WebSocketErrorMessage {
  final String message;

  WebSocketErrorMessage({required this.message});

  factory WebSocketErrorMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketErrorMessage(
      message: json['message'] ?? 'حدث خطأ غير معروف',
    );
  }
}

/// Connection established message
class WebSocketConnectionMessage {
  final String message;

  WebSocketConnectionMessage({required this.message});

  factory WebSocketConnectionMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketConnectionMessage(
      message: json['message'] ?? 'تم الاتصال بنجاح',
    );
  }
}

/// Message read update notification
class WebSocketMessageReadUpdate {
  final int messageId;
  final String? readAt;

  WebSocketMessageReadUpdate({
    required this.messageId,
    required this.readAt,
  });

  factory WebSocketMessageReadUpdate.fromJson(Map<String, dynamic> json) {
    return WebSocketMessageReadUpdate(
      messageId: json['message_id'],
      readAt: json['read_at'],
    );
  }
}

/// Helper to create outgoing messages
class WebSocketMessageFactory {
  /// Create a chat message to send
  static Map<String, dynamic> createChatMessage(String content) {
    return {
      'type': 'chat_message',
      'message': content,
    };
  }

  /// Create a typing indicator message
  static Map<String, dynamic> createTypingMessage(bool isTyping) {
    return {
      'type': 'typing',
      'is_typing': isTyping,
    };
  }

  /// Create a mark read message
  static Map<String, dynamic> createMarkReadMessage(int messageId) {
    return {
      'type': 'mark_read',
      'message_id': messageId,
    };
  }
}
