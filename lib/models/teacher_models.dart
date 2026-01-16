

library;

class StudentRecord {
  final String id;
  final String name;
  final String rollNumber;
  final String classId;
  final Map<String, double> marks;
  final List<String> attendanceDates;

  const StudentRecord({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.classId,
    this.marks = const {},
    this.attendanceDates = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rollNumber': rollNumber,
        'classId': classId,
        'marks': marks,
        'attendanceDates': attendanceDates,
      };

  factory StudentRecord.fromJson(Map<String, dynamic> json) => StudentRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        rollNumber: json['rollNumber'] as String,
        classId: json['classId'] as String,
        marks: Map<String, double>.from(json['marks'] ?? {}),
        attendanceDates: List<String>.from(json['attendanceDates'] ?? []),
      );

  StudentRecord copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? classId,
    Map<String, double>? marks,
    List<String>? attendanceDates,
  }) =>
      StudentRecord(
        id: id ?? this.id,
        name: name ?? this.name,
        rollNumber: rollNumber ?? this.rollNumber,
        classId: classId ?? this.classId,
        marks: marks ?? this.marks,
        attendanceDates: attendanceDates ?? this.attendanceDates,
      );
}

class ClassSection {
  final String id;
  final String name;
  final String grade;
  final String section;
  final List<String> studentIds;

  const ClassSection({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    this.studentIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'section': section,
        'studentIds': studentIds,
      };

  factory ClassSection.fromJson(Map<String, dynamic> json) => ClassSection(
        id: json['id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as String,
        section: json['section'] as String,
        studentIds: List<String>.from(json['studentIds'] ?? []),
      );
}

class LessonPlan {
  final String id;
  final String classId;
  final String subject;
  final String topic;
  final String date;
  final String notes;
  final String? aiSummary;

  const LessonPlan({
    required this.id,
    required this.classId,
    required this.subject,
    required this.topic,
    required this.date,
    required this.notes,
    this.aiSummary,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'subject': subject,
        'topic': topic,
        'date': date,
        'notes': notes,
        if (aiSummary != null) 'aiSummary': aiSummary,
      };

  factory LessonPlan.fromJson(Map<String, dynamic> json) => LessonPlan(
        id: json['id'] as String,
        classId: json['classId'] as String,
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        date: json['date'] as String,
        notes: json['notes'] as String,
        aiSummary: json['aiSummary'] as String?,
      );
}

class TimetableEntry {
  final String id;
  final String classId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subject;
  final String room;

  const TimetableEntry({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'room': room,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        classId: json['classId'] as String,
        dayOfWeek: json['dayOfWeek'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        subject: json['subject'] as String,
        room: json['room'] as String,
      );
}

class AttendanceRecord {
  final String date;
  final String classId;
  final Map<String, bool> attendance;

  const AttendanceRecord({
    required this.date,
    required this.classId,
    required this.attendance,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'classId': classId,
        'attendance': attendance,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: json['date'] as String,
        classId: json['classId'] as String,
        attendance: Map<String, bool>.from(json['attendance'] ?? {}),
      );
}
