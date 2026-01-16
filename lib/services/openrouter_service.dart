

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class AIResult {
  final bool success;
  final String? content;
  final String? error;

  const AIResult._({
    required this.success,
    this.content,
    this.error,
  });

  factory AIResult.success(String content) => AIResult._(
        success: true,
        content: content,
      );

  factory AIResult.failure(String error) => AIResult._(
        success: false,
        error: error,
      );
}

class OpenRouterService {
  OpenRouterService._();

  static const Duration _timeout = Duration(seconds: 90);

  static Future<AIResult> generateNotes({
    required String subject,
    required String topic,
    String? board,
    String? classLevel,
    String? additionalDetails,
    String language = 'English',
    double detailLevel = 0.5,
  }) async {
    try {
      final prompt = _buildNotesPrompt(
        subject: subject,
        topic: topic,
        board: board,
        classLevel: classLevel,
        additionalDetails: additionalDetails,
        language: language,
        detailLevel: detailLevel,
      );

      return await _callOpenRouterApi(prompt);
    } catch (e) {
      debugPrint('OpenRouter generateNotes error: $e');
      return AIResult.failure('Failed to generate notes: $e');
    }
  }

  static Future<AIResult> summarizeText({
    required String text,
    String language = 'English',
    int maxLength = 500,
  }) async {
    try {
      final prompt = '''
You are an expert at summarizing educational content.
Summarize the following text in $language.
Keep the summary concise but comprehensive, around $maxLength words maximum.
Maintain the key points and important details.

Text to summarize:
$text

Provide a clear, well-structured summary:
''';

      return await _callOpenRouterApi(prompt);
    } catch (e) {
      debugPrint('OpenRouter summarizeText error: $e');
      return AIResult.failure('Failed to summarize text: $e');
    }
  }

  static Future<AIResult> explainConcept({
    required String concept,
    required String subject,
    String? classLevel,
    String language = 'English',
  }) async {
    try {
      final levelContext =
          classLevel != null ? 'for a $classLevel student' : 'in simple terms';

      final prompt = '''
You are an expert $subject teacher. Explain the following concept $levelContext in $language.

Concept: $concept

Provide a clear explanation with:
1. Definition
2. Key points
3. Examples (if applicable)
4. Real-world applications (if applicable)

Make the explanation engaging and easy to understand:
''';

      return await _callOpenRouterApi(prompt);
    } catch (e) {
      debugPrint('OpenRouter explainConcept error: $e');
      return AIResult.failure('Failed to explain concept: $e');
    }
  }

  static Future<AIResult> generateQuiz({
    required String topic,
    required String subject,
    int questionCount = 5,
    String difficulty = 'medium',
    String language = 'English',
  }) async {
    try {
      final prompt = '''
You are an expert quiz creator for educational content.
Create $questionCount $difficulty difficulty questions about "$topic" in $subject.
Generate the quiz in $language.

For each question provide:
1. The question
2. Four options (A, B, C, D)
3. The correct answer
4. A brief explanation

Format the output as:
Q1: [Question]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Answer: [Correct letter]
Explanation: [Brief explanation]

Generate the quiz:
''';

      return await _callOpenRouterApi(prompt);
    } catch (e) {
      debugPrint('OpenRouter generateQuiz error: $e');
      return AIResult.failure('Failed to generate quiz: $e');
    }
  }

  static Future<AIResult> solveMathProblem({
    required String problem,
    bool showSteps = true,
    String language = 'English',
  }) async {
    try {
      final stepsInstruction = showSteps
          ? 'Show all steps clearly with explanations for each step.'
          : 'Provide the final answer directly.';

      final prompt = '''
You are an expert mathematics tutor.
Solve the following math problem in $language.
$stepsInstruction

Problem: $problem

Solution:
''';

      return await _callOpenRouterApi(prompt);
    } catch (e) {
      debugPrint('OpenRouter solveMathProblem error: $e');
      return AIResult.failure('Failed to solve problem: $e');
    }
  }

  static Future<AIResult> chat({
    required String message,
    String? systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      return await _callOpenRouterApiWithMessages(
        message: message,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );
    } catch (e) {
      debugPrint('OpenRouter chat error: $e');
      return AIResult.failure('Failed to get response: $e');
    }
  }

