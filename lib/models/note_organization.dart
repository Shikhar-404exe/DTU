/// Note organization models for structuring saved notes

class NoteClass {
  final String id;
  final String name;
  final int? grade; // null for college

  const NoteClass({
    required this.id,
    required this.name,
    this.grade,
  });

  static const List<NoteClass> allClasses = [
    NoteClass(id: 'class_1', name: 'Class 1', grade: 1),
    NoteClass(id: 'class_2', name: 'Class 2', grade: 2),
    NoteClass(id: 'class_3', name: 'Class 3', grade: 3),
    NoteClass(id: 'class_4', name: 'Class 4', grade: 4),
    NoteClass(id: 'class_5', name: 'Class 5', grade: 5),
    NoteClass(id: 'class_6', name: 'Class 6', grade: 6),
    NoteClass(id: 'class_7', name: 'Class 7', grade: 7),
    NoteClass(id: 'class_8', name: 'Class 8', grade: 8),
    NoteClass(id: 'class_9', name: 'Class 9', grade: 9),
    NoteClass(id: 'class_10', name: 'Class 10', grade: 10),
    NoteClass(id: 'class_11', name: 'Class 11', grade: 11),
    NoteClass(id: 'class_12', name: 'Class 12', grade: 12),
    NoteClass(id: 'college', name: 'College/University', grade: null),
  ];
}

class Subject {
  final String id;
  final String name;
  final String emoji;

  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
  });

  static const List<Subject> allSubjects = [
    // Primary subjects (Class 1-5)
    Subject(id: 'english', name: 'English', emoji: '📖'),
    Subject(id: 'hindi', name: 'Hindi', emoji: '📝'),
    Subject(id: 'math', name: 'Mathematics', emoji: '🔢'),
    Subject(id: 'evs', name: 'EVS', emoji: '🌍'),
    Subject(id: 'drawing', name: 'Drawing', emoji: '🎨'),

    // Secondary subjects (Class 6-10)
    Subject(id: 'science', name: 'Science', emoji: '🔬'),
    Subject(id: 'social', name: 'Social Studies', emoji: '🗺️'),
    Subject(id: 'computer', name: 'Computer', emoji: '💻'),
    Subject(id: 'sanskrit', name: 'Sanskrit', emoji: '🕉️'),

    // Higher Secondary (Class 11-12)
    Subject(id: 'physics', name: 'Physics', emoji: '⚛️'),
    Subject(id: 'chemistry', name: 'Chemistry', emoji: '🧪'),
    Subject(id: 'biology', name: 'Biology', emoji: '🧬'),
    Subject(id: 'accounts', name: 'Accountancy', emoji: '💰'),
    Subject(id: 'business', name: 'Business Studies', emoji: '📊'),
    Subject(id: 'economics', name: 'Economics', emoji: '📈'),
    Subject(id: 'history', name: 'History', emoji: '📜'),
    Subject(id: 'geography', name: 'Geography', emoji: '🌏'),
    Subject(id: 'political', name: 'Political Science', emoji: '🏛️'),

    // College
    Subject(id: 'engineering', name: 'Engineering', emoji: '⚙️'),
    Subject(id: 'medical', name: 'Medical', emoji: '🏥'),
    Subject(id: 'law', name: 'Law', emoji: '⚖️'),
    Subject(id: 'commerce', name: 'Commerce', emoji: '💼'),
    Subject(id: 'arts', name: 'Arts', emoji: '🎭'),

    // Common
    Subject(id: 'other', name: 'Other', emoji: '📚'),
  ];
}

class NoteCategory {
  final String id;
  final String name;
  final String emoji;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.emoji,
  });

  static const List<NoteCategory> allCategories = [
    NoteCategory(id: 'notes', name: 'Class Notes', emoji: '📝'),
    NoteCategory(id: 'assignment', name: 'Assignment', emoji: '📋'),
    NoteCategory(id: 'revision', name: 'Revision Notes', emoji: '🔄'),
    NoteCategory(id: 'exam', name: 'Exam Preparation', emoji: '📚'),
    NoteCategory(id: 'project', name: 'Project', emoji: '🎯'),
    NoteCategory(id: 'scanned', name: 'Scanned Document', emoji: '📄'),
    NoteCategory(id: 'other', name: 'Other', emoji: '📁'),
  ];
}

class OrganizedNote {
  final String id;
  final String title;
  final String content;
  final String classId;
  final String subjectId;
  final String categoryId;
  final DateTime createdAt;
  final String? filePath; // For PDFs
  final String type; // 'text' or 'pdf'

  OrganizedNote({
    required this.id,
    required this.title,
    required this.content,
    required this.classId,
    required this.subjectId,
    required this.categoryId,
    required this.createdAt,
    this.filePath,
    this.type = 'text',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'classId': classId,
        'subjectId': subjectId,
        'categoryId': categoryId,
        'createdAt': createdAt.toIso8601String(),
        'filePath': filePath,
        'type': type,
      };

  factory OrganizedNote.fromJson(Map<String, dynamic> json) => OrganizedNote(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        classId: json['classId'] as String,
        subjectId: json['subjectId'] as String,
        categoryId: json['categoryId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        filePath: json['filePath'] as String?,
        type: json['type'] as String? ?? 'text',
      );
}
