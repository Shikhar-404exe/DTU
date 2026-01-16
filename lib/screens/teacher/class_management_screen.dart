// filepath: lib/screens/teacher/class_management_screen.dart
/// Class Management - Create and organize class sections

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  List<ClassSection> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await TeacherDataService.getClasses();
      if (mounted) {
        setState(() {
          _classes = classes;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addClass() async {
    final result = await showDialog<ClassSection>(
      context: context,
      builder: (context) => const _ClassDialog(),
    );

    if (result != null) {
      _classes.add(result);
      await TeacherDataService.saveClasses(_classes);
      _loadClasses();
    }
  }

  void _editClass(int index) async {
    final result = await showDialog<ClassSection>(
      context: context,
      builder: (context) => _ClassDialog(classSection: _classes[index]),
    );

    if (result != null) {
      _classes[index] = result;
      await TeacherDataService.saveClasses(_classes);
      _loadClasses();
    }
  }

  void _deleteClass(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'delete_class')),
        content: Text(
            '${t(context, 'remove')} ${_classes[index].grade} ${_classes[index].section}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _classes.removeAt(index);
      await TeacherDataService.saveClasses(_classes);
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            t(context, 'classes'),
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
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _classes.isEmpty
                ? Center(
                    child: Text(
                      t(context, 'no_classes_yet'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textLightDark
                            : AppColors.textLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final classSection = _classes[index];
                      return Card(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isDark ? AppColors.mintDark : AppColors.mint,
                            child: Text(
                              classSection.grade[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${classSection.grade} ${classSection.section}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${classSection.studentIds.length} students',
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
                                _editClass(index);
                              } else if (value == 'delete') {
                                _deleteClass(index);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addClass,
          backgroundColor: isDark ? AppColors.mintDark : AppColors.mint,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ClassDialog extends StatefulWidget {
  final ClassSection? classSection;

  const _ClassDialog({this.classSection});

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late final TextEditingController _gradeController;
  late final TextEditingController _sectionController;

  @override
  void initState() {
    super.initState();
    _gradeController =
        TextEditingController(text: widget.classSection?.grade ?? '');
    _sectionController =
        TextEditingController(text: widget.classSection?.section ?? '');
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_gradeController.text.isEmpty || _sectionController.text.isEmpty) {
      return;
    }

    final grade = _gradeController.text;
    final section = _sectionController.text;

    final classSection = ClassSection(
      id: widget.classSection?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Class $grade-$section',
      grade: grade,
      section: section,
      studentIds: widget.classSection?.studentIds ?? [],
    );

    Navigator.pop(context, classSection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classSection == null ? 'Add Class' : 'Edit Class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _gradeController,
            decoration: const InputDecoration(
              labelText: 'Grade',
              hintText: 'e.g., 10',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sectionController,
            decoration: const InputDecoration(
              labelText: 'Section',
              hintText: 'e.g., A',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
