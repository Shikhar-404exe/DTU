

library;

class ApiConfig {

  static const String baseUrl = 'http://localhost:8000';

  static const String devUrl = 'http://localhost:8000';

  static const String prodUrl = 'https://your-production-url.com';

  static String get currentBaseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? prodUrl : devUrl;
  }

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

  static const String ttsSynthesize = '/tts/synthesize';
  static const String ttsVoices = '/tts/voices';
  static const String ttsHealth = '/tts/health';

  static const String sttRecognize = '/stt/recognize';
  static const String sttLanguages = '/stt/languages';
  static const String sttHealth = '/stt/health';

  static const String youtubeSearch = '/youtube/search';
  static String youtubeVideo(String videoId) => '/youtube/video/$videoId';
  static String youtubeChannels(String subject) => '/youtube/channels/$subject';
  static const String youtubeHealth = '/youtube/health';

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
