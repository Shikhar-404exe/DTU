// filepath: lib/services/teacher_data_service.dart
/// Teacher Data Persistence Service
/// Manages compact JSON storage in SharedPreferences with size monitoring

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher_models.dart';

class TeacherDataService {
  static const String _studentsKey = 'teacher_students';
  static const String _classesKey = 'teacher_classes';
  static const String _lessonsKey = 'teacher_lessons';
  static const String _timetableKey = 'teacher_timetable';
  static const String _attendanceKey = 'teacher_attendance';

  // Size limits (in bytes)
  static const int _maxTotalSize = 900 * 1024; // 900KB (safe under 1MB limit)
  static const int _warningSize = 700 * 1024; // 700KB warning threshold

  /// Get all students
  static Future<List<StudentRecord>> getStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_studentsKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => StudentRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading students: $e');
      return [];
    }
  }

  /// Save all students
  static Future<bool> saveStudents(List<StudentRecord> students) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(students.map((s) => s.toJson()).toList());

      // Check size before saving
      if (jsonStr.length > _maxTotalSize) {
        debugPrint('⚠️ Data size exceeds limit: ${jsonStr.length} bytes');
        return false;
      }

      await prefs.setString(_studentsKey, jsonStr);
      await _checkTotalSize();
      return true;
    } catch (e) {
      debugPrint('Error saving students: $e');
      return false;
    }
  }

  /// Get all class sections
  static Future<List<ClassSection>> getClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_classesKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => ClassSection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading classes: $e');
      return [];
    }
  }

  /// Save all class sections
  static Future<bool> saveClasses(List<ClassSection> classes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(classes.map((c) => c.toJson()).toList());
      await prefs.setString(_classesKey, jsonStr);
      await _checkTotalSize();
      return true;
    } catch (e) {
      debugPrint('Error saving classes: $e');
      return false;
    }
  }

  /// Get all lesson plans
  static Future<List<LessonPlan>> getLessonPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_lessonsKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => LessonPlan.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading lesson plans: $e');
      return [];
    }
  }

  /// Save all lesson plans
  static Future<bool> saveLessonPlans(List<LessonPlan> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(lessons.map((l) => l.toJson()).toList());
      await prefs.setString(_lessonsKey, jsonStr);
      await _checkTotalSize();
      return true;
    } catch (e) {
      debugPrint('Error saving lesson plans: $e');
      return false;
    }
  }

  /// Get timetable entries
  static Future<List<TimetableEntry>> getTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_timetableKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => TimetableEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading timetable: $e');
      return [];
    }
  }

  /// Save timetable entries
  static Future<bool> saveTimetable(List<TimetableEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_timetableKey, jsonStr);
      await _checkTotalSize();
      return true;
    } catch (e) {
      debugPrint('Error saving timetable: $e');
      return false;
    }
  }

  /// Get attendance records
  static Future<List<AttendanceRecord>> getAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_attendanceKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => AttendanceRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      return [];
    }
  }

  /// Save attendance records
  static Future<bool> saveAttendance(List<AttendanceRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_attendanceKey, jsonStr);
      await _checkTotalSize();
      return true;
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      return false;
    }
  }

  /// Mark attendance for a specific date and class
  static Future<bool> markAttendance({
    required String date,
    required String classId,
    required Map<String, bool> attendance,
  }) async {
    try {
      final records = await getAttendance();
      final existingIndex =
          records.indexWhere((r) => r.date == date && r.classId == classId);

      if (existingIndex >= 0) {
        records[existingIndex] = AttendanceRecord(
          date: date,
          classId: classId,
          attendance: attendance,
        );
      } else {
        records.add(AttendanceRecord(
          date: date,
          classId: classId,
          attendance: attendance,
        ));
      }

      return await saveAttendance(records);
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      return false;
    }
  }

  /// Check total data size and log warnings
  static Future<void> _checkTotalSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int totalSize = 0;

      for (final key in [
        _studentsKey,
        _classesKey,
        _lessonsKey,
        _timetableKey,
        _attendanceKey
      ]) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }

      debugPrint(
          '📊 Teacher data size: ${(totalSize / 1024).toStringAsFixed(2)} KB');

      if (totalSize > _warningSize) {
        debugPrint('⚠️ WARNING: Approaching SharedPreferences limit!');
        debugPrint('   Current: ${(totalSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('   Consider migrating to sqflite for >200 students');
      }
    } catch (e) {
      debugPrint('Error checking data size: $e');
    }
  }

  /// Clear all teacher data (use with caution!)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_studentsKey);
      await prefs.remove(_classesKey);
      await prefs.remove(_lessonsKey);
      await prefs.remove(_timetableKey);
      await prefs.remove(_attendanceKey);
      debugPrint('✓ All teacher data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  /// Get data size estimate
  static Future<Map<String, int>> getDataSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'students': prefs.getString(_studentsKey)?.length ?? 0,
        'classes': prefs.getString(_classesKey)?.length ?? 0,
        'lessons': prefs.getString(_lessonsKey)?.length ?? 0,
        'timetable': prefs.getString(_timetableKey)?.length ?? 0,
        'attendance': prefs.getString(_attendanceKey)?.length ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting data sizes: $e');
      return {};
    }
  }
}
