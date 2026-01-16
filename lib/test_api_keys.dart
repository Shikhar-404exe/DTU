

library;

import 'dart:convert';
import 'package:http/http.dart' as http;

const String openRouterApiKey =
    '';
const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
const String openRouterModel = 'xiaomi/mimo-v2-flash:free';

Future<void> main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║             API KEY VERIFICATION TEST                       ║');
  print('╠══════════════════════════════════════════════════════════════╣');
  print('');

  await testOpenRouterApi();
  print('');

  print('╠══════════════════════════════════════════════════════════════╣');
  print('║  OpenRouter: Xiaomi MiMo-V2-Flash (FREE)                    ║');
  print('╚══════════════════════════════════════════════════════════════╝');
}

Future<void> testOpenRouterApi() async {
  print('🔍 Testing OpenRouter AI API (MiMo-V2-Flash)...');
  try {
    final url = Uri.parse('$openRouterBaseUrl/chat/completions');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openRouterApiKey',
            'HTTP-Referer': 'https://vidyarthi.app',
            'X-Title': 'Vidyarthi Education App',
          },
          body: jsonEncode({
            'model': openRouterModel,
            'messages': [
              {
                'role': 'user',
                'content': 'Say "Hello, API test successful!" in one line.'
              }
            ],
            'max_tokens': 50,
            'temperature': 0.1,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'];
      print('   ✅ OPENROUTER API: WORKING');
      print('   📝 Model: $openRouterModel');
      print('   📝 Response: ${text?.toString().trim() ?? "OK"}');
    } else {
      print('   ❌ OPENROUTER API: FAILED');
      print('   📝 Status: ${response.statusCode}');
      print('   📝 Error: ${response.body}');
    }
  } catch (e) {
    print('   ❌ OPENROUTER API: ERROR');
    print('   📝 Exception: $e');
  }
}
