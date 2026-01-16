/// Chatbot Service
/// Handles all chatbot API interactions

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

enum ChatMode {
  offline,
  online,
  auto,
}

class ChatMessage {
  final String role;
  final String content;
  final String? agentId;
  final String? mode;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.agentId,
    this.mode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      agentId: json['agent_id'],
      mode: json['mode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (agentId != null) 'agent_id': agentId,
        if (mode != null) 'mode': mode,
        'timestamp': timestamp.toIso8601String(),
      };

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatSession {
  final String sessionId;
  final String userId;
  final String title;
  final ChatMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ChatSession({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'],
      userId: json['user_id'],
      title: json['title'],
      mode: _parseChatMode(json['mode']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'],
    );
  }

  static ChatMode _parseChatMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'offline':
        return ChatMode.offline;
      case 'online':
        return ChatMode.online;
      default:
        return ChatMode.auto;
    }
  }
}

class ChatbotService {
  static Future<String?> createSession({
    required String userId,
    ChatMode mode = ChatMode.auto,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.chatbotSession}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'user_id': userId,
              'mode': mode.name,
              if (metadata != null) 'metadata': metadata,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['session_id'];
      } else {
        print('Failed to create session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendMessage({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
    ChatMode? mode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.chatbotChat}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'session_id': sessionId,
              'message': message,
              if (context != null) 'context': context,
              if (mode != null) 'mode': mode.name,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to send message: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to send message'};
      }
    } catch (e) {
      print('Error sending message: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<ChatMessage>> getHistory({
    required String sessionId,
    int? limit,
  }) async {
    try {
      var url =
          '${ApiConfig.currentBaseUrl}${ApiConfig.chatbotHistory(sessionId)}';
      if (limit != null) {
        url += '?limit=$limit';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        return messages.map((m) => ChatMessage.fromJson(m)).toList();
      } else {
        print('Failed to get history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  static Future<List<ChatSession>> getUserSessions({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final url =
          '${ApiConfig.currentBaseUrl}${ApiConfig.chatbotUserSessions(userId)}?limit=$limit';

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = data['sessions'] as List;
        return sessions.map((s) => ChatSession.fromJson(s)).toList();
      } else {
        print('Failed to get sessions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting sessions: $e');
      return [];
    }
  }

  static Future<bool> updateSessionTitle({
    required String sessionId,
    required String title,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                '${ApiConfig.currentBaseUrl}${ApiConfig.chatbotSessionUpdate(sessionId)}'),
            headers: ApiConfig.headers,
            body: jsonEncode({'title': title}),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  static Future<bool> deleteSession(String sessionId) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConfig.currentBaseUrl}${ApiConfig.chatbotSessionUpdate(sessionId)}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting session: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> searchConversations({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final url =
          '${ApiConfig.currentBaseUrl}${ApiConfig.chatbotSearch(userId)}?query=$query&limit=$limit';

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        print('Failed to search: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.chatbotStats}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'];
      }
      return null;
    } catch (e) {
      print('Error getting stats: $e');
      return null;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.chatbotHealth}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
