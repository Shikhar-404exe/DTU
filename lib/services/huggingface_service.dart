

library;

import 'package:flutter/foundation.dart';

class HuggingFaceService {
  static final HuggingFaceService _instance = HuggingFaceService._internal();
  factory HuggingFaceService() => _instance;
  HuggingFaceService._internal();

  static const String _disabledMessage =
      'HuggingFace service is disabled. Please use Gemini AI instead.';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('HuggingFace service is disabled');
    _isInitialized = true;
  }

  Future<String> generateNotes({
    required String topic,
    String? context,
    String language = 'English',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> summarizeText({
    required String text,
    int maxLength = 150,
    int minLength = 40,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> explainConcept({
    required String concept,
    String level = 'high school',
    String language = 'English',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> generateQuiz({
    required String content,
    int numberOfQuestions = 5,
    String difficulty = 'medium',
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> solveMathProblem({
    required String problem,
    bool showSteps = true,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> answerQuestion({
    required String question,
    required String context,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> generateFlashcards({
    required String content,
    int numberOfCards = 10,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<String> createStudyPlan({
    required String subjects,
    required String duration,
    String? goals,
  }) async {
    debugPrint('HuggingFace service is disabled');
    throw Exception(_disabledMessage);
  }

  Future<bool> isAvailable() async {
    debugPrint('HuggingFace service is disabled');
    return false;
  }

  bool get isInitialized => _isInitialized;
}
