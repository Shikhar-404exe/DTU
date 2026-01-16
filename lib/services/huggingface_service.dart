/// Hugging Face AI Service for free AI-powered features
/// DISABLED - Invalid token
/// Uses Hugging Face Inference API with open-source models
library;

import 'package:flutter/foundation.dart';

/// Hugging Face AI Service for free AI-powered features
/// NOTE: This service is DISABLED - Invalid API token
class HuggingFaceService {
  static final HuggingFaceService _instance = HuggingFaceService._internal();
  factory HuggingFaceService() => _instance;
  HuggingFaceService._internal();

  static const String _disabledMessage =
      'HuggingFace service is disabled. Please use Gemini AI instead.';

  bool _isInitialized = false;

  /// Initialize the service (DISABLED)
  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('HuggingFace service is disabled');
    _isInitialized = true;
  }

  /// Generate notes from a topic (DISABLED)
  Future<String> generateNotes({
    required String topic,
    String? context,
    String language = 'English',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Summarize text (DISABLED)
  Future<String> summarizeText({
    required String text,
    int maxLength = 150,
    int minLength = 40,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Explain a concept in simple terms (DISABLED)
  Future<String> explainConcept({
    required String concept,
    String level = 'high school',
    String language = 'English',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Generate quiz questions from content (DISABLED)
  Future<String> generateQuiz({
    required String content,
    int numberOfQuestions = 5,
    String difficulty = 'medium',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Solve math problems (DISABLED)
  Future<String> solveMathProblem({
    required String problem,
    bool showSteps = true,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Answer questions about content (DISABLED)
  Future<String> answerQuestion({
    required String question,
    required String context,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Generate flashcards from content (DISABLED)
  Future<String> generateFlashcards({
    required String content,
    int numberOfCards = 10,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Create study plan (DISABLED)
  Future<String> createStudyPlan({
    required String subjects,
    required String duration,
    String? goals,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  /// Check if the service is available (always false - disabled)
  Future<bool> isAvailable() async {
    debugPrint('HuggingFace service is disabled');
    return false;
  }

  /// Get service status
  bool get isInitialized => _isInitialized;
}
