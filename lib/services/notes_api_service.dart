import 'gemini_service.dart';

/// AI Provider enum for selecting which AI to use
enum AiProvider { gemini, auto }

class NotesApiService {
  /// Generate notes using Gemini AI (Firebase integration)
  /// No local backend needed - all AI processing via Firebase/Gemini
  static Future<Map<String, dynamic>> generateNote(Map<String, dynamic> payload,
      {AiProvider provider = AiProvider.auto}) async {
    // Always use Gemini AI - it's integrated with Firebase
    return await generateNoteWithGemini(payload);
  }

  /// Generate notes using only Gemini AI
  static Future<Map<String, dynamic>> generateNoteWithGemini(
      Map<String, dynamic> payload) async {
    final result = await GeminiService.generateNotes(
      subject: payload['subject']?.toString() ?? '',
      topic: payload['topic']?.toString() ?? '',
      board: payload['board']?.toString(),
      classLevel: payload['class']?.toString(),
      additionalDetails: payload['details']?.toString(),
      language: payload['language']?.toString() ?? 'English',
      detailLevel: (payload['detailedness'] as num?)?.toDouble() ?? 0.5,
    );

    if (result.success && result.content != null) {
      return {
        'note': result.content,
        'source': 'gemini',
        'success': true,
      };
    }

    throw Exception(result.error ?? 'Failed to generate notes with Gemini');
  }

  /// Get list of available AI providers
  static List<AiProvider> getAvailableProviders() {
    final providers = <AiProvider>[];

    if (GeminiService.isConfigured) {
      providers.add(AiProvider.gemini);
    }

    return providers;
  }

  /// Check if any AI provider is available
  static bool get hasAiProvider => GeminiService.isConfigured;
}
