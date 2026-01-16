/// API Configuration
/// Central configuration for all backend API endpoints

class ApiConfig {
  // Base URL - Update this for production
  static const String baseUrl = 'http://localhost:8000';

  // Development/Testing URL
  static const String devUrl = 'http://localhost:8000';

  // Production URL (update when deploying)
  static const String prodUrl = 'https://your-production-url.com';

  // Use dev or prod based on build mode
  static String get currentBaseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? prodUrl : devUrl;
  }

  // Chatbot endpoints
  static const String chatbotSession = '/chatbot/session';
  static const String chatbotChat = '/chatbot/chat';
  static String chatbotHistory(String sessionId) =>
      '/chatbot/session/$sessionId/history';
  static String chatbotUserSessions(String userId) =>
      '/chatbot/user/$userId/sessions';
  static String chatbotSessionUpdate(String sessionId) =>
      '/chatbot/session/$sessionId';
  static String chatbotSearch(String userId) => '/chatbot/user/$userId/search';
  static const String chatbotStats = '/chatbot/stats';
  static const String chatbotHealth = '/chatbot/health';

  // TTS endpoints
  static const String ttsSynthesize = '/tts/synthesize';
  static const String ttsVoices = '/tts/voices';
  static const String ttsHealth = '/tts/health';

  // STT endpoints
  static const String sttRecognize = '/stt/recognize';
  static const String sttLanguages = '/stt/languages';
  static const String sttHealth = '/stt/health';

  // YouTube endpoints
  static const String youtubeSearch = '/youtube/search';
  static String youtubeVideo(String videoId) => '/youtube/video/$videoId';
  static String youtubeChannels(String subject) => '/youtube/channels/$subject';
  static const String youtubeHealth = '/youtube/health';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
