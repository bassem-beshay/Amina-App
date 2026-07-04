// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: (json['id'] as num).toInt(),
  booking: (json['booking'] as num).toInt(),
  bookingId: (json['booking_id'] as num).toInt(),
  bookingStatus: json['booking_status'] as String,
  serviceName: json['service_name'] as String,
  serviceNameEn: json['service_name_en'] as String?,
  client: User.fromJson(json['client'] as Map<String, dynamic>),
  provider: User.fromJson(json['provider'] as Map<String, dynamic>),
  lastMessage: json['last_message'] == null
      ? null
      : Message.fromJson(json['last_message'] as Map<String, dynamic>),
  unreadCount: (json['unread_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  messages: (json['messages'] as List<dynamic>?)
      ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking': instance.booking,
      'booking_id': instance.bookingId,
      'booking_status': instance.bookingStatus,
      'service_name': instance.serviceName,
      'service_name_en': instance.serviceNameEn,
      'client': instance.client,
      'provider': instance.provider,
      'last_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'messages': instance.messages,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: (json['id'] as num).toInt(),
  conversation: (json['conversation'] as num).toInt(),
  sender: User.fromJson(json['sender'] as Map<String, dynamic>),
  content: json['content'] as String,
  isRead: json['is_read'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  readAt: json['read_at'] == null
      ? null
      : DateTime.parse(json['read_at'] as String),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversation': instance.conversation,
  'sender': instance.sender,
  'content': instance.content,
  'is_read': instance.isRead,
  'created_at': instance.createdAt.toIso8601String(),
  'read_at': instance.readAt?.toIso8601String(),
};
