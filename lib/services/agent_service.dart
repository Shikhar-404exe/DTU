

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

enum AgentCapability {
  textProcessing('text_processing'),
  voiceProcessing('voice_processing'),
  imageProcessing('image_processing'),
  videoRecommendation('video_recommendation'),
  contentGeneration('content_generation'),
  learningPath('learning_path'),
  assessment('assessment'),
  translation('translation'),
  accessibility('accessibility');

  final String value;
  const AgentCapability(this.value);
}

enum AgentPriority {
  critical(1, 'Critical'),
  high(2, 'High'),
  medium(3, 'Medium'),
  low(4, 'Low');

  final int level;
  final String name;
  const AgentPriority(this.level, this.name);
}

enum AgentMode {
  offline('offline'),
  online('online'),
  auto('auto');

  final String value;
  const AgentMode(this.value);
}

class AgentInfo {
  final String id;
  final String name;
  final String description;
  final List<AgentCapability> capabilities;
  final AgentPriority priority;
  final AgentMode defaultMode;
  final bool isActive;
  final int totalRequests;
  final int successfulResponses;

  const AgentInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.capabilities,
    required this.priority,
    this.defaultMode = AgentMode.auto,
    this.isActive = true,
    this.totalRequests = 0,
    this.successfulResponses = 0,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      id: json['agent_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((c) => AgentCapability.values.firstWhere(
                    (e) => e.value == c,
                    orElse: () => AgentCapability.textProcessing,
                  ))
              .toList() ??
          [],
      priority: AgentPriority.values.firstWhere(
        (p) =>
            p.name.toLowerCase() ==
            (json['priority'] ?? 'medium').toString().toLowerCase(),
        orElse: () => AgentPriority.medium,
      ),
      defaultMode: AgentMode.values.firstWhere(
        (m) => m.value == (json['default_mode'] ?? 'auto'),
        orElse: () => AgentMode.auto,
      ),
      isActive: json['is_active'] ?? true,
      totalRequests: json['total_requests'] ?? 0,
      successfulResponses: json['successful_responses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'agent_id': id,
        'name': name,
        'description': description,
        'capabilities': capabilities.map((c) => c.value).toList(),
        'priority': priority.name.toLowerCase(),
        'default_mode': defaultMode.value,
        'is_active': isActive,
        'total_requests': totalRequests,
        'successful_responses': successfulResponses,
      };
}

class AgentResponse {
  final bool success;
  final String? response;
  final String? agentId;
  final String? agentName;
  final String? mode;
  final double confidence;
  final String? error;
  final Map<String, dynamic>? metadata;

  const AgentResponse({
    required this.success,
    this.response,
    this.agentId,
    this.agentName,
    this.mode,
    this.confidence = 0.0,
    this.error,
    this.metadata,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      success: json['success'] ?? false,
      response: json['response'] ?? json['answer'],
      agentId: json['agent_id'],
      agentName: json['agent_name'],
      mode: json['mode'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      error: json['error'],
      metadata: json['metadata'],
    );
  }
}

class AgentService {
  AgentService._();

  static final List<AgentInfo> _registeredAgents = [

    const AgentInfo(
      id: 'offline_knowledge',
      name: 'Offline Knowledge Agent',
      description:
          'Provides instant responses from cached knowledge base. Works completely offline for app FAQs and basic educational content.',
      capabilities: [
        AgentCapability.textProcessing,
        AgentCapability.contentGeneration
      ],
      priority: AgentPriority.critical,
      defaultMode: AgentMode.offline,
    ),

    const AgentInfo(
      id: 'study_assistant',
      name: 'Study Assistant Agent',
      description:
          'AI-powered study helper for homework, explanations, and problem solving. Uses Gemini API online, cached Q&A offline.',
      capabilities: [
        AgentCapability.textProcessing,
        AgentCapability.contentGeneration,
        AgentCapability.assessment
      ],
      priority: AgentPriority.high,
      defaultMode: AgentMode.auto,
    ),

    const AgentInfo(
      id: 'voice_interface',
      name: 'Voice Interface Agent',
      description:
          'Handles voice input/output with TTS and STT. Provides voice-first accessibility for low-literacy users.',
      capabilities: [
        AgentCapability.voiceProcessing,
        AgentCapability.textProcessing,
        AgentCapability.accessibility
      ],
      priority: AgentPriority.high,
      defaultMode: AgentMode.auto,
    ),

    const AgentInfo(
      id: 'language_support',
      name: 'Language Support Agent',
      description:
          'Handles multi-language support for Hindi, Punjabi, and English. Provides translation and language detection.',
      capabilities: [
        AgentCapability.translation,
        AgentCapability.textProcessing
      ],
      priority: AgentPriority.high,
      defaultMode: AgentMode.auto,
    ),

    const AgentInfo(
      id: 'assessment',
      name: 'Assessment Agent',
      description:
          'Generates quizzes, tests, and provides learning assessments. Uses AI for dynamic questions, cached templates offline.',
      capabilities: [
        AgentCapability.assessment,
        AgentCapability.contentGeneration
      ],
      priority: AgentPriority.medium,
      defaultMode: AgentMode.auto,
    ),

    const AgentInfo(
      id: 'content_discovery',
      name: 'Content Discovery Agent',
      description:
          'Finds educational videos, articles, and learning resources. Uses YouTube API and curated content library.',
      capabilities: [
        AgentCapability.videoRecommendation,
        AgentCapability.contentGeneration
      ],
      priority: AgentPriority.medium,
      defaultMode: AgentMode.online,
    ),

    const AgentInfo(
      id: 'study_path_planner',
      name: 'Study Path Planner Agent',
      description:
          'Creates personalized study plans and learning paths based on syllabus, progress, and available time.',
      capabilities: [
        AgentCapability.learningPath,
        AgentCapability.contentGeneration
      ],
      priority: AgentPriority.medium,
      defaultMode: AgentMode.auto,
    ),

    const AgentInfo(
      id: 'accessibility',
      name: 'Accessibility Agent',
      description:
          'Ensures content is accessible for users with disabilities. Provides text scaling, high contrast, and screen reader support.',
      capabilities: [
        AgentCapability.accessibility,
        AgentCapability.textProcessing
      ],
      priority: AgentPriority.high,
      defaultMode: AgentMode.offline,
    ),

    const AgentInfo(
      id: 'offline_photomath',
      name: 'Offline PhotoMath Agent',
      description:
          'Solves math problems from camera images using offline OCR (Tesseract) and SymPy for symbolic math.',
      capabilities: [
        AgentCapability.imageProcessing,
        AgentCapability.contentGeneration
      ],
      priority: AgentPriority.high,
      defaultMode: AgentMode.offline,
    ),
  ];

