

library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OfflineTtsService {
  static final OfflineTtsService _instance = OfflineTtsService._internal();
  factory OfflineTtsService() => _instance;
  OfflineTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'en-IN';

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {

      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS: Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✓ TTS: Completed');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ TTS Error: $msg');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('⚠ TTS: Cancelled');
      });

      List<dynamic> languages = await _flutterTts.getLanguages;
      debugPrint('📢 Available TTS languages: ${languages.length}');

      _isInitialized = true;
      debugPrint('✓ Offline TTS initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> readNoteAloud(String noteContent) async {
    await initialize();

    if (noteContent.isEmpty) {
      await speak("No content to read.");
      return;
    }

    String cleanText = _cleanTextForSpeech(noteContent);
    await speak(cleanText);
  }

  Future<void> readDoubtAloud(String doubtText) async {
    await initialize();

    if (doubtText.isEmpty) return;

    await speak("The question is: $doubtText");
  }

  Future<void> readQuestionAloud(String question) async {
    await initialize();

    if (question.isEmpty) return;

    await speak("Question: $question");
  }

  Future<void> speak(String text) async {
    await initialize();

    if (text.trim().isEmpty) return;

    try {

      await stop();

      List<String> chunks = _splitIntoChunks(text, maxLength: 4000);

      for (String chunk in chunks) {
        await _flutterTts.speak(chunk);

        await _waitForCompletion();
      }
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ TTS stop error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ TTS pause error: $e');
    }
  }

  Future<void> setSpeed(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _flutterTts.setLanguage(_language);
    debugPrint('🌐 TTS language changed to: $_language');
  }

  Future<void> setLanguageFromLocale(String locale) async {
    final Map<String, String> localeToTts = {
      'en': 'en-IN',
      'hi': 'hi-IN',
      'pa': 'pa-IN',
    };

    String ttsLanguage = localeToTts[locale] ?? 'en-IN';
    await setLanguage(ttsLanguage);
  }

  Future<List<dynamic>> getAvailableVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      debugPrint('❌ Error getting voices: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      debugPrint('❌ Error getting languages: $e');
      return [];
    }
  }

  String _cleanTextForSpeech(String text) {
    String cleaned = text;

    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'#+ '), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'`(.+?)`'), r'$1');

    cleaned = cleaned.replaceAll('━', ' ');
    cleaned = cleaned.replaceAll('═', ' ');
    cleaned = cleaned.replaceAll('╔', ' ');
    cleaned = cleaned.replaceAll('╚', ' ');
    cleaned = cleaned.replaceAll('║', ' ');
    cleaned = cleaned.replaceAll('╠', ' ');
    cleaned = cleaned.replaceAll('╣', ' ');

    cleaned = cleaned.replaceAll('&', 'and');
    cleaned = cleaned.replaceAll('@', 'at');
    cleaned = cleaned.replaceAll('%', 'percent');
    cleaned = cleaned.replaceAll('+', 'plus');
    cleaned = cleaned.replaceAll('=', 'equals');
    cleaned = cleaned.replaceAll('×', 'times');
    cleaned = cleaned.replaceAll('÷', 'divided by');

    cleaned = cleaned.replaceAll('✓', 'checkmark');
    cleaned = cleaned.replaceAll('✅', 'done');
    cleaned = cleaned.replaceAll('❌', 'error');
    cleaned = cleaned.replaceAll('⚠️', 'warning');
    cleaned = cleaned.replaceAll('📝', '');
    cleaned = cleaned.replaceAll('🎯', '');
    cleaned = cleaned.replaceAll('💡', '');

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    cleaned = cleaned.replaceAll(RegExp(r'^[•\-\*]\s*', multiLine: true), '');

    return cleaned;
  }

  List<String> _splitIntoChunks(String text, {int maxLength = 4000}) {
    if (text.length <= maxLength) return [text];

    List<String> chunks = [];

    List<String> sentences = text.split(RegExp(r'[.!?]\s+'));

    String currentChunk = '';
    for (String sentence in sentences) {
      if (currentChunk.length + sentence.length > maxLength) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = sentence;
      } else {
        currentChunk += (currentChunk.isEmpty ? '' : '. ') + sentence;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  Future<void> _waitForCompletion() async {
    int waitTime = 0;
    const int maxWait = 60000;
    const int checkInterval = 100;

    while (_isSpeaking && waitTime < maxWait) {
      await Future.delayed(const Duration(milliseconds: checkInterval));
      waitTime += checkInterval;
    }

    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> testVoice() async {
    await speak(
        'This is a test of the offline text to speech feature. It works completely offline without internet.');
  }

  Future<void> dispose() async {
    await stop();
  }
}
