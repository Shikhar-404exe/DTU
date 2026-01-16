class Note {
  final String id;
  final String subject;
  final String topic;
  final String content;
  final DateTime createdAt;

  // Quiz metadata for offline question generation
  final NoteQuizMetadata? quizMetadata;

  Note({
    required this.id,
    required this.subject,
    required this.topic,
    required this.content,
    required this.createdAt,
    this.quizMetadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'topic': topic,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        if (quizMetadata != null) 'quizMetadata': quizMetadata!.toJson(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        quizMetadata: json['quizMetadata'] != null
            ? NoteQuizMetadata.fromJson(
                json['quizMetadata'] as Map<String, dynamic>)
            : null,
      );
}

/// Quiz metadata for offline question generation
class NoteQuizMetadata {
  final List<String> keyPoints; // Main concepts from notes
  final List<String> keywords; // Important terms
  final List<QuizQuestionTemplate>
      questionTemplates; // Pre-generated question templates
  final String difficulty; // easy, medium, hard
  final String? board; // CBSE, State Board, etc.
  final String? classLevel; // Class 10, 12, etc.

  NoteQuizMetadata({
    required this.keyPoints,
    required this.keywords,
    required this.questionTemplates,
    this.difficulty = 'medium',
    this.board,
    this.classLevel,
  });

  Map<String, dynamic> toJson() => {
        'keyPoints': keyPoints,
        'keywords': keywords,
        'questionTemplates': questionTemplates.map((q) => q.toJson()).toList(),
        'difficulty': difficulty,
        if (board != null) 'board': board,
        if (classLevel != null) 'classLevel': classLevel,
      };

  factory NoteQuizMetadata.fromJson(Map<String, dynamic> json) =>
      NoteQuizMetadata(
        keyPoints: List<String>.from(json['keyPoints'] as List),
        keywords: List<String>.from(json['keywords'] as List),
        questionTemplates: (json['questionTemplates'] as List)
            .map(
                (q) => QuizQuestionTemplate.fromJson(q as Map<String, dynamic>))
            .toList(),
        difficulty: json['difficulty'] as String? ?? 'medium',
        board: json['board'] as String?,
        classLevel: json['classLevel'] as String?,
      );
}

/// Question template for offline quiz generation
class QuizQuestionTemplate {
  final String question;
  final List<String> options; // For MCQ (4 options)
  final String correctAnswer;
  final String explanation;
  final String type; // mcq, true_false, short_answer, fill_blank

  QuizQuestionTemplate({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.type = 'mcq',
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'type': type,
      };

  factory QuizQuestionTemplate.fromJson(Map<String, dynamic> json) =>
      QuizQuestionTemplate(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        correctAnswer: json['correctAnswer'] as String,
        explanation: json['explanation'] as String,
        type: json['type'] as String? ?? 'mcq',
      );
}
