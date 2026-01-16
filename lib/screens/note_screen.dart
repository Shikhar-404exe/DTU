

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../services/notes_api_service.dart';
import '../services/storage_service.dart';
import '../services/qr_share_helper.dart';
import '../models/note_organization.dart';
import 'note_share_qr.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'doubts_screen.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _form = GlobalKey<FormState>();

  final subject = TextEditingController();
  final board = TextEditingController();
  final classCtrl = TextEditingController();
  final topic = TextEditingController();
  final details = TextEditingController();

  String? lang = "English";
  double detailedness = 0.5;

  bool loading = false;
  String? outputNote;

  String _selectedClassId = 'class_10';
  String _selectedSubjectId = 'math';
  String _selectedCategoryId = 'notes';

  @override
  void initState() {
    super.initState();
    _loadUserClass();
  }

  Future<void> _loadUserClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classId = prefs.getString('profile_class_id');
      if (classId != null && mounted) {
        setState(() {
          _selectedClassId = classId;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user class: $e');
    }
  }

  @override
  void dispose() {
    subject.dispose();
    board.dispose();
    classCtrl.dispose();
    topic.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(

      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Generate Notes",
            style: TextStyle(
                color: isDark ? AppColors.textDarkMode : Colors.black87),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? AppColors.textDarkMode : Colors.black87,
          iconTheme: IconThemeData(
              color: isDark ? AppColors.textDarkMode : Colors.black87),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(topic, "Topic", isDark),
                _field(details, "Additional Detail", isDark, max: 3),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Class / Grade',
                    prefixIcon: const Icon(Icons.school),
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                  items: NoteClass.allClasses.map((cls) {
                    return DropdownMenuItem(
                      value: cls.id,
                      child: Text(cls.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book),
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                  items: Subject.allSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Row(
                        children: [
                          Text(subject.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(subject.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                  items: NoteCategory.allCategories
                      .where((cat) => cat.id != 'scanned')
                      .map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(category.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: lang,
                  decoration: InputDecoration(
                    labelText: "Language",
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                  items: [
                    "English",
                    "Hindi",
                    "Punjabi",
                    "Tamil",
                    "Telugu",
                    "Gujarati",
                    "Marathi"
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => lang = v),
                ),
                const SizedBox(height: 20),
                Text(
                  "Detailedness",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.textDarkMode : Colors.black87,
                  ),
                ),
                Slider(
                  value: detailedness,
                  divisions: 4,
                  activeColor: isDark ? AppColors.salmonDark : AppColors.salmon,
                  inactiveColor: isDark
                      ? AppColors.salmonDark.withAlpha(77)
                      : AppColors.salmon.withAlpha(77),
                  onChanged: (v) => setState(() => detailedness = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _generate,
                    icon: const Icon(Icons.auto_stories),
                    label: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ))
                        : const Text("Generate Notes"),
                  ),
                ),
                if (outputNote != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    "Generated Notes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark.withAlpha(230)
                          : Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppColors.salmon)
                              .withAlpha(38),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SelectableText(
                      outputNote!,
                      style: TextStyle(
                        color: isDark ? AppColors.textDarkMode : Colors.black87,
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                      contextMenuBuilder: (context, editableTextState) {
                        final selection =
                            editableTextState.textEditingValue.selection;
                        final selectedText =
                            selection.isValid && !selection.isCollapsed
                                ? editableTextState.textEditingValue.text
                                    .substring(selection.start, selection.end)
                                : '';

                        return AdaptiveTextSelectionToolbar(
                          anchors: editableTextState.contextMenuAnchors,
                          children: [

                            TextSelectionToolbarTextButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                if (selectedText.isNotEmpty) {
                                  Clipboard.setData(
                                      ClipboardData(text: selectedText));
                                  editableTextState.hideToolbar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied to clipboard')),
                                  );
                                }
                              },
                              child: const Text('Copy'),
                            ),

                            TextSelectionToolbarTextButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                editableTextState
                                    .selectAll(SelectionChangedCause.toolbar);
                              },
                              child: const Text('Select All'),
                            ),

                            TextSelectionToolbarTextButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () async {
                                if (selectedText.isNotEmpty) {
                                  final noteTitle = topic.text.isNotEmpty
                                      ? topic.text
                                      : 'Generated Note';
                                  await addDoubtFromText(
                                      selectedText, noteTitle);
                                  editableTextState.hideToolbar();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            const Text('📌 Marked as doubt!'),
                                        backgroundColor: AppColors.salmon,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Select text to mark as doubt')),
                                  );
                                }
                              },
                              child: const Text('📌 Mark'),
                            ),

                            TextSelectionToolbarTextButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                editableTextState.hideToolbar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Opening AI assistant...')),
                                );
                              },
                              child: const Text('Ask AI'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : _save,
                          icon: const Icon(Icons.save),
                          label: const Text("Save"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final noteToShare = outputNote!;

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.salmon),
                              ),
                            );

                            try {

                              final payload =
                                  await QRShareHelper.prepareForSharing(
                                title: '${subject.text} - ${topic.text}',
                                content: noteToShare,
                              );

                              if (!mounted) return;
                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteShareQR(
                                    note: payload.toJson(),
                                    detailedness: detailedness,
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to prepare QR: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Share QR"),
                        ),
                      ),
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, bool isDark,
      {int max = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: max,
        style: TextStyle(
          color: isDark ? AppColors.textDarkMode : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? AppColors.textLightDark : Colors.black54,
          ),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Future<void> _generate() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      loading = true;
      outputNote = null;
    });

    try {

      final className =
          NoteClass.allClasses.firstWhere((c) => c.id == _selectedClassId).name;
      final subjectName = Subject.allSubjects
          .firstWhere((s) => s.id == _selectedSubjectId)
          .name;
      final categoryName = NoteCategory.allCategories
          .firstWhere((c) => c.id == _selectedCategoryId)
          .name;

      final detailLevel = detailedness < 0.3
          ? 'brief'
          : detailedness < 0.7
              ? 'detailed'
              : 'comprehensive';

      final enhancedPrompt = '''
Generate $detailLevel educational content for:

Class/Grade: $className
Subject: $subjectName
Category: $categoryName
Topic: ${topic.text.trim()}
${details.text.isNotEmpty ? 'Additional Context: ${details.text.trim()}' : ''}

Language: $lang

Please provide comprehensive notes suitable for $className students studying $subjectName.
Format with clear headings, bullet points, examples, and summary.
''';

      final r = await NotesApiService.generateNote({
        "subject": subjectName,
        "board": "",
        "class": className,
        "topic": topic.text,
        "details": details.text.isNotEmpty ? details.text : enhancedPrompt,
        "language": lang,
        "detailedness": detailedness,
      });

      if (!mounted) return;
      setState(() => outputNote = r["note"] as String? ?? "");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (outputNote == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file =
          File("${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.txt");
      await file.writeAsString(outputNote!);

      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('organized_notes') ?? '[]';
      final notesList =
          (jsonDecode(notesJson) as List).cast<Map<String, dynamic>>();

      final newNote = OrganizedNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: topic.text.trim().isNotEmpty ? topic.text.trim() : 'Note',
        content: outputNote!,
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
        categoryId: _selectedCategoryId,
        createdAt: DateTime.now(),
        filePath: file.path,
        type: 'text',
      );

      notesList.add(newNote.toJson());
      await prefs.setString('organized_notes', jsonEncode(notesList));

      final notes = await StorageService.loadNotes();
      notes.add({
        "v": 1,
        "type": "text",
        "title": topic.text.trim().isNotEmpty ? topic.text.trim() : 'Note',
        "content": outputNote!,
        "timestamp": DateTime.now().toIso8601String(),
        "filePath": file.path,
      });
      await StorageService.saveNotes(notes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not save note: $e")),
      );
    }
  }
}
