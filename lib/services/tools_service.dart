

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

enum ToolCapability {
  semanticSearch('semantic_search'),
  caching('caching'),
  syllabusParsing('syllabus_parsing'),
  studyPathGeneration('study_path_generation'),
  contentSync('content_sync'),
  offlineStorage('offline_storage');

  final String value;
  const ToolCapability(this.value);
}

class ToolInfo {
  final String id;
  final String name;
  final String description;
  final List<ToolCapability> capabilities;
  final bool supportsOffline;
  final String version;

  const ToolInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.capabilities,
    this.supportsOffline = true,
    this.version = '1.0.0',
  });

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      id: json['id'] ?? json['tool_id'],
      name: json['name'],
      description: json['description'],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((c) => ToolCapability.values.firstWhere(
                    (e) => e.value == c,
                    orElse: () => ToolCapability.offlineStorage,
                  ))
              .toList() ??
          [],
      supportsOffline: json['supports_offline'] ?? true,
      version: json['version'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() => {
        'tool_id': id,
        'name': name,
        'description': description,
        'capabilities': capabilities.map((c) => c.value).toList(),
        'supports_offline': supportsOffline,
        'version': version,
      };
}

class KnowledgeSearchResult {
  final String question;
  final String answer;
  final String? subject;
  final String? category;
  final double similarity;
  final String language;

  const KnowledgeSearchResult({
    required this.question,
    required this.answer,
    this.subject,
    this.category,
    required this.similarity,
    this.language = 'en',
  });

  factory KnowledgeSearchResult.fromJson(Map<String, dynamic> json) {
    return KnowledgeSearchResult(
      question: json['question'],
      answer: json['answer'],
      subject: json['subject'],
      category: json['category'],
      similarity: (json['similarity'] ?? 0.0).toDouble(),
      language: json['language'] ?? 'en',
    );
  }
}

class StudyPathItem {
  final int id;
  final String topic;
  final String? subtopic;
  final String difficulty;
  final double estimatedHours;
  final String status;
  final int progressPercentage;

  const StudyPathItem({
    required this.id,
    required this.topic,
    this.subtopic,
    required this.difficulty,
    required this.estimatedHours,
    this.status = 'not_started',
    this.progressPercentage = 0,
  });

  factory StudyPathItem.fromJson(Map<String, dynamic> json) {
    return StudyPathItem(
      id: json['id'] ?? 0,
      topic: json['topic'],
      subtopic: json['subtopic'],
      difficulty: json['difficulty'] ?? 'intermediate',
      estimatedHours: (json['estimated_hours'] ?? 1.0).toDouble(),
      status: json['status'] ?? 'not_started',
      progressPercentage: json['progress_percentage'] ?? 0,
    );
  }
}

class StudyPath {
  final int pathId;
  final String subject;
  final String gradeLevel;
  final int totalTopics;
  final int completedTopics;
  final double estimatedHours;
  final List<StudyPathItem> items;

  const StudyPath({
    required this.pathId,
    required this.subject,
    required this.gradeLevel,
    required this.totalTopics,
    this.completedTopics = 0,
    required this.estimatedHours,
    required this.items,
  });

