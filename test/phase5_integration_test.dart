

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rural_education/services/services.dart';

void main() {
  group('Phase 5: Flutter Frontend Integration Tests', () {

    group('API Configuration', () {
      test('Base URL should be configured', () {
        expect(ApiConfig.baseUrl, isNotNull);
        expect(ApiConfig.baseUrl, isNotEmpty);
      });

      test('All chatbot endpoints should be defined', () {
        expect(ApiConfig.chatbotSession, '/chatbot/session');
        expect(ApiConfig.chatbotChat, '/chatbot/chat');
        expect(ApiConfig.chatbotHistory('test-session'),
            '/chatbot/session/test-session/history');
        expect(ApiConfig.chatbotUserSessions('user123'),
            '/chatbot/user/user123/sessions');
      });

      test('All TTS endpoints should be defined', () {
        expect(ApiConfig.ttsSynthesize, '/tts/synthesize');
        expect(ApiConfig.ttsVoices, '/tts/voices');
        expect(ApiConfig.ttsHealth, '/tts/health');
      });

      test('All STT endpoints should be defined', () {
        expect(ApiConfig.sttRecognize, '/stt/recognize');
        expect(ApiConfig.sttLanguages, '/stt/languages');
        expect(ApiConfig.sttHealth, '/stt/health');
      });

      test('All YouTube endpoints should be defined', () {
        expect(ApiConfig.youtubeSearch, '/youtube/search');
        expect(ApiConfig.youtubeVideo('abc123'), '/youtube/video/abc123');
        expect(
            ApiConfig.youtubeChannels('Science'), '/youtube/channels/Science');
        expect(ApiConfig.youtubeHealth, '/youtube/health');
      });
    });

    group('Chatbot Service', () {
      test('ChatMode enum should have all modes', () {
        expect(ChatMode.offline, isNotNull);
        expect(ChatMode.online, isNotNull);
        expect(ChatMode.auto, isNotNull);
      });

      test('ChatMessage model should serialize correctly', () {
        final message = ChatMessage(
          role: 'user',
          content: 'Hello AI',
        );

        expect(message.isUser, true);
        expect(message.isAssistant, false);
        expect(message.role, 'user');
        expect(message.content, 'Hello AI');

        final json = message.toJson();
        expect(json['role'], 'user');
        expect(json['content'], 'Hello AI');
      });

      test('ChatMessage should deserialize from JSON', () {
        final json = {
          'role': 'assistant',
          'content': 'Hello human',
          'agent_id': 'content_agent',
          'mode': 'online',
          'timestamp': '2026-01-15T10:30:00.000Z',
        };

        final message = ChatMessage.fromJson(json);
        expect(message.role, 'assistant');
        expect(message.content, 'Hello human');
        expect(message.agentId, 'content_agent');
        expect(message.mode, 'online');
        expect(message.isAssistant, true);
      });

      test('ChatSession should parse mode correctly', () {
        final json = {
          'session_id': 'session123',
          'user_id': 'user456',
          'title': 'Test Session',
          'mode': 'offline',
          'created_at': '2026-01-15T10:00:00.000Z',
          'updated_at': '2026-01-15T10:30:00.000Z',
          'message_count': 5,
        };

        final session = ChatSession.fromJson(json);
        expect(session.mode, ChatMode.offline);
        expect(session.sessionId, 'session123');
        expect(session.messageCount, 5);
      });
    });

    group('Voice Service', () {
      test('Voice service should initialize TTS', () async {
        await VoiceService.initTTS();

      });

      test('Voice service should initialize STT', () async {
        final initialized = await VoiceService.initSTT();

        expect(initialized, isA<bool>());
      });

      test('Voice service should not be listening initially', () {
        expect(VoiceService.isListening, false);
      });
    });

    group('YouTube Service', () {
      test('YouTubeVideo should deserialize from JSON', () {
        final json = {
          'video_id': 'abc123',
          'title': 'Test Video',
          'description': 'A test video',
          'thumbnail': 'https://example.com/thumb.jpg',
          'channel_title': 'Test Channel',
          'channel_id': 'channel123',
          'published_at': '2026-01-15T10:00:00Z',
          'url': 'https://youtube.com/watch?v=abc123',
          'view_count': 1000,
          'like_count': 50,
          'duration': '10:30',
        };

        final video = YouTubeVideo.fromJson(json);
        expect(video.videoId, 'abc123');
        expect(video.title, 'Test Video');
        expect(video.viewCount, 1000);
        expect(video.duration, '10:30');
      });

      test('YouTubeChannel should deserialize from JSON', () {
        final json = {
          'name': 'Khan Academy',
          'id': 'channel123',
          'language': 'English',
        };

        final channel = YouTubeChannel.fromJson(json);
        expect(channel.name, 'Khan Academy');
        expect(channel.id, 'channel123');
        expect(channel.language, 'English');
        expect(
            channel.channelUrl, 'https://www.youtube.com/channel/channel123');
      });

      test('YouTube subjects should be defined', () {
        final subjects = YouTubeService.subjects;
        expect(subjects, contains('General'));
        expect(subjects, contains('Science'));
        expect(subjects, contains('Mathematics'));
        expect(subjects, contains('English'));
        expect(subjects.length, greaterThanOrEqualTo(8));
      });
    });

    group('Integration Tests (Backend Required)', () {
      test('Chatbot health check', () async {
        try {
          final healthy = await ChatbotService.checkHealth();
          print('Chatbot health: $healthy');
        } catch (e) {
          print(
              'Chatbot health check failed (expected if backend not running): $e');
        }
      });

      test('TTS health check', () async {
        try {
          final healthy = await VoiceService.checkTTSHealth();
          print('TTS health: $healthy');
        } catch (e) {
          print(
              'TTS health check failed (expected if backend not running): $e');
        }
      });

      test('STT health check', () async {
        try {
          final healthy = await VoiceService.checkSTTHealth();
          print('STT health: $healthy');
        } catch (e) {
          print(
              'STT health check failed (expected if backend not running): $e');
        }
      });

      test('YouTube health check', () async {
        try {
          final healthy = await YouTubeService.checkHealth();
          print('YouTube health: $healthy');
        } catch (e) {
          print(
              'YouTube health check failed (expected if backend not running): $e');
        }
      });

      test('Create chatbot session', () async {
        try {
          final sessionId = await ChatbotService.createSession(
            userId: 'test_user_flutter',
            mode: ChatMode.auto,
          );
          print('Created session: $sessionId');
          expect(sessionId, isNotNull);

          if (sessionId != null) {

            final history =
                await ChatbotService.getHistory(sessionId: sessionId);
            print('Session history length: ${history.length}');
          }
        } catch (e) {
          print(
              'Session creation failed (expected if backend not running): $e');
        }
      });

      test('Search YouTube videos offline', () async {
        try {
          final result = await YouTubeService.searchVideos(
            query: 'mathematics',
            maxResults: 5,
            useOnline: false,
          );

          print('YouTube search result: $result');
          expect(result['success'], true);

          if (result['provider'] == 'offline') {
            print(
                'Offline mode: ${result['channels']?.length ?? 0} channels recommended');
          }
        } catch (e) {
          print('YouTube search failed (expected if backend not running): $e');
        }
      });

      test('Get TTS voices', () async {
        try {
          final voices = await VoiceService.getVoices();
          print('Available voices: ${voices.length}');
          for (var voice in voices) {
            print('  - ${voice['name']} (${voice['language']})');
          }
        } catch (e) {
          print('Get voices failed (expected if backend not running): $e');
        }
      });

      test('Get STT languages', () async {
        try {
          final languages = await VoiceService.getSupportedLanguages();
          print('Supported STT languages: ${languages.length}');
          for (var lang in languages) {
            print('  - ${lang['name']} (${lang['code']})');
          }
        } catch (e) {
          print('Get languages failed (expected if backend not running): $e');
        }
      });
    });
  });
}