  static List<AgentInfo> getRegisteredAgents() =>
      List.unmodifiable(_registeredAgents);

  static int get agentCount => _registeredAgents.length;

  static AgentInfo? getAgentById(String id) {
    try {
      return _registeredAgents.firstWhere((agent) => agent.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<AgentInfo> getAgentsByCapability(AgentCapability capability) {
    return _registeredAgents
        .where((agent) => agent.capabilities.contains(capability))
        .toList();
  }

  static List<AgentInfo> getAgentsByPriority(AgentPriority priority) {
    return _registeredAgents
        .where((agent) => agent.priority == priority)
        .toList();
  }

  static List<AgentInfo> getCriticalAgents() {
    return _registeredAgents
        .where((agent) =>
            agent.priority == AgentPriority.critical ||
            agent.defaultMode == AgentMode.offline)
        .toList();
  }

  static Future<AgentResponse> processQuery({
    required String query,
    Map<String, dynamic>? context,
    String? preferredAgentId,
    AgentMode mode = AgentMode.auto,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/orchestrator/process'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'context': context ?? {},
              'preferred_agent': preferredAgentId,
              'mode': mode.value,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AgentResponse.fromJson(data);
      } else {
        return AgentResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AgentService processQuery error: $e');

      return _processOfflineFallback(query, context);
    }
  }

  static Future<AgentResponse> processWithAgent({
    required String agentId,
    required String query,
    Map<String, dynamic>? context,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/agents/$agentId/process'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'context': context ?? {},
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AgentResponse.fromJson(data);
      } else {
        return AgentResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AgentService processWithAgent error: $e');
      return AgentResponse(
        success: false,
        error: 'Failed to process: $e',
      );
    }
  }

  static Future<Map<String, dynamic>?> getOrchestratorStats() async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/orchestrator/stats'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AgentService getOrchestratorStats error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getAgentStats(String agentId) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/agents/$agentId/stats'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AgentService getAgentStats error: $e');
    }
    return null;
  }

  static AgentResponse _processOfflineFallback(
      String query, Map<String, dynamic>? context) {

    final queryLower = query.toLowerCase();

    String selectedAgentId = 'offline_knowledge';
    String agentName = 'Offline Knowledge Agent';

    if (queryLower.contains('solve') ||
        queryLower.contains('math') ||
        queryLower.contains('calculate')) {
      selectedAgentId = 'offline_photomath';
      agentName = 'Offline PhotoMath Agent';
    } else if (queryLower.contains('quiz') ||
        queryLower.contains('test') ||
        queryLower.contains('question')) {
      selectedAgentId = 'assessment';
      agentName = 'Assessment Agent';
    } else if (queryLower.contains('video') ||
        queryLower.contains('watch') ||
        queryLower.contains('learn')) {
      selectedAgentId = 'content_discovery';
      agentName = 'Content Discovery Agent';
    } else if (queryLower.contains('study plan') ||
        queryLower.contains('schedule') ||
        queryLower.contains('syllabus')) {
      selectedAgentId = 'study_path_planner';
      agentName = 'Study Path Planner Agent';
    } else if (queryLower.contains('explain') ||
        queryLower.contains('homework') ||
        queryLower.contains('help')) {
      selectedAgentId = 'study_assistant';
      agentName = 'Study Assistant Agent';
    }

    return AgentResponse(
      success: true,
      response:
          'Offline mode: Query routed to $agentName. Connect to internet for full AI capabilities.',
      agentId: selectedAgentId,
      agentName: agentName,
      mode: 'offline',
      confidence: 0.7,
      metadata: {'offline_fallback': true},
    );
  }
}
