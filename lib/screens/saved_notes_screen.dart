// lib/screens/saved_notes_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../main.dart';
import '../services/storage_service.dart';
import '../services/qr_share_helper.dart';
import 'handwritten_scan_screen.dart';
import 'note_share_qr.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await StorageService.loadNotes();
      notes.sort(
          (a, b) => (b["timestamp"] ?? "").compareTo(a["timestamp"] ?? ""));
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notes = [];
        _loading = false;
      });
    }
  }

  // ICON
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

  // Load note content from content field or file
  Future<String> _loadNoteContent(Map<String, dynamic> note) async {
    // First try to get content from note data
    if (note["content"] != null && note["content"].toString().isNotEmpty) {
      return note["content"];
    }

    // If no content, try to read from file
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

  //-------------------- OPEN NOTE ---------------------
  void _open(int index) {
    final note = _notes[index];

    // Determine actual file type from extension if filePath exists
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
              ),
              body: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38), // ~0.15 opacity
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
                      color: Colors.black.withAlpha(38), // ~0.15 opacity
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

    // TEXT NOTE
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
            ),
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230), // ~0.9 opacity
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26), // ~0.1 opacity
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
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //-------------------- SHARE ---------------------
  void _share(int index) async {
    final note = _notes[index];
    final type = note["type"];
    final title = note["title"] as String? ?? 'Shared Note';

    // Show loading
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
        // Text note - use QRShareHelper with compression
        final content = note["content"] as String? ?? '';
        payload = await QRShareHelper.prepareForSharing(
          title: title,
          content: content,
        );
      } else {
        // File note (PDF/image) - use QRShareHelper with smart compression/P2P
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
      Navigator.pop(context); // Close loading

      // Navigate to QR share screen
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
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //-------------------- DELETE ---------------------
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

  //-----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const Center(child: CircularProgressIndicator());

    final ebooks = _notes.where((e) => e["type"] == "ebook").toList();
    final pdfDocs = _notes.where((e) => e["type"] == "pdf").toList();
    final images = _notes.where((e) => e["type"] == "image").toList();
    final texts = _notes.where((e) => e["type"] == "text").toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Saved Notes",
          style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textDarkMode : Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _scanTile(isDark),

            // E-Books section with distinct header
            if (ebooks.isNotEmpty) _ebookSection(ebooks, isDark),
            if (pdfDocs.isNotEmpty)
              _section("📄 Scanned Documents", pdfDocs, isDark),
            if (images.isNotEmpty) _section("🖼️ Images", images, isDark),
            if (texts.isNotEmpty) _section("📝 Notes", texts, isDark),

            if (_notes.isEmpty)
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

  //------------------ UI HELPERS ---------------------

  Widget _scanTile(bool isDark) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark
            ? AppColors.cardDark.withAlpha(230) // ~0.9 opacity
            : Colors.white.withAlpha(230),
        child: ListTile(
          leading: Icon(
            Icons.document_scanner,
            color: isDark ? AppColors.salmonDark : const Color(0xFFFFB4A2),
          ),
          title: Text(
            "Scan handwritten notes to PDF",
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
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
              MaterialPageRoute(builder: (_) => const HandwrittenScanScreen()),
            );
            if (changed == true) _loadNotes();
          },
        ),
      );

  /// Special E-Books section with distinct purple styling
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
                color: Colors.deepPurple.withAlpha(77), // ~0.3 opacity
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
                  color: Colors.white.withAlpha(51), // ~0.2 opacity
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

  /// E-Book tile with purple accent
  Widget _ebookTile(int index, Map<String, dynamic> note, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark
          ? AppColors.cardDark.withAlpha(230) // ~0.9 opacity
          : Colors.white.withAlpha(230),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.deepPurple.withAlpha(77), // ~0.3 opacity
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(26), // ~0.1 opacity
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
    // Determine section color based on title
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
                    ] // ~0.8, ~0.6 opacity
                  : [
                      sectionColor.withAlpha(230),
                      sectionColor.withAlpha(179)
                    ], // ~0.9, ~0.7 opacity
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: sectionColor.withAlpha(77), // ~0.3 opacity
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
                  color: Colors.white.withAlpha(51), // ~0.2 opacity
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
          ? AppColors.cardDark.withAlpha(230) // ~0.9 opacity
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
