class TimetableEntry {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final int weekday; // 1=Mon..7=Sun
  final String startTime; // "09:30"
  final String endTime;   // "10:15"

  TimetableEntry({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'teacher': teacher,
        'room': room,
        'weekday': weekday,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        subject: json['subject'] as String,
        teacher: json['teacher'] as String? ?? '',
        room: json['room'] as String? ?? '',
        weekday: json['weekday'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
      );
}
