import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class Conversation {
  final int id;
  final int booking;
  @JsonKey(name: 'booking_id')
  final int bookingId;
  @JsonKey(name: 'booking_status')
  final String bookingStatus;
  @JsonKey(name: 'service_name')
  final String serviceName;
  @JsonKey(name: 'service_name_en')
  final String? serviceNameEn;
  final User client;
  final User provider;
  @JsonKey(name: 'last_message')
  final Message? lastMessage;
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final List<Message>? messages;

  Conversation({
    required this.id,
    required this.booking,
    required this.bookingId,
    required this.bookingStatus,
    required this.serviceName,
    this.serviceNameEn,
    required this.client,
    required this.provider,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  /// Get the other user in the conversation (not the current user)
  User getOtherUser(int currentUserId) {
    return client.id == currentUserId ? provider : client;
  }
}

@JsonSerializable()
class Message {
  final int id;
  final int conversation;
  final User sender;
  final String content;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  Message({
    required this.id,
    required this.conversation,
    required this.sender,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  /// Check if this message was sent by the current user
  bool isSentByMe(int currentUserId) {
    return sender.id == currentUserId;
  }
}

/// Request model for creating a conversation
class CreateConversationRequest {
  final int booking;

  CreateConversationRequest({required this.booking});

  Map<String, dynamic> toJson() => {
        'booking': booking,
      };
}

/// Request model for sending a message
class SendMessageRequest {
  final int conversation;
  final String content;

  SendMessageRequest({
    required this.conversation,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'conversation': conversation,
        'content': content,
      };
}

/// Request model for marking conversation as read
class MarkConversationReadRequest {
  final int conversation;

  MarkConversationReadRequest({required this.conversation});

  Map<String, dynamic> toJson() => {
        'conversation': conversation,
      };
}
