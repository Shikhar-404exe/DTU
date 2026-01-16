import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/note_organization.dart';
import '../services/qr_share_helper.dart';
import 'note_view_screen.dart';
import 'note_share_qr.dart';
import 'handwritten_scan_screen.dart';
import 'package:pdfx/pdfx.dart';

class SavedNotesOrganizedScreen extends StatefulWidget {
  const SavedNotesOrganizedScreen({super.key});

  @override
  State<SavedNotesOrganizedScreen> createState() =>
      _SavedNotesOrganizedScreenState();
}

class _SavedNotesOrganizedScreenState extends State<SavedNotesOrganizedScreen> {
  List<OrganizedNote> _allNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('organized_notes') ?? '[]';
      final notesList =
          (jsonDecode(notesJson) as List).cast<Map<String, dynamic>>();

      setState(() {
        _allNotes =
            notesList.map((json) => OrganizedNote.fromJson(json)).toList();
        _allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _renameNote(OrganizedNote note) async {
    final controller = TextEditingController(text: note.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Note Title',
            hintText: 'Enter new title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('organized_notes');
      if (notesJson == null) return;

      final List<dynamic> notesList = json.decode(notesJson);
      final index = notesList.indexWhere((n) => n['id'] == note.id);
      if (index != -1) {
        notesList[index]['title'] = result;
        await prefs.setString('organized_notes', json.encode(notesList));

        if (mounted) {
          _loadNotes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note renamed successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to rename note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rename note')),
        );
      }
    }
  }

  Future<void> _shareNote(OrganizedNote note) async {
    final title = note.title;
    final type = note.type;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.salmon),
      ),
    );

    try {
      QRPayload payload;

      final filePath = note.filePath;
      if (filePath != null && filePath.isNotEmpty) {

        payload = await QRShareHelper.prepareForSharing(
          title: title,
          content: '',
          filePath: filePath,
          fileType: type,
          classId: note.classId,
          subjectId: note.subjectId,
          categoryId: note.categoryId,
        );
      } else {

        payload = await QRShareHelper.prepareForSharing(
          title: title,
          content: note.content,
          classId: note.classId,
          subjectId: note.subjectId,
          categoryId: note.categoryId,
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

  Map<String, Map<String, Map<String, List<OrganizedNote>>>> _organizeNotes() {
    final organized = <String, Map<String, Map<String, List<OrganizedNote>>>>{};

    for (final note in _allNotes) {
      if (_searchQuery.isNotEmpty &&
          !note.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }

      organized.putIfAbsent(note.classId, () => {});
      organized[note.classId]!.putIfAbsent(note.subjectId, () => {});
      organized[note.classId]![note.subjectId]!
          .putIfAbsent(note.categoryId, () => []);
      organized[note.classId]![note.subjectId]![note.categoryId]!.add(note);
    }

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('My Notes'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: const Center(
              child: CircularProgressIndicator(color: AppColors.salmon)),
        ),
      );
    }

    final organized = _organizeNotes();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Notes'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark ? AppColors.textDarkMode : Colors.black87,
          iconTheme: IconThemeData(
              color: isDark ? AppColors.textDarkMode : Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotes,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildScanTile(isDark),
            const SizedBox(height: 8),
            if (organized.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No notes yet\nGenerate your first note!'
                            : 'No notes found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textLightDark
                                : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...organized.keys.map((classId) {
                final className = NoteClass.allClasses
                    .firstWhere((c) => c.id == classId)
                    .name;
                final subjects = organized[classId]!;

                return _ClassSection(
                  className: className,
                  subjects: subjects,
                  onNoteTap: _openNote,
                  onNoteDelete: _deleteNote,
                  onNoteRename: _renameNote,
                  onNoteShare: _shareNote,
                  isDark: isDark,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTile(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: isDark
          ? AppColors.cardDark.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.9),
      elevation: 4,
      child: ListTile(
        leading: Icon(
          Icons.document_scanner,
          color: isDark ? AppColors.salmonDark : const Color(0xFFFFB4A2),
          size: 28,
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
            MaterialPageRoute(builder: (_) => const HandwrittenScanScreen()),
          );
          if (changed == true) _loadNotes();
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter note title...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _openNote(OrganizedNote note) {

    bool isPdfFile = false;
    bool isTextFile = false;

    if (note.filePath != null && note.filePath!.isNotEmpty) {
      final extension = note.filePath!.toLowerCase().split('.').last;
      isPdfFile = extension == 'pdf';
      isTextFile = extension == 'txt' || extension == 'md';
    }

    if ((isPdfFile || note.type == 'pdf') &&
        note.filePath != null &&
        !isTextFile) {

      final path = note.filePath!;
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
                  note.title,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              body: FutureBuilder<PdfDocument>(
                future: PdfDocument.openFile(path),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.salmon),
                    );
                  }
                  final doc = snapshot.data!;
                  return PdfView(
                      controller: PdfController(document: Future.value(doc)));
                },
              ),
            ),
          ),
        ),
      );
    } else if ((isTextFile || note.type == 'text') &&
        note.filePath != null &&
        note.filePath!.isNotEmpty) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GradientBackground(
            child: NoteViewScreen(
              filePath: note.filePath!,
            ),
          ),
        ),
      );
    } else if (note.filePath != null && note.filePath!.isNotEmpty) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GradientBackground(
            child: NoteViewScreen(
              filePath: note.filePath!,
            ),
          ),
        ),
      );
    } else {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(note.title),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
              ),
              body: Container(
                color: const Color(0xFFFFDAD0),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 17,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteNote(OrganizedNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Delete "${note.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {

      if (note.filePath != null) {
        try {
          final file = File(note.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _allNotes.removeWhere((n) => n.id == note.id);
      await prefs.setString('organized_notes',
          jsonEncode(_allNotes.map((n) => n.toJson()).toList()));
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }
}

class _ClassSection extends StatefulWidget {
  final String className;
  final Map<String, Map<String, List<OrganizedNote>>> subjects;
  final Function(OrganizedNote) onNoteTap;
  final Function(OrganizedNote) onNoteDelete;
  final Function(OrganizedNote) onNoteRename;
  final Function(OrganizedNote) onNoteShare;
  final bool isDark;

  const _ClassSection({
    required this.className,
    required this.subjects,
    required this.onNoteTap,
    required this.onNoteDelete,
    required this.onNoteRename,
    required this.onNoteShare,
    required this.isDark,
  });

  @override
  State<_ClassSection> createState() => _ClassSectionState();
}

class _ClassSectionState extends State<_ClassSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final totalNotes = widget.subjects.values.fold<int>(
        0,
        (sum, categories) =>
            sum +
            categories.values.fold<int>(0, (s, notes) => s + notes.length));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: widget.isDark
          ? AppColors.cardDark.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.school, color: Colors.blue, size: 28),
            title: Text(
              widget.className,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? AppColors.textDarkMode : Colors.black87,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalNotes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            ...widget.subjects.entries.map((subjectEntry) {
              final subjectId = subjectEntry.key;
              final subject =
                  Subject.allSubjects.firstWhere((s) => s.id == subjectId);
              final categories = subjectEntry.value;

              return _SubjectSection(
                subject: subject,
                categories: categories,
                onNoteTap: widget.onNoteTap,
                onNoteDelete: widget.onNoteDelete,
                onNoteRename: widget.onNoteRename,
                onNoteShare: widget.onNoteShare,
                isDark: widget.isDark,
              );
            }),
        ],
      ),
    );
  }
}

