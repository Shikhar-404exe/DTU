class Note {
  final String id;
  final String subject;
  final String topic;
  final String content;
  final DateTime createdAt;

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

class NoteQuizMetadata {
  final List<String> keyPoints;
  final List<String> keywords;
  final List<QuizQuestionTemplate>
      questionTemplates;
  final String difficulty;
  final String? board;
  final String? classLevel;

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

class QuizQuestionTemplate {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String type;

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