  static String _buildNotesPrompt({
    required String subject,
    required String topic,
    String? board,
    String? classLevel,
    String? additionalDetails,
    required String language,
    required double detailLevel,
  }) {
    String detailInstruction;
    if (detailLevel < 0.3) {
      detailInstruction =
          'Keep it brief: 1-2 subtopics per section, 2-3 points each.';
    } else if (detailLevel < 0.7) {
      detailInstruction =
          'Moderate detail: 2-3 subtopics per section, 3-5 points each.';
    } else {
      detailInstruction =
          'Comprehensive: 3-5 subtopics per section, 5-8 points each with examples.';
    }

    final boardContext =
        board != null && board.isNotEmpty ? 'following $board curriculum' : '';

    final classContext = classLevel != null && classLevel.isNotEmpty
        ? 'for $classLevel students'
        : '';

    final additionalContext =
        additionalDetails != null && additionalDetails.isNotEmpty
            ? '\n\nFocus on: $additionalDetails'
            : '';

    return '''
Create engaging, well-formatted study notes on "$topic" in $subject $classContext $boardContext.
Language: $language
$detailInstruction
$additionalContext

IMPORTANT FORMATTING RULES:
- Use emojis to make content engaging and visual
- Use CAPITAL LETTERS for main headings
- DO NOT use asterisks (**) or any markdown for bold text
- Use plain text with clear labels like "Definition:", "Explanation:", etc.
- Use simple bullet points (•) instead of -, *, or special markdown
- AVOID special characters like #, **, *, -, ~, etc.
- Add proper spacing between sections for better readability
- Make it colorful, engaging, and student-friendly
- Use emojis strategically to highlight important points

Format as follows:

📚 $topic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ INTRODUCTION

🎯 Overview: Brief introduction to the topic (2-3 lines)

💡 Why It Matters: Importance and relevance

🎓 Learning Goals: What you will learn from this topic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2️⃣ KEY CONCEPTS

📌 Concept 1: [Name]

   Definition: Clear definition in simple words

   Explanation: Detailed explanation with examples

   Key Points:
   • Point 1
   • Point 2
   • Point 3

   Example: Practical example with clear explanation

📌 Concept 2: [Name]

   Definition: Clear definition

   Explanation: Detailed explanation

   Key Points:
   • Point 1
   • Point 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣ IMPORTANT FORMULAS AND RULES (if applicable)

📐 Formula 1: Name of formula

   [Formula written clearly]

   Where:
   • Variable 1 = explanation
   • Variable 2 = explanation

   When to use: Application context

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4️⃣ STEP-BY-STEP PROCESS (if applicable)

🔹 Step 1: Description
   • Sub-step a
   • Sub-step b

🔹 Step 2: Description
   • Sub-step a
   • Sub-step b

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5️⃣ REAL-WORLD APPLICATIONS

🌍 Application 1: Description with practical example

🌍 Application 2: Description with practical example

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6️⃣ COMMON MISTAKES TO AVOID

❌ Mistake 1: Description of common error
✅ Correct Way: How to do it right

❌ Mistake 2: Description of common error
✅ Correct Way: How to do it right

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7️⃣ PRACTICE QUESTIONS

❓ Q1: Question here?

   Answer: Detailed answer with clear explanation

❓ Q2: Question here?

   Answer: Detailed answer with clear explanation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8️⃣ SUMMARY AND KEY TAKEAWAYS

🎯 Remember These Points:

✓ Key point 1
✓ Key point 2
✓ Key point 3
✓ Key point 4

💭 Quick Revision:

→ Must-remember fact 1
→ Must-remember fact 2
→ Must-remember fact 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Note: Make notes exam-focused, accurate, and easy to understand.
''';
  }

  static Future<AIResult> _callOpenRouterApi(String prompt) async {
    return _callOpenRouterApiWithMessages(message: prompt);
  }

  static Future<AIResult> _callOpenRouterApiWithMessages({
    required String message,
    String? systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final url = Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions');

    final messages = <Map<String, String>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (conversationHistory != null) {
      messages.addAll(conversationHistory);
    }

    messages.add({'role': 'user', 'content': message});

    final requestBody = {
      'model': AppConstants.openRouterModel,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 8192,
      'top_p': 0.95,
    };

    try {
      debugPrint('Calling OpenRouter API...');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
              'HTTP-Referer': 'https://vidyarthi.app',
              'X-Title': 'Vidyarthi Education App',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('OpenRouter API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>;
          final messageData = firstChoice['message'] as Map<String, dynamic>?;

          if (messageData != null) {
            final content = messageData['content'] as String?;
            if (content != null && content.isNotEmpty) {
              return AIResult.success(content);
            }
          }
        }

        return AIResult.failure('No content generated');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Bad request';
        return AIResult.failure('API Error: $message');
      } else if (response.statusCode == 401) {
        return AIResult.failure('API key invalid');
      } else if (response.statusCode == 402) {
        return AIResult.failure('Insufficient credits');
      } else if (response.statusCode == 429) {
        return AIResult.failure('Rate limit exceeded. Please try again later.');
      } else {
        debugPrint('OpenRouter error body: ${response.body}');
        return AIResult.failure('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenRouter API call error: $e');
      if (e.toString().contains('TimeoutException')) {
        return AIResult.failure('Request timed out. Please try again.');
      }
      return AIResult.failure('Network error: $e');
    }
  }

  static bool get isConfigured =>
      AppConstants.openRouterApiKey.isNotEmpty &&
      AppConstants.openRouterApiKey != 'YOUR_API_KEY_HERE';

  static Future<bool> testConnection() async {
    try {
      final result = await _callOpenRouterApi('Say "Hello" in one word.');
      return result.success;
    } catch (e) {
      debugPrint('OpenRouter connection test failed: $e');
      return false;
    }
  }
}
