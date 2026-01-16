

library;

import 'package:flutter/foundation.dart';

class OpenAiResult {
  final bool success;
  final String? content;
  final String? error;
  final int? tokensUsed;

  const OpenAiResult._({
    required this.success,
    this.content,
    this.error,
    this.tokensUsed,
  });

  factory OpenAiResult.success(String content, {int? tokensUsed}) =>
      OpenAiResult._(
        success: true,
        content: content,
        tokensUsed: tokensUsed,
      );

  factory OpenAiResult.failure(String error) => OpenAiResult._(
        success: false,
        error: error,
      );
}

class OpenAiService {
  OpenAiService._();

  static const String _disabledMessage =
      'OpenAI service is disabled. Please use Gemini AI instead.';

  static Future<OpenAiResult> generateNotes({
    required String subject,
    required String topic,
    String? board,
    String? classLevel,
    String? additionalDetails,
    String language = 'English',
    double detailLevel = 0.5,
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static Future<OpenAiResult> summarizeText({
    required String text,
    String language = 'English',
    int maxLength = 500,
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static Future<OpenAiResult> explainConcept({
    required String concept,
    required String subject,
    String? classLevel,
    String language = 'English',
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static Future<OpenAiResult> generateQuiz({
    required String topic,
    required String subject,
    int questionCount = 5,
    String difficulty = 'medium',
    String language = 'English',
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static Future<OpenAiResult> solveMathProblem({
    required String problem,
    bool showSteps = true,
    String language = 'English',
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static Future<OpenAiResult> chat({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? systemContext,
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  static bool get isConfigured => false;

  static Future<bool> testConnection() async {
    debugPrint('OpenAI service is disabled');
    return false;
  }

  static Future<List<String>> getAvailableModels() async {
    debugPrint('OpenAI service is disabled');
    return [];
  }
}
