

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/storage_service.dart';
import '../services/qr_share_helper.dart';
import 'handwritten_scan_screen.dart';
import 'note_share_qr.dart';
import 'doubts_screen.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  bool _loading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = List.from(_notes);
      });
    } else {
      setState(() {
        _filteredNotes = _notes.where((note) {
          final title = (note['title'] ?? '').toString().toLowerCase();
          final content = (note['content'] ?? '').toString().toLowerCase();
          return title.contains(query) || content.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await StorageService.loadNotes();
      notes.sort(
          (a, b) => (b["timestamp"] ?? "").compareTo(a["timestamp"] ?? ""));
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _filteredNotes = List.from(notes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notes = [];
        _filteredNotes = [];
        _loading = false;
      });
    }
  }

  IconData _iconFor(Map<String, dynamic> note) {
    switch (note["type"]) {
      case "ebook":
        return Icons.menu_book_rounded;
      case "pdf":
        return Icons.picture_as_pdf;
      case "image":
        return Icons.image;
      case "file":
        return Icons.insert_drive_file;
      default:
        return Icons.description;
    }
  }

  Color _iconColor(Map<String, dynamic> note) {
    switch (note["type"]) {
      case "ebook":
        return Colors.deepPurple;
      case "pdf":
        return Colors.redAccent;
      case "image":
        return Colors.green;
      case "file":
        return Colors.blueGrey;
      default:
        return Colors.indigo;
    }
  }

  Future<String> _loadNoteContent(Map<String, dynamic> note) async {

    if (note["content"] != null && note["content"].toString().isNotEmpty) {
      return note["content"];
    }

    final filePath = note["filePath"];
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (e) {
        return 'Error reading file: $e';
      }
    }

    return 'No content available';
  }

  void _open(int index) {
    final note = _notes[index];

    bool isPdfFile = false;
    bool isTextFile = false;
    final path = note["filePath"];

    if (path != null && path.isNotEmpty) {
      final extension = path.toLowerCase().split('.').last;
      isPdfFile = extension == 'pdf';
      isTextFile = extension == 'txt' || extension == 'md';
    }

    if ((note["type"] == "pdf" || note["type"] == "ebook" || isPdfFile) &&
        !isTextFile) {
      if (path == null || path.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                title: Text(
                  note["title"],
                  style: const TextStyle(color: Colors.black87),
                ),
                actions: [

                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded,
                        color: AppColors.salmon),
                    tooltip: 'Add as Doubt',
                    onPressed: () =>
                        _showAddDoubtDialog(note["title"], note["filePath"]),
                  ),
                ],
              ),
              body: GestureDetector(
                onLongPress: () =>
                    _showAddDoubtDialog(note["title"], note["filePath"]),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PdfView(
                      controller:
                          PdfController(document: PdfDocument.openFile(path)),
                      scrollDirection: Axis.vertical,
                      pageSnapping: false,
                    ),
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.question_mark_rounded),
                label: const Text('Add Doubt'),
                onPressed: () =>
                    _showAddDoubtDialog(note["title"], note["filePath"]),
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (note["type"] == "image") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                title: Text(
                  note["title"],
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              body: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(note["filePath"]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                note["title"],
                style: const TextStyle(color: Colors.black87),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black87,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded,
                      color: AppColors.salmon),
                  tooltip: 'Add as Doubt',
                  onPressed: () => _showAddDoubtDialog(note["title"], null),
                ),
              ],
            ),
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: FutureBuilder<String>(
                  future: _loadNoteContent(note),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Error loading note: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.salmon),
                      );
                    }
                    return _SelectableTextWithDoubt(
                      text: snapshot.data!,
                      noteTitle: note["title"],
                    );
                  },
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.salmon,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.sticky_note_2_rounded),
              label: const Text('Add Doubt'),
              onPressed: () => _showAddDoubtDialog(note["title"], null),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDoubtDialog(String noteTitle, String? filePath) {
    final textController =
        TextEditingController(text: 'Doubt from: $noteTitle');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.salmon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: AppColors.salmon),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Add Doubt', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your doubt about this PDF:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your doubt here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.salmonLight.withOpacity(0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (textController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your doubt')),
                );
                return;
              }

              Navigator.pop(context);

              await addDoubtFromText(textController.text.trim(), noteTitle);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Doubt added successfully!'),
                    ],
                  ),
                  backgroundColor: AppColors.mint,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DoubtsScreen()),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Doubt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salmon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _share(int index) async {
    final note = _notes[index];
    final type = note["type"];
    final title = note["title"] as String? ?? 'Shared Note';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.salmon),
      ),
    );

    try {
      QRPayload payload;

      if (type == "text") {

        final content = note["content"] as String? ?? '';
        payload = await QRShareHelper.prepareForSharing(
          title: title,
          content: content,
        );
      } else {

        final filePath = note["filePath"] as String?;
        if (filePath == null) {
          throw 'File path not found';
        }

        payload = await QRShareHelper.prepareForSharing(
          title: title,
          content: '',
          filePath: filePath,
          fileType: type,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteShareQR(
            note: payload.toJson(),
            detailedness: 1.0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _delete(int index) async {
    final notes = List<Map<String, dynamic>>.from(_notes);
    final n = notes[index];

    if (n["type"] != "text") {
      final file = File(n["filePath"]);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    notes.removeAt(index);
    await StorageService.saveNotes(notes);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const Center(child: CircularProgressIndicator());

    final notesToShow = _filteredNotes;
    final ebooks = notesToShow.where((e) => e["type"] == "ebook").toList();
    final pdfDocs = notesToShow.where((e) => e["type"] == "pdf").toList();
    final images = notesToShow.where((e) => e["type"] == "image").toList();
    final voiceNotes =
        notesToShow.where((e) => e["isVoiceNote"] == true).toList();
    final texts = notesToShow
        .where((e) => e["type"] == "text" && e["isVoiceNote"] != true)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textLightDark : Colors.black45,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                "Saved Notes",
                style: TextStyle(
                    color: isDark ? AppColors.textDarkMode : Colors.black87),
              ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textDarkMode : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredNotes = List.from(_notes);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (!_isSearching) _scanTile(isDark),

            if (_isSearching && notesToShow.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    "No notes found matching '${_searchController.text}'",
                    style: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                ),
              ),

            if (ebooks.isNotEmpty) _ebookSection(ebooks, isDark),
            if (pdfDocs.isNotEmpty)
              _section("📄 Scanned Documents", pdfDocs, isDark),
            if (images.isNotEmpty) _section("🖼️ Images", images, isDark),
            if (voiceNotes.isNotEmpty) _voiceNotesSection(voiceNotes, isDark),
            if (texts.isNotEmpty) _section("📝 Notes", texts, isDark),

            if (notesToShow.isEmpty && !_isSearching)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    "No saved notes yet.",
                    style: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scanTile(bool isDark) => Column(
        children: [

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: isDark
                ? AppColors.cardDark.withAlpha(230)
                : Colors.white.withAlpha(230),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.salmon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.document_scanner,
                  color: isDark ? AppColors.salmonDark : AppColors.salmon,
                ),
              ),
              title: Text(
                "Scan handwritten notes to PDF",
                style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                "Use camera to capture notes.",
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                ),
              ),
              onTap: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HandwrittenScanScreen()),
                );
                if (changed == true) _loadNotes();
              },
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: isDark
                ? AppColors.cardDark.withAlpha(230)
                : Colors.white.withAlpha(230),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: isDark ? AppColors.mintDark : AppColors.mint,
                ),
              ),
              title: Text(
                "Create voice note",
                style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                "Record and share voice notes offline",
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                ),
              ),
              onTap: () => _showVoiceNoteDialog(isDark),
            ),
          ),
        ],
      );

  void _showVoiceNoteDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceNoteRecorder(
        onSaved: (title, content) async {

          final notes = await StorageService.loadNotes();
          notes.add({
            "v": 1,
            "type": "text",
            "title": title,
            "content": content,
            "timestamp": DateTime.now().toIso8601String(),
            "isVoiceNote": true,
          });
          await StorageService.saveNotes(notes);
          _loadNotes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🎤 Voice note saved!'),
                backgroundColor: AppColors.mint,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _ebookSection(List<Map<String, dynamic>> list, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.deepPurple.shade800, Colors.deepPurple.shade600]
                  : [Colors.deepPurple.shade400, Colors.deepPurple.shade300],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(77),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Downloaded E-Books",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${list.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...list.asMap().entries.map((entry) {
          final idx = _notes.indexOf(entry.value);
          return _ebookTile(idx, entry.value, isDark);
        }),
      ],
    );
  }

  Widget _ebookTile(int index, Map<String, dynamic> note, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? AppColors.cardDark.withAlpha(230)
          : Colors.white.withAlpha(230),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.deepPurple.withAlpha(77),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.menu_book_rounded, color: Colors.deepPurple),
          ),
          title: Text(
            note["title"],
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatTimestamp(note["timestamp"] ?? ""),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textLightDark : Colors.black54,
            ),
          ),
          onTap: () => _open(index),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.qr_code,
                  color: isDark ? AppColors.salmonDark : AppColors.salmon,
                ),
                onPressed: () => _share(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _delete(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voiceNotesSection(List<Map<String, dynamic>> list, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.teal.withAlpha(204),
                      AppColors.mint.withAlpha(179)
                    ]
                  : [AppColors.teal, AppColors.mint],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withAlpha(77),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "🎤 Voice Notes",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${list.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...list.asMap().entries.map((entry) {
          final idx = _notes.indexOf(entry.value);
          return _voiceNoteTile(idx, entry.value, isDark);
        }),
      ],
    );
  }

  Widget _voiceNoteTile(int index, Map<String, dynamic> note, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? AppColors.cardDark.withAlpha(230)
          : Colors.white.withAlpha(230),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.mint.withAlpha(77),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mint.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.mic_rounded, color: AppColors.mint),
          ),
          title: Text(
            note["title"] ?? "Voice Note",
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTimestamp(note["timestamp"] ?? ""),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                ),
              ),
              if (note["content"] != null) ...[
                const SizedBox(height: 4),
                Text(
                  note["content"].toString().length > 80
                      ? '${note["content"].toString().substring(0, 80)}...'
                      : note["content"].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textLightDark : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          isThreeLine: note["content"] != null,
          onTap: () => _open(index),
          onLongPress: () => _markAsDoubt(note),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.salmon,
                ),
                tooltip: 'Mark as Doubt',
                onPressed: () => _markAsDoubt(note),
              ),
              IconButton(
                icon: Icon(
                  Icons.qr_code,
                  color: isDark ? AppColors.salmonDark : AppColors.salmon,
                ),
                onPressed: () => _share(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _delete(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsDoubt(Map<String, dynamic> note) async {
    final content = note["content"]?.toString() ?? "";
    final title = note["title"]?.toString() ?? "Voice Note";

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No content to mark as doubt')),
      );
      return;
    }

    await addDoubtFromText(content, title);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Added to doubts! 📌'),
          ],
        ),
        backgroundColor: AppColors.mint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoubtsScreen()),
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return "";
    try {
      final dt = DateTime.parse(timestamp);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return timestamp;
    }
  }

  Widget _section(String title, List<Map<String, dynamic>> list, bool isDark) {

    Color sectionColor;
    IconData sectionIcon;

    if (title.contains("Document")) {
      sectionColor = AppColors.salmon;
      sectionIcon = Icons.picture_as_pdf;
    } else if (title.contains("Image")) {
      sectionColor = Colors.green;
      sectionIcon = Icons.image;
    } else {
      sectionColor = Colors.indigo;
      sectionIcon = Icons.description;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      sectionColor.withAlpha(204),
                      sectionColor.withAlpha(153)
                    ]
                  : [
                      sectionColor.withAlpha(230),
                      sectionColor.withAlpha(179)
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: sectionColor.withAlpha(77),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(sectionIcon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${list.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...list.asMap().entries.map((entry) {
          final idx = _notes.indexOf(entry.value);
          return _noteTile(idx, entry.value, isDark);
        })
      ],
    );
  }

  Widget _noteTile(int index, Map<String, dynamic> note, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? AppColors.cardDark.withAlpha(230)
          : Colors.white.withAlpha(230),
      child: ListTile(
        leading: Icon(_iconFor(note), color: _iconColor(note)),
        title: Text(
          note["title"],
          style: TextStyle(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
          ),
        ),
        subtitle: Text(
          note["timestamp"] ?? "",
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textLightDark : Colors.black54,
          ),
        ),
        onTap: () => _open(index),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isDark ? AppColors.textLightDark : Colors.black54,
              ),
              onPressed: () => _rename(index),
            ),
            IconButton(
              icon: Icon(
                Icons.qr_code,
                color: isDark ? AppColors.salmonDark : AppColors.salmon,
              ),
              onPressed: () => _share(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(index),
            ),
          ],
        ),
      ),
    );
  }

  void _rename(int index) async {
    final controller =
        TextEditingController(text: _notes[index]["title"] ?? "");

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Title"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final notes = List<Map<String, dynamic>>.from(_notes);
    notes[index] = {...notes[index], "title": result};
    await StorageService.saveNotes(notes);
    _loadNotes();
  }
}

