/// API Key Verification Script
/// Run with: dart run lib/test_api_keys.dart
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// Gemini API Configuration (only active AI provider)
const String geminiApiKey = 'AIzaSyCSzJ9j0nOqnhyAqmrDacJTm9daye9t59w';
const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
const String geminiModel = 'gemini-2.5-flash';

Future<void> main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║             API KEY VERIFICATION TEST                       ║');
  print('╠══════════════════════════════════════════════════════════════╣');
  print('');

  // Test Gemini (only active provider)
  await testGeminiApi();
  print('');

  print('╠══════════════════════════════════════════════════════════════╣');
  print('║  OpenAI: DISABLED (no billing credits)                      ║');
  print('║  HuggingFace: DISABLED (invalid token)                      ║');
  print('╚══════════════════════════════════════════════════════════════╝');
}

Future<void> testGeminiApi() async {
  print('🔍 Testing Gemini AI API...');
  try {
    final url = Uri.parse(
        '$geminiBaseUrl/models/$geminiModel:generateContent?key=$geminiApiKey');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'Say "Hello, API test successful!" in one line.'}
                ]
              }
            ],
            'generationConfig': {
              'maxOutputTokens': 50,
              'temperature': 0.1,
            }
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      print('   ✅ GEMINI API: WORKING');
      print('   📝 Model: $geminiModel');
      print('   📝 Response: ${text?.toString().trim() ?? "OK"}');
    } else {
      print('   ❌ GEMINI API: FAILED');
      print('   📝 Status: ${response.statusCode}');
      print('   📝 Error: ${response.body}');
    }
  } catch (e) {
    print('   ❌ GEMINI API: ERROR');
    print('   📝 Exception: $e');
  }
}