  factory StudyPath.fromJson(Map<String, dynamic> json) {
    return StudyPath(
      pathId: json['path_id'] ?? 0,
      subject: json['subject'],
      gradeLevel: json['grade_level'],
      totalTopics: json['total_topics'] ?? 0,
      completedTopics: json['completed_topics'] ?? 0,
      estimatedHours: (json['estimated_hours'] ?? 0.0).toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => StudyPathItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SyncStatus {
  final String status;
  final int itemsSynced;
  final int bytesDownloaded;
  final double bandwidthKbps;
  final int pendingItems;
  final DateTime? lastSyncTime;

  const SyncStatus({
    required this.status,
    this.itemsSynced = 0,
    this.bytesDownloaded = 0,
    this.bandwidthKbps = 0.0,
    this.pendingItems = 0,
    this.lastSyncTime,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      status: json['status'] ?? 'unknown',
      itemsSynced: json['items_synced'] ?? 0,
      bytesDownloaded: json['bytes_downloaded'] ?? 0,
      bandwidthKbps: (json['bandwidth_kbps'] ?? 0.0).toDouble(),
      pendingItems: json['pending_items'] ?? 0,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'])
          : null,
    );
  }
}

class ToolsService {
  ToolsService._();

  static final List<ToolInfo> _registeredTools = [

    const ToolInfo(
      id: 'offline_knowledge_base',
      name: 'Offline Knowledge Base',
      description:
          'Provides semantic search and cached Q&A for offline operation. '
          'Uses SQLite for storage and lightweight embeddings for search. '
          'Stores educational content, app FAQs, and syllabus content.',
      capabilities: [
        ToolCapability.semanticSearch,
        ToolCapability.offlineStorage,
      ],
      supportsOffline: true,
      version: '1.0.0',
    ),

    const ToolInfo(
      id: 'cache_manager',
      name: 'Smart Cache Manager',
      description:
          'Manages content synchronization for low-bandwidth scenarios. '
          'Implements progressive sync and offline-first strategies. '
          'Prioritizes content based on user needs and connectivity.',
      capabilities: [
        ToolCapability.caching,
        ToolCapability.contentSync,
        ToolCapability.offlineStorage,
      ],
      supportsOffline: true,
      version: '1.0.0',
    ),

    const ToolInfo(
      id: 'syllabus_parser',
      name: 'Syllabus Parser & Study Path Generator',
      description:
          'Parses educational syllabus and generates structured learning paths. '
          'Extracts topics, creates dependencies, and builds personalized study plans. '
          'Supports CBSE, ICSE, and state board syllabi.',
      capabilities: [
        ToolCapability.syllabusParsing,
        ToolCapability.studyPathGeneration,
      ],
      supportsOffline: true,
      version: '1.0.0',
    ),
  ];

  static List<ToolInfo> getRegisteredTools() =>
      List.unmodifiable(_registeredTools);

  static int get toolCount => _registeredTools.length;

  static ToolInfo? getToolById(String id) {
    try {
      return _registeredTools.firstWhere((tool) => tool.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<KnowledgeSearchResult>> searchKnowledge({
    required String query,
    String? subject,
    String language = 'en',
    int limit = 5,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/tools/knowledge/search'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'subject': subject,
              'language': language,
              'limit': limit,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List<dynamic>?)
                ?.map((r) => KnowledgeSearchResult.fromJson(r))
                .toList() ??
            [];
        return results;
      }
    } catch (e) {
      debugPrint('ToolsService searchKnowledge error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getKnowledgeStats() async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/tools/knowledge/stats'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('ToolsService getKnowledgeStats error: $e');
    }
    return null;
  }

  static Future<SyncStatus?> getSyncStatus() async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/tools/cache/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SyncStatus.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ToolsService getSyncStatus error: $e');
    }
    return null;
  }

  static Future<bool> startProgressiveSync({
    String priority = 'high',
    int maxSizeKb = 5000,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/tools/cache/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'priority': priority,
              'max_size_kb': maxSizeKb,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ToolsService startProgressiveSync error: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getCachedContent({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/tools/cache/content/$contentType/$contentId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('ToolsService getCachedContent error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getSyllabusTopics({
    required String subject,
    String gradeLevel = '10',
    String? board,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse(
            '$baseUrl/tools/syllabus/topics?subject=$subject&grade=$gradeLevel${board != null ? '&board=$board' : ''}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['topics'] ?? []);
      }
    } catch (e) {
      debugPrint('ToolsService getSyllabusTopics error: $e');
    }
    return [];
  }

  static Future<StudyPath?> generateStudyPath({
    required String userId,
    required String subject,
    String gradeLevel = '10',
    int availableHoursPerWeek = 10,
    int targetWeeks = 12,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/tools/syllabus/study-path'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': userId,
              'subject': subject,
              'grade_level': gradeLevel,
              'available_hours_per_week': availableHoursPerWeek,
              'target_weeks': targetWeeks,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['study_path'] != null) {
          return StudyPath.fromJson(data['study_path']);
        }
      }
    } catch (e) {
      debugPrint('ToolsService generateStudyPath error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getStudyPathProgress({
    required int pathId,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/tools/syllabus/study-path/$pathId/progress'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('ToolsService getStudyPathProgress error: $e');
    }
    return null;
  }

  static Future<bool> updateTopicProgress({
    required int pathId,
    required int topicId,
    required int progressPercentage,
    int? timeSpentMinutes,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .put(
            Uri.parse(
                '$baseUrl/tools/syllabus/study-path/$pathId/topic/$topicId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'progress_percentage': progressPercentage,
              'time_spent_minutes': timeSpentMinutes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ToolsService updateTopicProgress error: $e');
    }
    return false;
  }
}
