/// OpenAI Service for Note Generation
/// DISABLED - No credits available
/// Uses OpenAI's GPT API for AI-powered note generation
library;

import 'package:flutter/foundation.dart';

/// Result wrapper for OpenAI API responses
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

/// OpenAI Service for generating notes and educational content
/// NOTE: This service is DISABLED - OpenAI has no credits
class OpenAiService {
  OpenAiService._();

  static const String _disabledMessage =
      'OpenAI service is disabled. Please use Gemini AI instead.';

  /// Generate notes using OpenAI GPT (DISABLED)
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

  /// Summarize text using OpenAI GPT (DISABLED)
  static Future<OpenAiResult> summarizeText({
    required String text,
    String language = 'English',
    int maxLength = 500,
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  /// Explain a concept using OpenAI GPT (DISABLED)
  static Future<OpenAiResult> explainConcept({
    required String concept,
    required String subject,
    String? classLevel,
    String language = 'English',
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  /// Generate quiz questions using OpenAI GPT (DISABLED)
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

  /// Solve a math problem using OpenAI GPT (DISABLED)
  static Future<OpenAiResult> solveMathProblem({
    required String problem,
    bool showSteps = true,
    String language = 'English',
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  /// Chat with AI assistant (DISABLED)
  static Future<OpenAiResult> chat({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? systemContext,
  }) async {
    debugPrint('OpenAI service is disabled');
    return OpenAiResult.failure(_disabledMessage);
  }

  /// Check if the API key is configured (always false - disabled)
  static bool get isConfigured => false;

  /// Test the API connection (always false - disabled)
  static Future<bool> testConnection() async {
    debugPrint('OpenAI service is disabled');
    return false;
  }

  /// Get available models (empty - disabled)
  static Future<List<String>> getAvailableModels() async {
    debugPrint('OpenAI service is disabled');
    return [];
  }
}
