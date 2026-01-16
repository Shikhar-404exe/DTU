

library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../main.dart';
import '../services/qr_share_helper.dart';
import 'note_share_qr.dart';

class Doubt {
  final String id;
  final String title;
  final String? description;
  final String? voiceText;
  final String? voicePath;
  final String? markedText;
  final String? sourceNote;
  final DateTime createdAt;
  final bool isResolved;

  Doubt({
    required this.id,
    required this.title,
    this.description,
    this.voiceText,
    this.voicePath,
    this.markedText,
    this.sourceNote,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'voiceText': voiceText,
        'voicePath': voicePath,
        'markedText': markedText,
        'sourceNote': sourceNote,
        'createdAt': createdAt.toIso8601String(),
        'isResolved': isResolved,
      };

  factory Doubt.fromJson(Map<String, dynamic> json) => Doubt(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        voiceText: json['voiceText'] as String?,
        voicePath: json['voicePath'] as String?,
        markedText: json['markedText'] as String?,
        sourceNote: json['sourceNote'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
      );

  Doubt copyWith({
    String? id,
    String? title,
    String? description,
    String? voiceText,
    String? voicePath,
    String? markedText,
    String? sourceNote,
    DateTime? createdAt,
    bool? isResolved,
  }) =>
      Doubt(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        voiceText: voiceText ?? this.voiceText,
        voicePath: voicePath ?? this.voicePath,
        markedText: markedText ?? this.markedText,
        sourceNote: sourceNote ?? this.sourceNote,
        createdAt: createdAt ?? this.createdAt,
        isResolved: isResolved ?? this.isResolved,
      );
}

Future<void> addDoubtFromText(String markedText, String sourceNote) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final doubtsJson = prefs.getString('saved_doubts');
    List<Doubt> doubts = [];

    if (doubtsJson != null) {
      final List<dynamic> decoded = jsonDecode(doubtsJson);
      doubts = decoded.map((d) => Doubt.fromJson(d)).toList();
    }

    final doubt = Doubt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: markedText.length > 50
          ? '${markedText.substring(0, 50)}...'
          : markedText,
      markedText: markedText,
      sourceNote: sourceNote,
      createdAt: DateTime.now(),
    );

    doubts.insert(0, doubt);
    final newJson = jsonEncode(doubts.map((d) => d.toJson()).toList());
    await prefs.setString('saved_doubts', newJson);
  } catch (e) {
    debugPrint('Error adding doubt: $e');
  }
}

