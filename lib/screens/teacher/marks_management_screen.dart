/// Marks Management Screen - Add and manage student marks for different subjects

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';

class MarksManagementScreen extends StatefulWidget {
  const MarksManagementScreen({super.key});

  @override
  State<MarksManagementScreen> createState() => _MarksManagementScreenState();
}

class _MarksManagementScreenState extends State<MarksManagementScreen> {
  List<ClassSection> _classes = [];
  List<StudentRecord> _students = [];
  List<StudentRecord> _filteredStudents = [];
  ClassSection? _selectedClass;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classes = await TeacherDataService.getClasses();
      final students = await TeacherDataService.getStudents();

      if (mounted) {
        setState(() {
          _classes = classes;
          _students = students;
          _loading = false;
          if (_classes.isNotEmpty) {
            _selectedClass = _classes.first;
            _filterStudents();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterStudents() {
    if (_selectedClass == null) {
      _filteredStudents = [];
      return;
    }

    _filteredStudents =
        _students.where((s) => s.classId == _selectedClass!.id).toList();
    setState(() {});
  }

  Future<void> _editMarks(StudentRecord student) async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => _MarksEditorDialog(
        studentName: student.name,
        currentMarks: student.marks,
      ),
    );

    if (result != null) {
      // Update student marks
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index >= 0) {
        _students[index] = student.copyWith(marks: result);
        await TeacherDataService.saveStudents(_students);
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Marks Management',
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
          : _classes.isEmpty
              ? Center(
                  child: Text(
                    'No classes created yet',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textLightDark
                          : AppColors.textLight,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Class Selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ClassSection>(
                            value: _selectedClass,
                            isExpanded: true,
                            items: _classes.map((cls) {
                              return DropdownMenuItem(
                                value: cls,
                                child: Text('${cls.grade} ${cls.section}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClass = value;
                                _filterStudents();
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Student List with Marks
                    Expanded(
                      child: _filteredStudents.isEmpty
                          ? Center(
                              child: Text(
                                'No students in this class',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textLightDark
                                      : AppColors.textLight,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final totalMarks = student.marks.values.isEmpty
                                    ? 0.0
                                    : student.marks.values
                                        .reduce((a, b) => a + b);
                                final subjectCount = student.marks.length;
                                final avgMarks = subjectCount > 0
                                    ? totalMarks / subjectCount
                                    : 0.0;

                                return Card(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : Colors.white,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: (isDark
                                              ? AppColors.salmonDark
                                              : AppColors.salmon)
                                          .withAlpha(100),
                                      child: Text(
                                        student.name
                                            .split(' ')
                                            .map((e) => e[0])
                                            .take(2)
                                            .join()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.salmonDark
                                              : AppColors.salmon,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Roll: ${student.rollNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textLightDark
                                                : AppColors.textLight,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _ScoreBadge(
                                              label: 'Subjects',
                                              value: subjectCount.toString(),
                                              color: isDark
                                                  ? AppColors.mintDark
                                                  : AppColors.mint,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(width: 8),
                                            _ScoreBadge(
                                              label: 'Avg',
                                              value:
                                                  avgMarks.toStringAsFixed(1),
                                              color: isDark
                                                  ? AppColors.lavenderDark
                                                  : AppColors.lavender,
                                              isDark: isDark,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: isDark
                                            ? AppColors.salmonDark
                                            : AppColors.salmon,
                                      ),
                                      onPressed: () => _editMarks(student),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _ScoreBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDarkMode : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksEditorDialog extends StatefulWidget {
  final String studentName;
  final Map<String, double> currentMarks;

  const _MarksEditorDialog({
    required this.studentName,
    required this.currentMarks,
  });

  @override
  State<_MarksEditorDialog> createState() => _MarksEditorDialogState();
}

class _MarksEditorDialogState extends State<_MarksEditorDialog> {
  late Map<String, TextEditingController> _controllers;
  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'Social Studies',
    'Hindi',
    'Computer Science',
    'Physical Education',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final subject in _subjects) {
      _controllers[subject] = TextEditingController(
        text: widget.currentMarks[subject]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final marks = <String, double>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        final mark = double.tryParse(value);
        if (mark != null && mark >= 0 && mark <= 100) {
          marks[entry.key] = mark;
        }
      }
    }
    Navigator.pop(context, marks);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      title: Text(
        'Edit Marks - ${widget.studentName}',
        style: TextStyle(
          color: isDark ? AppColors.textDarkMode : AppColors.textDark,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final subject = _subjects[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[subject],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  labelText: subject,
                  labelStyle: TextStyle(
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                  hintText: 'Enter marks (0-100)',
                  hintStyle: TextStyle(
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.salmonDark : AppColors.salmon,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
