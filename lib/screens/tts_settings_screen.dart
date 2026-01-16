

library;

import 'package:flutter/material.dart';
import '../services/offline_tts_service.dart';
import '../main.dart';

class TtsSettingsScreen extends StatefulWidget {
  const TtsSettingsScreen({super.key});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  final _tts = OfflineTtsService();
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _selectedLanguage = 'en-IN';
  List<dynamic> _availableVoices = [];
  List<dynamic> _availableLanguages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTtsInfo();
  }

  Future<void> _loadTtsInfo() async {
    await _tts.initialize();

    final voices = await _tts.getAvailableVoices();
    final languages = await _tts.getAvailableLanguages();

    if (mounted) {
      setState(() {
        _availableVoices = voices;
        _availableLanguages = languages;
        _speechRate = _tts.speechRate;
        _volume = _tts.volume;
        _pitch = _tts.pitch;
        _selectedLanguage = _tts.language;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Text-to-Speech Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(isDark),
                const SizedBox(height: 20),
                _buildSpeedControl(isDark),
                const SizedBox(height: 20),
                _buildVolumeControl(isDark),
                const SizedBox(height: 20),
                _buildPitchControl(isDark),
                const SizedBox(height: 20),
                _buildLanguageSelector(isDark),
                const SizedBox(height: 20),
                _buildTestButton(isDark),
                const SizedBox(height: 20),
                _buildLanguageInfo(isDark),
              ],
            ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Offline TTS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uses device\'s built-in voice engine. Works without internet!',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speech Speed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.speed, size: 20),
            Expanded(
              child: Slider(
                value: _speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_speechRate * 100).toInt()}%',
                onChanged: (value) {
                  setState(() => _speechRate = value);
                  _tts.setSpeed(value);
                },
              ),
            ),
            Text('${(_speechRate * 100).toInt()}%'),
          ],
        ),
        Text(
          _speechRate < 0.4
              ? '🐌 Slow (good for learning)'
              : _speechRate > 0.7
                  ? '🚀 Fast (quick revision)'
                  : '👍 Normal',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textLightDark : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.volume_up, size: 20),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume * 100).toInt()}%',
                onChanged: (value) {
                  setState(() => _volume = value);
                  _tts.setVolume(value);
                },
              ),
            ),
            Text('${(_volume * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildPitchControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Pitch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.graphic_eq, size: 20),
            Expanded(
              child: Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: _pitch.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _pitch = value);
                  _tts.setPitch(value);
                },
              ),
            ),
            Text(_pitch.toStringAsFixed(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.language),
          ),
          items: const [
            DropdownMenuItem(
                value: 'en-IN', child: Text('🇮🇳 English (India)')),
            DropdownMenuItem(
                value: 'hi-IN', child: Text('🇮🇳 हिन्दी (Hindi)')),
            DropdownMenuItem(
                value: 'pa-IN', child: Text('🇮🇳 ਪੰਜਾਬੀ (Punjabi)')),
            DropdownMenuItem(value: 'en-US', child: Text('🇺🇸 English (US)')),
            DropdownMenuItem(value: 'en-GB', child: Text('🇬🇧 English (UK)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLanguage = value);
              _tts.setLanguage(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTestButton(bool isDark) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_circle),
      label: const Text('Test Voice'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.salmonDark : AppColors.salmon,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _tts.testVoice(),
    );
  }

  Widget _buildLanguageInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Language Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Available languages depend on your device\'s installed TTS voices. '
            'You can download more voices from your device settings.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
          if (_availableLanguages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Detected: ${_availableLanguages.length} languages',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