class _VoiceNoteRecorder extends StatefulWidget {
  final Function(String title, String content) onSaved;

  const _VoiceNoteRecorder({required this.onSaved});

  @override
  State<_VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<_VoiceNoteRecorder> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = '';
  bool _speechAvailable = false;
  final _titleController = TextEditingController();
  int _listeningDuration = 0;
  Timer? _listeningTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listeningTimer?.cancel();
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        _listeningTimer?.cancel();
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _listeningDuration = 0;
    });

    _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _listeningDuration++);
      }
    });

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
  }

  void _saveNote() {
    if (_spokenText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record something first')),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Voice Note ${DateTime.now().toString().substring(0, 16)}';

    widget.onSaved(title, _spokenText);
    Navigator.pop(context);
  }

  void _shareViaQR() async {
    if (_spokenText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record something first')),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Voice Note';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppColors.mint)),
    );

    try {
      final payload = await QRShareHelper.prepareForSharing(
        title: title,
        content: _spokenText,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NoteShareQR(note: payload.toJson(), detailedness: 1.0),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to prepare QR: $e')),
      );
    }
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _speech.stop();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.mint, AppColors.teal],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Note',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Hold to record, works offline',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Give your note a title',
                prefixIcon:
                    const Icon(Icons.title_rounded, color: AppColors.salmon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: AppColors.salmonLight.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {

                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              onLongPressStart: (_) => _startListening(),
              onLongPressEnd: (_) => _stopListening(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isListening ? 110 : 90,
                height: _isListening ? 110 : 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : AppColors.mint,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : AppColors.mint)
                          .withOpacity(0.4),
                      blurRadius: _isListening ? 25 : 12,
                      spreadRadius: _isListening ? 8 : 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: _isListening ? 45 : 38,
                    ),
                    if (_isListening) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_listeningDuration ~/ 60}:${(_listeningDuration % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'Tap to stop recording' : 'Tap or hold to record',
              style: TextStyle(
                color: _isListening ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            if (_spokenText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mintLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mint.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transcribed Text:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _spokenText,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareViaQR,
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('Share QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sky,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SelectableTextWithDoubt extends StatefulWidget {
  final String text;
  final String noteTitle;

  const _SelectableTextWithDoubt({
    required this.text,
    required this.noteTitle,
  });

  @override
  State<_SelectableTextWithDoubt> createState() =>
      _SelectableTextWithDoubtState();
}

class _SelectableTextWithDoubtState extends State<_SelectableTextWithDoubt> {
  String _selectedText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.salmonLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.salmon.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: AppColors.salmon, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Select text and tap button to mark as doubt',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),

        SelectableText(
          widget.text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
          onSelectionChanged: (selection, cause) {
            if (selection.start != selection.end) {
              final selected =
                  widget.text.substring(selection.start, selection.end);
              setState(() {
                _selectedText = selected;
              });
            } else {
              setState(() {
                _selectedText = '';
              });
            }
          },
        ),

        if (_selectedText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mintLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mint.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: AppColors.mint, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Selected Text:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedText.length > 100
                      ? '${_selectedText.substring(0, 100)}...'
                      : _selectedText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await addDoubtFromText(_selectedText, widget.noteTitle);
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.sticky_note_2_rounded,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(child: Text('Saved as doubt! 📌')),
                            ],
                          ),
                          backgroundColor: AppColors.mint,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          action: SnackBarAction(
                            label: 'View',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DoubtsScreen()),
                              );
                            },
                          ),
                        ),
                      );

                      setState(() {
                        _selectedText = '';
                      });
                    },
                    icon: const Icon(Icons.sticky_note_2_rounded, size: 18),
                    label: const Text('Add as Sticky Doubt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.salmon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
