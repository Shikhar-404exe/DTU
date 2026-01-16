

library;

import 'package:flutter/material.dart';
import '../services/offline_tts_service.dart';

class ReadAloudButton extends StatefulWidget {
  final String textContent;
  final String? tooltip;
  final IconData? icon;
  final Color? color;
  final double? iconSize;

  const ReadAloudButton({
    super.key,
    required this.textContent,
    this.tooltip,
    this.icon,
    this.color,
    this.iconSize,
  });

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  final _tts = OfflineTtsService();
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isSpeaking ? Icons.stop_circle : (widget.icon ?? Icons.volume_up),
        color: _isSpeaking ? Colors.red : (widget.color ?? Colors.blue),
        size: widget.iconSize,
      ),
      onPressed: _toggleSpeech,
      tooltip: _isSpeaking ? 'Stop Reading' : (widget.tooltip ?? 'Read Aloud'),
    );
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    } else {
      if (mounted) {
        setState(() => _isSpeaking = true);
      }
      await _tts.speak(widget.textContent);
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

class ReadAloudFloatingButton extends StatefulWidget {
  final String textContent;

  const ReadAloudFloatingButton({
    super.key,
    required this.textContent,
  });

  @override
  State<ReadAloudFloatingButton> createState() =>
      _ReadAloudFloatingButtonState();
}

class _ReadAloudFloatingButtonState extends State<ReadAloudFloatingButton> {
  final _tts = OfflineTtsService();
  bool _isSpeaking = false;
  bool _showControls = false;
  double _speed = 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        if (_showControls) ...[
          _buildSpeedControl(),
          const SizedBox(height: 8),
        ],

        FloatingActionButton(
          onPressed: _toggleSpeech,
          tooltip: _isSpeaking ? 'Stop' : 'Read Aloud',
          backgroundColor: _isSpeaking ? Colors.red : Colors.blue,
          child: Icon(_isSpeaking ? Icons.stop : Icons.play_arrow),
        ),

        if (_isSpeaking) ...[
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () => setState(() => _showControls = !_showControls),
            child: Icon(_showControls ? Icons.expand_more : Icons.settings),
          ),
        ],
      ],
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Slider(
              value: _speed,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(_speed * 100).toInt()}%',
              onChanged: (value) {
                setState(() => _speed = value);
                _tts.setSpeed(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _showControls = false;
      });
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(widget.textContent);
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _showControls = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
