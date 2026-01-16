

library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'api_config.dart';

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _ttsInitialized = false;
  static bool _sttInitialized = false;

  static Future<void> initTTS() async {
    if (_ttsInitialized) return;

    try {
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _ttsInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  static Future<bool> speak({
    required String text,
    String language = 'en',
    double speed = 1.0,
    double pitch = 1.0,
    bool useOnline = false,
  }) async {
    await initTTS();

    if (useOnline) {
      final onlineResult = await _speakOnline(
        text: text,
        language: language,
        speed: speed,
        pitch: pitch,
      );
      if (onlineResult) return true;
    }

    return await _speakDevice(
      text: text,
      language: language,
      speed: speed,
      pitch: pitch,
    );
  }

  static Future<bool> _speakOnline({
    required String text,
    required String language,
    required double speed,
    required double pitch,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.ttsSynthesize}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'text': text,
              'language': language,
              'speed': speed,
              'pitch': pitch,
              'use_online': true,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] && data['provider'] == 'google_cloud') {

          return false;
        }
      }
      return false;
    } catch (e) {
      print('Online TTS error: $e');
      return false;
    }
  }

  static Future<bool> _speakDevice({
    required String text,
    required String language,
    required double speed,
    required double pitch,
  }) async {
    try {

      String deviceLang = language;
      if (language == 'en') deviceLang = 'en-IN';
      if (language == 'hi') deviceLang = 'hi-IN';
      if (language == 'pa') deviceLang = 'pa-IN';

      await _flutterTts.setLanguage(deviceLang);
      await _flutterTts.setSpeechRate(speed * 0.5);
      await _flutterTts.setPitch(pitch);

      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      print('Device TTS error: $e');
      return false;
    }
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<List<Map<String, String>>> getVoices({String? language}) async {
    try {
      var url = '${ApiConfig.currentBaseUrl}${ApiConfig.ttsVoices}';
      if (language != null) {
        url += '?language=$language';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(
            data['voices'].map((v) => Map<String, String>.from(v)));
      }
      return [];
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  static Future<bool> initSTT() async {
    if (_sttInitialized) return true;

    try {
      _sttInitialized = await _speech.initialize(
        onError: (error) => print('STT error: $error'),
        onStatus: (status) => print('STT status: $status'),
      );
      return _sttInitialized;
    } catch (e) {
      print('STT initialization error: $e');
      return false;
    }
  }

  static Future<String?> listen({
    String language = 'en-IN',
    Duration timeout = const Duration(seconds: 30),
    Function(String)? onResult,
  }) async {
    final initialized = await initSTT();
    if (!initialized) {
      print('STT not available');
      return null;
    }

    String? finalResult;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          finalResult = result.recognizedWords;
          if (onResult != null) {
            onResult(result.recognizedWords);
          }
        }
      },
      localeId: language,
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );

    await Future.delayed(timeout);
    return finalResult;
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static bool get isListening => _speech.isListening;

  static Future<List<Map<String, String>>> getSupportedLanguages() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.sttLanguages}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(
            data['languages'].map((l) => Map<String, String>.from(l)));
      }
      return [];
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  static Future<List<stt.LocaleName>> getDeviceLanguages() async {
    final initialized = await initSTT();
    if (!initialized) return [];

    return await _speech.locales();
  }

  static Future<bool> checkTTSHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.ttsHealth}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('TTS health check failed: $e');
      return false;
    }
  }

  static Future<bool> checkSTTHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.sttHealth}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('STT health check failed: $e');
      return false;
    }
  }
}
