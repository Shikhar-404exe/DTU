// filepath: lib/screens/teacher/student_management_screen.dart
/// Student Management - Add, edit, view students

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<StudentRecord> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await TeacherDataService.getStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addStudent() async {
    final classes = await TeacherDataService.getClasses();
    if (classes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'create_class_first'))),
        );
      }
      return;
    }

    if (mounted) {
      final result = await showDialog<StudentRecord>(
        context: context,
        builder: (context) => _StudentDialog(classes: classes),
      );

      if (result != null) {
        _students.add(result);
        await TeacherDataService.saveStudents(_students);

        // Add student ID to class's studentIds array
        final classIndex = classes.indexWhere((c) => c.id == result.classId);
        if (classIndex >= 0) {
          final updatedClass = classes[classIndex];
          if (!updatedClass.studentIds.contains(result.id)) {
            classes[classIndex] = ClassSection(
              id: updatedClass.id,
              name: updatedClass.name,
              grade: updatedClass.grade,
              section: updatedClass.section,
              studentIds: [...updatedClass.studentIds, result.id],
            );
            await TeacherDataService.saveClasses(classes);
          }
        }

        _loadStudents();
      }
    }
  }

  void _editStudent(int index) async {
    final classes = await TeacherDataService.getClasses();
    final oldStudent = _students[index];

    if (mounted) {
      final result = await showDialog<StudentRecord>(
        context: context,
        builder: (context) => _StudentDialog(
          student: _students[index],
          classes: classes,
        ),
      );

      if (result != null) {
        _students[index] = result;
        await TeacherDataService.saveStudents(_students);

        // If class changed, update studentIds in both old and new classes
        if (oldStudent.classId != result.classId) {
          // Remove from old class
          final oldClassIndex =
              classes.indexWhere((c) => c.id == oldStudent.classId);
          if (oldClassIndex >= 0) {
            final oldClass = classes[oldClassIndex];
            classes[oldClassIndex] = ClassSection(
              id: oldClass.id,
              name: oldClass.name,
              grade: oldClass.grade,
              section: oldClass.section,
              studentIds:
                  oldClass.studentIds.where((id) => id != result.id).toList(),
            );
          }

          // Add to new class
          final newClassIndex =
              classes.indexWhere((c) => c.id == result.classId);
          if (newClassIndex >= 0) {
            final newClass = classes[newClassIndex];
            if (!newClass.studentIds.contains(result.id)) {
              classes[newClassIndex] = ClassSection(
                id: newClass.id,
                name: newClass.name,
                grade: newClass.grade,
                section: newClass.section,
                studentIds: [...newClass.studentIds, result.id],
              );
            }
          }

          await TeacherDataService.saveClasses(classes);
        }

        _loadStudents();
      }
    }
  }

  void _deleteStudent(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'delete_student')),
        content: Text('${t(context, 'remove')} ${_students[index].name}?'),
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
      final student = _students[index];
      _students.removeAt(index);
      await TeacherDataService.saveStudents(_students);

      // Remove student ID from class's studentIds array
      final classes = await TeacherDataService.getClasses();
      final classIndex = classes.indexWhere((c) => c.id == student.classId);
      if (classIndex >= 0) {
        final classSection = classes[classIndex];
        classes[classIndex] = ClassSection(
          id: classSection.id,
          name: classSection.name,
          grade: classSection.grade,
          section: classSection.section,
          studentIds:
              classSection.studentIds.where((id) => id != student.id).toList(),
        );
        await TeacherDataService.saveClasses(classes);
      }

      _loadStudents();
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
            t(context, 'students'),
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
            : _students.isEmpty
                ? Center(
                    child: Text(
                      t(context, 'no_students_yet'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textLightDark
                            : AppColors.textLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return Card(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark
                                ? AppColors.salmonDark
                                : AppColors.salmon,
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${t(context, 'roll')}: ${student.rollNumber}',
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
                                _editStudent(index);
                              } else if (value == 'delete') {
                                _deleteStudent(index);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addStudent,
          backgroundColor: isDark ? AppColors.salmonDark : AppColors.salmon,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _StudentDialog extends StatefulWidget {
  final StudentRecord? student;
  final List<ClassSection> classes;

  const _StudentDialog({this.student, required this.classes});

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _rollController;
  late String _selectedClassId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _rollController =
        TextEditingController(text: widget.student?.rollNumber ?? '');
    _selectedClassId = widget.student?.classId ??
        (widget.classes.isNotEmpty ? widget.classes.first.id : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty || _rollController.text.isEmpty) {
      return;
    }

    final student = StudentRecord(
      id: widget.student?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      rollNumber: _rollController.text,
      classId: _selectedClassId,
      marks: widget.student?.marks ?? {},
      attendanceDates: widget.student?.attendanceDates ?? [],
    );

    Navigator.pop(context, student);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rollController,
            decoration: const InputDecoration(labelText: 'Roll Number'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            decoration: const InputDecoration(labelText: 'Class'),
            items: widget.classes.map((cls) {
              return DropdownMenuItem(
                value: cls.id,
                child: Text('${cls.grade} ${cls.section}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedClassId = value;
                });
              }
            },
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