class _SubjectSection extends StatefulWidget {
  final Subject subject;
  final Map<String, List<OrganizedNote>> categories;
  final Function(OrganizedNote) onNoteTap;
  final Function(OrganizedNote) onNoteDelete;
  final Function(OrganizedNote) onNoteRename;
  final Function(OrganizedNote) onNoteShare;
  final bool isDark;

  const _SubjectSection({
    required this.subject,
    required this.categories,
    required this.onNoteTap,
    required this.onNoteDelete,
    required this.onNoteRename,
    required this.onNoteShare,
    required this.isDark,
  });

  @override
  State<_SubjectSection> createState() => _SubjectSectionState();
}

class _SubjectSectionState extends State<_SubjectSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totalNotes = widget.categories.values
        .fold<int>(0, (sum, notes) => sum + notes.length);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 48, right: 16),
          leading:
              Text(widget.subject.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(
            widget.subject.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? AppColors.textDarkMode : Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.salmon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalNotes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
        ),
        if (_expanded)
          ...widget.categories.entries.map((categoryEntry) {
            final categoryId = categoryEntry.key;
            final category = NoteCategory.allCategories
                .firstWhere((c) => c.id == categoryId);
            final notes = categoryEntry.value;

            return _CategorySection(
              category: category,
              notes: notes,
              onNoteTap: widget.onNoteTap,
              onNoteDelete: widget.onNoteDelete,
              onNoteRename: widget.onNoteRename,
              onNoteShare: widget.onNoteShare,
              isDark: widget.isDark,
            );
          }),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final NoteCategory category;
  final List<OrganizedNote> notes;
  final Function(OrganizedNote) onNoteTap;
  final Function(OrganizedNote) onNoteDelete;
  final Function(OrganizedNote) onNoteRename;
  final Function(OrganizedNote) onNoteShare;
  final bool isDark;

  const _CategorySection({
    required this.category,
    required this.notes,
    required this.onNoteTap,
    required this.onNoteDelete,
    required this.onNoteRename,
    required this.onNoteShare,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...notes.map((note) => Card(
                margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                color: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.5)
                    : Colors.white,
                child: ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Icon(
                    note.type == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.description,
                    color: note.type == 'pdf' ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                  title: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year} at ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textLightDark
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => onNoteRename(note),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.qr_code,
                          size: 18,
                          color:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => onNoteShare(note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => onNoteDelete(note),
                      ),
                    ],
                  ),
                  onTap: () => onNoteTap(note),
                ),
              )),
        ],
      ),
    );
  }
}
