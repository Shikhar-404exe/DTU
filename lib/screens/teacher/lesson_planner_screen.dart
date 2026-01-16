/// Lesson Planner Screen - Teacher Dashboard
/// Create and manage lesson plans with optional AI summaries

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../services/gemini_service.dart';
import '../../models/teacher_models.dart';

class LessonPlannerScreen extends StatefulWidget {
  const LessonPlannerScreen({super.key});

  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen> {
  List<LessonPlan> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await TeacherDataService.getLessonPlans();
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addLesson() async {
    final classes = await TeacherDataService.getClasses();
    if (classes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a class first')),
        );
      }
      return;
    }

    if (mounted) {
      final result = await Navigator.push<LessonPlan>(
        context,
        MaterialPageRoute(
          builder: (_) => _LessonEditorScreen(classes: classes),
        ),
      );

      if (result != null) {
        _lessons.add(result);
        await TeacherDataService.saveLessonPlans(_lessons);
        _loadLessons();
      }
    }
  }

  void _editLesson(int index) async {
    final classes = await TeacherDataService.getClasses();
    if (mounted) {
      final result = await Navigator.push<LessonPlan>(
        context,
        MaterialPageRoute(
          builder: (_) => _LessonEditorScreen(
            lesson: _lessons[index],
            classes: classes,
          ),
        ),
      );

      if (result != null) {
        _lessons[index] = result;
        await TeacherDataService.saveLessonPlans(_lessons);
        _loadLessons();
      }
    }
  }

  void _deleteLesson(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Remove "${_lessons[index].topic}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _lessons.removeAt(index);
      await TeacherDataService.saveLessonPlans(_lessons);
      _loadLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Lesson Plans',
          style: TextStyle(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? Center(
                  child: Text(
                    'No lesson plans yet',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textLightDark
                          : AppColors.textLight,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    return Card(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? AppColors.lavenderDark
                              : AppColors.lavender,
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(
                          lesson.topic,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textDarkMode
                                : AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${lesson.subject} - ${lesson.date}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textLightDark
                                : AppColors.textLight,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editLesson(index);
                            } else if (value == 'delete') {
                              _deleteLesson(index);
                            }
                          },
                        ),
                        onTap: () => _editLesson(index),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLesson,
        backgroundColor: isDark ? AppColors.lavenderDark : AppColors.lavender,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonEditorScreen extends StatefulWidget {
  final LessonPlan? lesson;
  final List<ClassSection> classes;

  const _LessonEditorScreen({this.lesson, required this.classes});

  @override
  State<_LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<_LessonEditorScreen> {
  late final TextEditingController _topicController;
  late final TextEditingController _subjectController;
  late final TextEditingController _notesController;
  late String _selectedClassId;
  late String _selectedDate;
  bool _generatingSummary = false;
  String _aiSummary = '';

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.lesson?.topic ?? '');
    _subjectController =
        TextEditingController(text: widget.lesson?.subject ?? '');
    _notesController = TextEditingController(text: widget.lesson?.notes ?? '');
    _selectedClassId = widget.lesson?.classId ??
        (widget.classes.isNotEmpty ? widget.classes.first.id : '');
    _selectedDate =
        widget.lesson?.date ?? DateTime.now().toIso8601String().split('T')[0];
    _aiSummary = widget.lesson?.aiSummary ?? '';
  }

  @override
  void dispose() {
    _topicController.dispose();
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add notes first')),
      );
      return;
    }

    setState(() => _generatingSummary = true);

    try {
      final result = await GeminiService.summarizeText(
        text: _notesController.text,
      ).timeout(const Duration(seconds: 30));

      if (mounted) {
        if (result.success && result.content != null) {
          setState(() {
            _aiSummary = result.content!;
            _generatingSummary = false;
          });
        } else {
          setState(() => _generatingSummary = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.error ?? 'Failed to generate summary')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating summary: $e');
      if (mounted) {
        setState(() => _generatingSummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _save() {
    if (_topicController.text.isEmpty || _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic and Subject are required')),
      );
      return;
    }

    final lesson = LessonPlan(
      id: widget.lesson?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      classId: _selectedClassId,
      subject: _subjectController.text,
      topic: _topicController.text,
      date: _selectedDate,
      notes: _notesController.text,
      aiSummary: _aiSummary.isNotEmpty ? _aiSummary : null,
    );

    Navigator.pop(context, lesson);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.lesson == null ? 'New Lesson' : 'Edit Lesson',
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.save,
                  color: isDark ? AppColors.textDarkMode : Colors.black87),
              onPressed: _save,
              tooltip: 'Save',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                items: widget.classes.map((cls) {
                  return DropdownMenuItem(
                    value: cls.id,
                    child: Text('${cls.grade} ${cls.section}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedClassId = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: isDark
                              ? AppColors.lavenderDark
                              : AppColors.lavender),
                      const SizedBox(width: 12),
                      Text(_selectedDate,
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generatingSummary ? null : _generateSummary,
                icon: _generatingSummary
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_generatingSummary
                    ? 'Generating...'
                    : 'Generate AI Summary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.lavenderDark : AppColors.lavender,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_aiSummary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 20,
                              color: isDark
                                  ? AppColors.lavenderDark
                                  : AppColors.lavender),
                          const SizedBox(width: 8),
                          Text('AI Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textDarkMode
                                      : AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_aiSummary,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textLightDark
                                  : AppColors.textLight)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
