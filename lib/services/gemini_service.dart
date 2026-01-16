

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class GeminiResult {
  final bool success;
  final String? content;
  final String? error;

  const GeminiResult._({
    required this.success,
    this.content,
    this.error,
  });

  factory GeminiResult.success(String content) => GeminiResult._(
        success: true,
        content: content,
      );

  factory GeminiResult.failure(String error) => GeminiResult._(
        success: false,
        error: error,
      );
}

class GeminiService {
  GeminiService._();

  static const Duration _timeout = Duration(seconds: 90);

  static Future<GeminiResult> generateNotes({
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

      return await _callGeminiApi(prompt);
    } catch (e) {
      debugPrint('Gemini generateNotes error: $e');
      return GeminiResult.failure('Failed to generate notes: $e');
    }
  }

  static Future<GeminiResult> summarizeText({
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

      return await _callGeminiApi(prompt);
    } catch (e) {
      debugPrint('Gemini summarizeText error: $e');
      return GeminiResult.failure('Failed to summarize text: $e');
    }
  }

  static Future<GeminiResult> explainConcept({
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

      return await _callGeminiApi(prompt);
    } catch (e) {
      debugPrint('Gemini explainConcept error: $e');
      return GeminiResult.failure('Failed to explain concept: $e');
    }
  }

  static Future<GeminiResult> generateQuiz({
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

      return await _callGeminiApi(prompt);
    } catch (e) {
      debugPrint('Gemini generateQuiz error: $e');
      return GeminiResult.failure('Failed to generate quiz: $e');
    }
  }

  static Future<GeminiResult> solveMathProblem({
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

      return await _callGeminiApi(prompt);
    } catch (e) {
      debugPrint('Gemini solveMathProblem error: $e');
      return GeminiResult.failure('Failed to solve problem: $e');
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

9️⃣ ADDITIONAL RESOURCES (if applicable)

📖 Resource 1: Description
📖 Resource 2: Description

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Note: Make notes exam-focused, accurate, and easy to understand. Use emojis to make learning fun and engaging. Keep content clear, well-spaced, and visually appealing for better retention.
''';
  }

  static Future<GeminiResult> _callGeminiApi(String prompt) async {
    final url = Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions');

    final requestBody = {
      'model': AppConstants.openRouterModel,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.7,
      'max_tokens': 8192,
    };

    try {
      debugPrint('Calling OpenRouter API (MiMo)...');

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
          final message = firstChoice['message'] as Map<String, dynamic>?;

          if (message != null) {
            final text = message['content'] as String?;
            if (text != null && text.isNotEmpty) {
              return GeminiResult.success(text);
            }
          }
        }

        return GeminiResult.failure('No content generated');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Bad request';
        return GeminiResult.failure('API Error: $message');
      } else if (response.statusCode == 403) {
        return GeminiResult.failure('API key invalid or quota exceeded');
      } else if (response.statusCode == 429) {
        return GeminiResult.failure(
            'Rate limit exceeded. Please try again later.');
      } else {
        return GeminiResult.failure('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenRouter API call error: $e');
      if (e.toString().contains('TimeoutException')) {
        return GeminiResult.failure('Request timed out. Please try again.');
      }
      return GeminiResult.failure('Network error: $e');
    }
  }

  static bool get isConfigured =>
      AppConstants.openRouterApiKey.isNotEmpty &&
      AppConstants.openRouterApiKey != 'YOUR_API_KEY_HERE';

  static Future<bool> testConnection() async {
    try {
      final result = await _callGeminiApi('Say "Hello" in one word.');
      return result.success;
    } catch (e) {
      debugPrint('OpenRouter connection test failed: $e');
      return false;
    }
  }
}
