import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _notesKey = 'notes_v1';
  static const _timetableKey = 'timetable_v1';

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to read $key: $e');
      return [];
    }
  }

  static Future<bool> _writeList(String key, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('Failed to write $key: $e');
      return false;
    }
  }

  // Notes
  static Future<List<Map<String, dynamic>>> loadNotes() => _readList(_notesKey);
  static Future<bool> saveNotes(List<Map<String, dynamic>> notes) => _writeList(_notesKey, notes);

  // Timetable
  static Future<List<Map<String, dynamic>>> loadTimetable() => _readList(_timetableKey);
  static Future<bool> saveTimetable(List<Map<String, dynamic>> entries) => _writeList(_timetableKey, entries);

  // Auth state helpers
  static Future<void> clearAuth() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove('token');
      await p.remove('guest');
    } catch (e) {
      debugPrint('Failed to clear auth: $e');
    }
  }
}

