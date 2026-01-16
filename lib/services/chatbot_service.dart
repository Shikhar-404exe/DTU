

library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../core/constants/app_constants.dart';

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

  static final Map<String, String> _localGuidance = {
    'help': '''I can help you navigate the app! Here are the main features:
• **Home**: Your dashboard with all features
• **Doubts**: Record voice notes and share doubts with peers
• **AI Chat**: Chat with AI assistant (that's me!)
• **Profile**: Manage your settings

What would you like to know more about?''',
    'doubts': '''The **Doubts** section helps you:
• Record voice notes with your questions
• Add text doubts organized by subject
• Share doubts via QR code or P2P
• Mark doubts as resolved when answered

Tap the microphone button to start recording!''',
    'scanner': '''The **PDF Scanner** lets you:
• Scan handwritten notes or documents
• Apply filters (Enhance, High Contrast, Lighten)
• Save scans as PDF files
• Share your scanned documents

Just point your camera at the document and tap capture!''',
    'photomath': '''**Photomath** feature helps with:
• Capturing math problems with your camera
• Getting step-by-step solutions
• AI-powered problem solving when OCR fails

Just photograph any math equation and get solutions!''',
    'videos': '''The **Videos** section provides:
• Educational content from YouTube
• Subject-wise video organization
• Search for specific topics

Browse educational videos to enhance learning!''',
    'notes': '''The **Notes** feature allows you:
• Create and organize study notes
• AI-generated summaries
• Subject-wise categorization

Keep all your study material in one place!''',
    'offline': '''When **offline**, you can still:
• View previously loaded content
• Record voice doubts
• Use the scanner
• Access cached videos

I'll guide you through the app even without internet!''',
    'default': '''Hi! I'm your Vidyarthi AI assistant. I can help you:
• Navigate the app features
• Answer questions about subjects
• Provide study guidance

Try asking about: doubts, scanner, photomath, videos, or notes!'''
  };

  static String _getLocalResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('help') || lowerMessage.contains('what can')) {
      return _localGuidance['help']!;
    } else if (lowerMessage.contains('doubt') ||
        lowerMessage.contains('voice') ||
        lowerMessage.contains('record')) {
      return _localGuidance['doubts']!;
    } else if (lowerMessage.contains('scan') ||
        lowerMessage.contains('pdf') ||
        lowerMessage.contains('document')) {
      return _localGuidance['scanner']!;
    } else if (lowerMessage.contains('math') ||
        lowerMessage.contains('photomath') ||
        lowerMessage.contains('equation')) {
      return _localGuidance['photomath']!;
    } else if (lowerMessage.contains('video') ||
        lowerMessage.contains('youtube') ||
        lowerMessage.contains('watch')) {
      return _localGuidance['videos']!;
    } else if (lowerMessage.contains('note') ||
        lowerMessage.contains('summary') ||
        lowerMessage.contains('study')) {
      return _localGuidance['notes']!;
    } else if (lowerMessage.contains('offline') ||
        lowerMessage.contains('internet') ||
        lowerMessage.contains('connection')) {
      return _localGuidance['offline']!;
    } else if (lowerMessage.contains('hello') ||
        lowerMessage.contains('hi') ||
        lowerMessage.contains('hey')) {
      return _localGuidance['default']!;
    }

    return _localGuidance['default']!;
  }

  static Future<Map<String, dynamic>?> _callOpenRouter(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
              'HTTP-Referer': 'https://vidyarthi.app',
              'X-Title': 'Vidyarthi AI Assistant',
            },
            body: jsonEncode({
              'model': AppConstants.openRouterModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are Vidyarthi AI Assistant, a helpful educational chatbot for rural students in India.
You help students with:
- Understanding app features (Doubts section, PDF Scanner, Photomath, Videos, Notes)
- Answering academic questions across subjects
- Providing study tips and guidance
- Explaining concepts in simple terms

Be friendly, supportive, and explain things clearly. Use simple language suitable for students.
Keep responses concise but helpful.'''
                },
                {'role': 'user', 'content': message}
              ],
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return {
          'success': true,
          'response': content,
          'agent_id': 'openrouter',
          'mode': 'online',
        };
      }
      return null;
    } catch (e) {
      print('OpenRouter error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendMessage({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
    ChatMode? mode,
  }) async {

    if (mode == ChatMode.offline) {
      return {
        'success': true,
        'response': _getLocalResponse(message),
        'agent_id': 'local_guide',
        'mode': 'offline',
      };
    }

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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Backend error: $e');
    }

    final openRouterResponse = await _callOpenRouter(message);
    if (openRouterResponse != null) {
      return openRouterResponse;
    }

    return {
      'success': true,
      'response': _getLocalResponse(message),
      'agent_id': 'local_guide',
      'mode': 'offline',
    };
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
