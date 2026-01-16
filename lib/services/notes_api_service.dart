import 'openrouter_service.dart';

enum AiProvider { openrouter, auto }

class NotesApiService {

  static Future<Map<String, dynamic>> generateNote(Map<String, dynamic> payload,
      {AiProvider provider = AiProvider.auto}) async {
    return await generateNoteWithOpenRouter(payload);
  }

  static Future<Map<String, dynamic>> generateNoteWithOpenRouter(
      Map<String, dynamic> payload) async {
    final result = await OpenRouterService.generateNotes(
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
        'source': 'openrouter',
        'success': true,
      };
    }

    throw Exception(result.error ?? 'Failed to generate notes with OpenRouter');
  }

  static List<AiProvider> getAvailableProviders() {
    final providers = <AiProvider>[];

    if (OpenRouterService.isConfigured) {
      providers.add(AiProvider.openrouter);
    }

    return providers;
  }

  static bool get hasAiProvider => OpenRouterService.isConfigured;
}
