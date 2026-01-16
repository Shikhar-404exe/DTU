

library;

import 'dart:math';
import '../models/note.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String type;
  final int points;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.type,
    this.points = 1,
  });
}

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final int score;
  final Map<int, bool> answers;
  final Duration timeTaken;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.answers,
    required this.timeTaken,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;
  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}

class OfflineQuizService {
  static final Random _random = Random();

  static List<QuizQuestion> generateQuizFromNote({
    required Note note,
    int questionCount = 10,
    List<String>? questionTypes,
    String? difficulty,
  }) {

    if (note.quizMetadata == null) {
      throw Exception(
          'Note does not have quiz metadata. Generate questions online first.');
    }

    final metadata = note.quizMetadata!;
    final templates = metadata.questionTemplates;

    if (templates.isEmpty) {
      throw Exception('No question templates available in metadata.');
    }

    List<QuizQuestionTemplate> filteredTemplates = templates;
    if (questionTypes != null && questionTypes.isNotEmpty) {
      filteredTemplates =
          templates.where((t) => questionTypes.contains(t.type)).toList();
    }

    if (filteredTemplates.isEmpty) {
      filteredTemplates = templates;
    }

    final selectedCount = min(questionCount, filteredTemplates.length);
    final selectedTemplates = _selectRandomQuestions(
      filteredTemplates,
      selectedCount,
    );

    return selectedTemplates.map((template) {
      return QuizQuestion(
        question: template.question,
        options: List.from(template.options)..shuffle(_random),
        correctAnswer: template.correctAnswer,
        explanation: template.explanation,
        type: template.type,
        points: _getPointsForType(template.type),
      );
    }).toList();
  }

  static List<QuizQuestion> generateQuizFromMultipleNotes({
    required List<Note> notes,
    int questionsPerNote = 3,
    List<String>? questionTypes,
  }) {
    final allQuestions = <QuizQuestion>[];

    for (final note in notes) {
      if (note.quizMetadata == null) continue;

      try {
        final questions = generateQuizFromNote(
          note: note,
          questionCount: questionsPerNote,
          questionTypes: questionTypes,
        );
        allQuestions.addAll(questions);
      } catch (e) {

        continue;
      }
    }

    if (allQuestions.isEmpty) {
      throw Exception(
          'No questions could be generated from the provided notes.');
    }

    allQuestions.shuffle(_random);
    return allQuestions;
  }

  static List<String> getKeyConceptsFromNote(Note note) {
    if (note.quizMetadata == null) return [];
    return note.quizMetadata!.keyPoints;
  }

  static List<String> getKeywordsFromNote(Note note) {
    if (note.quizMetadata == null) return [];
    return note.quizMetadata!.keywords;
  }

  static bool canGenerateQuiz(Note note) {
    return note.quizMetadata != null &&
        note.quizMetadata!.questionTemplates.isNotEmpty;
  }

  static Map<String, dynamic> getQuizStats(Note note) {
    if (note.quizMetadata == null) {
      return {
        'available': false,
        'message': 'Quiz metadata not available',
      };
    }

    final metadata = note.quizMetadata!;
    final templates = metadata.questionTemplates;

    final typeCounts = <String, int>{};
    for (final template in templates) {
      typeCounts[template.type] = (typeCounts[template.type] ?? 0) + 1;
    }

    return {
      'available': true,
      'totalQuestions': templates.length,
      'keyPoints': metadata.keyPoints.length,
      'keywords': metadata.keywords.length,
      'difficulty': metadata.difficulty,
      'questionTypes': typeCounts,
      'board': metadata.board,
      'classLevel': metadata.classLevel,
    };
  }

  static List<QuizQuestion> generatePracticeQuiz({
    required Note note,
    int easyCount = 3,
    int mediumCount = 5,
    int hardCount = 2,
  }) {
    if (note.quizMetadata == null ||
        note.quizMetadata!.questionTemplates.isEmpty) {
      throw Exception('Quiz metadata not available');
    }

    final templates = note.quizMetadata!.questionTemplates;
    final allQuestions = templates
        .map((t) => QuizQuestion(
              question: t.question,
              options: List.from(t.options)..shuffle(_random),
              correctAnswer: t.correctAnswer,
              explanation: t.explanation,
              type: t.type,
              points: _getPointsForType(t.type),
            ))
        .toList();

    if (allQuestions.length <= (easyCount + mediumCount + hardCount)) {
      allQuestions.shuffle(_random);
      return allQuestions;
    }

    final selected = _selectRandomQuestions(
      templates,
      easyCount + mediumCount + hardCount,
    );

    return selected
        .map((t) => QuizQuestion(
              question: t.question,
              options: List.from(t.options)..shuffle(_random),
              correctAnswer: t.correctAnswer,
              explanation: t.explanation,
              type: t.type,
              points: _getPointsForType(t.type),
            ))
        .toList();
  }

  static List<QuizQuestion> generateQuickQuiz(Note note) {
    return generateQuizFromNote(
      note: note,
      questionCount: 5,
      questionTypes: ['mcq', 'true_false'],
    );
  }

  static QuizResult calculateResult({
    required List<QuizQuestion> questions,
    required Map<int, String> userAnswers,
    required Duration timeTaken,
  }) {
    final answers = <int, bool>{};
    int correctCount = 0;
    int totalScore = 0;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = userAnswers[i];

      if (userAnswer == null) {
        answers[i] = false;
        continue;
      }

      final isCorrect = userAnswer.trim().toLowerCase() ==
          question.correctAnswer.trim().toLowerCase();

      answers[i] = isCorrect;

      if (isCorrect) {
        correctCount++;
        totalScore += question.points;
      }
    }

    return QuizResult(
      totalQuestions: questions.length,
      correctAnswers: correctCount,
      score: totalScore,
      answers: answers,
      timeTaken: timeTaken,
    );
  }

  static List<QuizQuestionTemplate> _selectRandomQuestions(
    List<QuizQuestionTemplate> templates,
    int count,
  ) {
    if (templates.length <= count) {
      return List.from(templates)..shuffle(_random);
    }

    final selected = <QuizQuestionTemplate>[];
    final available = List<int>.generate(templates.length, (i) => i);
    available.shuffle(_random);

    for (int i = 0; i < count; i++) {
      selected.add(templates[available[i]]);
    }

    return selected;
  }

  static int _getPointsForType(String type) {
    switch (type) {
      case 'mcq':
        return 1;
      case 'true_false':
        return 1;
      case 'short_answer':
        return 2;
      case 'fill_blank':
        return 1;
      default:
        return 1;
    }
  }

  static List<Map<String, String>> generateFlashcards(Note note) {
    if (note.quizMetadata == null) return [];

    final flashcards = <Map<String, String>>[];
    final metadata = note.quizMetadata!;

    for (final keyword in metadata.keywords) {

      String? definition;
      for (final point in metadata.keyPoints) {
        if (point.toLowerCase().contains(keyword.toLowerCase())) {
          definition = point;
          break;
        }
      }

      flashcards.add({
        'front': keyword,
        'back': definition ?? 'Definition from: ${note.topic}',
      });
    }

    return flashcards;
  }
}