class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});

  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen>
    with TickerProviderStateMixin {
  List<Doubt> _doubts = [];
  bool _isLoading = true;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = '';
  bool _speechAvailable = false;
  Timer? _listeningTimer;
  int _listeningDuration = 0;

  bool _showResolved = false;

  late AnimationController _fabAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadDoubts();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  Future<void> _loadDoubts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final doubtsJson = prefs.getString('saved_doubts');
      if (doubtsJson != null) {
        final List<dynamic> decoded = jsonDecode(doubtsJson);
        _doubts = decoded.map((d) => Doubt.fromJson(d)).toList();
        _doubts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error loading doubts: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveDoubts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doubtsJson = jsonEncode(_doubts.map((d) => d.toJson()).toList());
      await prefs.setString('saved_doubts', doubtsJson);
    } catch (e) {
      debugPrint('Error saving doubts: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showSnackBar('Speech recognition not available', isError: true);
      return;
    }

    setState(() {
      _isListening = true;
      _spokenText = '';
      _listeningDuration = 0;
    });

    _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _listeningDuration++);
    });

    _showSnackBar('🎙️ Listening... Speak your doubt');

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_IN',
    );
  }

  Future<void> _stopListening() async {
    _listeningTimer?.cancel();
    await _speech.stop();
    setState(() => _isListening = false);

    if (_spokenText.isNotEmpty) {
      _showAddDoubtDialog(voiceText: _spokenText);
    } else {
      _showSnackBar('No speech detected. Try again.', isError: true);
    }
  }

  void _addDoubt(String title, String? description,
      {String? voiceText, String? voicePath}) {
    final doubt = Doubt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      voiceText: voiceText,
      voicePath: voicePath,
      createdAt: DateTime.now(),
    );

    setState(() {
      _doubts.insert(0, doubt);
    });
    _saveDoubts();
    _showSnackBar('Doubt added! 📝');
  }

  void _toggleResolved(Doubt doubt) {
    final index = _doubts.indexWhere((d) => d.id == doubt.id);
    if (index != -1) {
      setState(() {
        _doubts[index] = doubt.copyWith(isResolved: !doubt.isResolved);
      });
      _saveDoubts();
      _showSnackBar(
        _doubts[index].isResolved
            ? 'Marked as resolved ✅'
            : 'Marked as pending 📌',
      );
    }
  }

  void _deleteDoubt(Doubt doubt) {
    setState(() {
      _doubts.removeWhere((d) => d.id == doubt.id);
    });
    _saveDoubts();
    _showSnackBar('Doubt deleted 🗑️');
  }

  List<Doubt> get _filteredDoubts {
    return _doubts.where((d) {
      return _showResolved || !d.isResolved;
    }).toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFFF6B6B) : AppColors.mint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAddDoubtDialog({String? voiceText}) {
    final titleController = TextEditingController(text: voiceText ?? '');
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: AppColors.salmon.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.salmon, AppColors.peach]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(voiceText != null ? '🎤' : '📝',
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    voiceText != null ? 'Voice Doubt' : 'New Doubt',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Your Question',
                  hintText: 'What do you want to ask?',
                  prefixIcon: const Icon(Icons.help_outline_rounded,
                      color: AppColors.salmon),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.salmon, width: 2)),
                  filled: true,
                  fillColor: AppColors.salmonLight.withOpacity(0.3),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'More details (optional)',
                  hintText: 'Add context or examples...',
                  prefixIcon:
                      const Icon(Icons.notes_rounded, color: AppColors.mint),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.mint, width: 2)),
                  filled: true,
                  fillColor: AppColors.mintLight.withOpacity(0.3),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      _showSnackBar('Please enter your question',
                          isError: true);
                      return;
                    }
                    Navigator.pop(context);
                    _addDoubt(
                      titleController.text.trim(),
                      descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      voiceText: voiceText,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.salmon.withOpacity(0.4),
                  ),
                  child: Text('Add Doubt ✨',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _shareDoubt(Doubt doubt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.salmon)),
    );

    try {
      final shareData = {
        'type': 'doubt',
        'title': doubt.title,
        'description': doubt.description,
        'voiceText': doubt.voiceText,
        'markedText': doubt.markedText,
        'sourceNote': doubt.sourceNote,
      };

      final payload = await QRShareHelper.prepareForSharing(
          title: doubt.title, content: jsonEncode(shareData));

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  NoteShareQR(note: payload.toJson(), detailedness: 1.0)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Failed to share: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pulseController.dispose();
    _speech.stop();
    _listeningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.salmon))
                  : _filteredDoubts.isEmpty
                      ? _buildEmptyState()
                      : _buildDoubtsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    final unresolvedCount = _doubts.where((d) => !d.isResolved).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.salmon, AppColors.peach],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: AppColors.salmon.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Text('💭', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Doubts',
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Text('$unresolvedCount pending • ${_doubts.length} total',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppColors.textLight)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _showResolved
                  ? AppColors.mint.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => setState(() => _showResolved = !_showResolved),
              icon: Icon(
                _showResolved
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                color: _showResolved ? AppColors.mint : AppColors.textLight,
              ),
              tooltip: _showResolved ? 'Hide resolved' : 'Show resolved',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.salmonLight.withOpacity(0.5),
                AppColors.mintLight.withOpacity(0.5)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child:
                const Center(child: Text('🤔', style: TextStyle(fontSize: 60))),
          ),
          const SizedBox(height: 24),
          Text('No doubts yet!',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('Record a voice note or add a text doubt',
              style:
                  GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('💡 Tip: Long press on notes to mark text as doubt',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.salmon,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDoubtsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredDoubts.length,
      itemBuilder: (context, index) => _buildDoubtCard(_filteredDoubts[index]),
    );
  }

  Widget _buildDoubtCard(Doubt doubt) {
    final timeAgo = _formatTimeAgo(doubt.createdAt);
    final hasVoice = doubt.voicePath != null || doubt.voiceText != null;
    final hasMarkedText = doubt.markedText != null;

    Color cardAccent = AppColors.salmon;
    String typeEmoji = '📝';
    if (hasVoice) {
      cardAccent = AppColors.mint;
      typeEmoji = '🎤';
    } else if (hasMarkedText) {
      cardAccent = AppColors.sky;
      typeEmoji = '📌';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardAccent.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: cardAccent.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDoubtDetails(doubt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: cardAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child:
                          Text(typeEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doubt.title,
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                decoration: doubt.isResolved
                                    ? TextDecoration.lineThrough
                                    : null),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (doubt.sourceNote != null)
                            Text('From: ${doubt.sourceNote}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: doubt.isResolved
                              ? AppColors.mint.withOpacity(0.2)
                              : AppColors.peach.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(doubt.isResolved ? '✅' : '📌',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                if (doubt.markedText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.skyLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sky.withOpacity(0.3)),
                    ),
                    child: Text('"${doubt.markedText}"',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(timeAgo,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    _buildActionButton(
                        icon: Icons.share_rounded,
                        onTap: () => _shareDoubt(doubt),
                        color: AppColors.sky),
                    const SizedBox(width: 8),
                    _buildActionButton(
                        icon: doubt.isResolved
                            ? Icons.refresh_rounded
                            : Icons.check_rounded,
                        onTap: () => _toggleResolved(doubt),
                        color: AppColors.mint),
                    const SizedBox(width: 8),
                    _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: () => _confirmDelete(doubt),
                        color: const Color(0xFFFF6B6B)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  void _showDoubtDetails(Doubt doubt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.salmon.withOpacity(0.2), blurRadius: 20)
              ]),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(doubt.title,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(_formatDate(doubt.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
                if (doubt.sourceNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.skyLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('📚 From: ${doubt.sourceNote}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textDark)),
                  ),
                ],
                if (doubt.markedText != null) ...[
                  const SizedBox(height: 20),
                  Text('Marked Text',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.skyLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.sky.withOpacity(0.3))),
                    child: Text(doubt.markedText!,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.6)),
                  ),
                ],
                if (doubt.description != null) ...[
                  const SizedBox(height: 20),
                  Text('Details',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Text(doubt.description!,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.6)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareDoubt(doubt);
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sky,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleResolved(doubt);
                        },
                        icon: Icon(doubt.isResolved
                            ? Icons.replay_rounded
                            : Icons.check_rounded),
                        label: Text(doubt.isResolved ? 'Reopen' : 'Solved'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: doubt.isResolved
                                ? AppColors.peach
                                : AppColors.mint,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Doubt doubt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Doubt?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.poppins(color: AppColors.textLight)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppColors.textLight))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDoubt(doubt);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.scale(
            scale: _isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0,
            child: GestureDetector(
              onLongPressStart: (_) => _startListening(),
              onLongPressEnd: (_) => _stopListening(),
              child: FloatingActionButton(
                heroTag: 'voice',
                onPressed: () {
                  _showSnackBar('💡 Hold button to record voice doubt');
                },
                backgroundColor:
                    _isListening ? const Color(0xFFFF6B6B) : AppColors.mint,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white, size: 26),
                    if (_isListening)
                      Text(_formatDuration(_listeningDuration),
                          style: const TextStyle(
                              fontSize: 8, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'add',
          onPressed: () => _showAddDoubtDialog(),
          backgroundColor: AppColors.salmon,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
