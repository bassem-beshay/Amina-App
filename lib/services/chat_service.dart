import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/chat_model.dart';
import 'storage_service.dart';

class ChatService {
  /// Get user's conversations
  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.chatConversations}';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final conversations = data.map((json) => Conversation.fromJson(json)).toList();
        return conversations;
      } else {
        throw Exception('فشل في جلب المحادثات');
      }
    } catch (e, stackTrace) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Get conversation by booking ID
  static Future<Conversation> getConversationByBooking(int bookingId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.chatConversationByBooking(bookingId)}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('فشل في جلب المحادثة');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Get conversation details with messages
  static Future<Conversation> getConversationDetails(int conversationId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.chatConversationDetail(conversationId)}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('فشل في جلب تفاصيل المحادثة');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Create or get conversation for a booking
  static Future<Conversation> createConversation(int bookingId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final request = CreateConversationRequest(booking: bookingId);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatConversations}'),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('فشل في إنشاء المحادثة');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Get messages for a conversation
  static Future<List<Message>> getMessages(int conversationId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.chatMessages}?conversation=$conversationId'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('فشل في جلب الرسائل');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Get messages since a specific timestamp (for efficient polling)
  static Future<List<Message>> getMessagesSince(int conversationId, DateTime since) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      // Format timestamp as ISO 8601
      final sinceStr = since.toIso8601String();
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.chatMessages}?conversation=$conversationId&since=$sinceStr'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('فشل في جلب الرسائل');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Send a message
  static Future<Message> sendMessage(int conversationId, String content) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final request = SendMessageRequest(
        conversation: conversationId,
        content: content,
      );

      final url = '${ApiConfig.baseUrl}${ApiConfig.chatMessages}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(request.toJson()),
      );


      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data);
      } else {
        throw Exception('فشل في إرسال الرسالة: \u200F${response.body}\u200F');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Mark a message as read
  static Future<void> markMessageRead(int messageId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.markMessageRead(messageId)}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل في تعليم الرسالة كمقروءة');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }

  /// Mark all messages in a conversation as read
  static Future<Conversation?> markConversationRead(int conversationId) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }

      final request = MarkConversationReadRequest(conversation: conversationId);
      final url = '${ApiConfig.baseUrl}${ApiConfig.markConversationRead}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(request.toJson()),
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract the updated conversation from response
        if (data['conversation'] != null) {
          final conversation = Conversation.fromJson(data['conversation']);
          return conversation;
        }
        return null;
      } else {
        throw Exception('فشل في تعليم المحادثة كمقروءة: \u200F${response.body}\u200F');
      }
    } catch (e, stackTrace) {
      throw Exception('خطأ في الاتصال: \u200F$e\u200F');
    }
  }
}
