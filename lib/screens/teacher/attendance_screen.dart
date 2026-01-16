
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<ClassSection> _classes = [];
  List<StudentRecord> _students = [];
  ClassSection? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  final Map<String, bool> _attendance = {};

  DateTime? _attendanceStartDate;
  DateTime? _attendanceEndDate;
  Set<int> _workingDays = {1, 2, 3, 4, 5};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAttendanceConfig();
  }

  Future<void> _loadAttendanceConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startStr = prefs.getString('attendance_start_date');
      final endStr = prefs.getString('attendance_end_date');
      final workingDaysStr = prefs.getString('working_days') ?? '1,2,3,4,5';

      if (mounted) {
        setState(() {
          if (startStr != null) {
            _attendanceStartDate = DateTime.parse(startStr);
          }
          if (endStr != null) {
            _attendanceEndDate = DateTime.parse(endStr);
          }
          _workingDays =
              workingDaysStr.split(',').map((e) => int.parse(e)).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance config: $e');
    }
  }

  Future<void> _saveAttendanceConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_attendanceStartDate != null) {
        await prefs.setString(
            'attendance_start_date', _attendanceStartDate!.toIso8601String());
      }
      if (_attendanceEndDate != null) {
        await prefs.setString(
            'attendance_end_date', _attendanceEndDate!.toIso8601String());
      }
      await prefs.setString('working_days', _workingDays.join(','));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'attendance_settings_saved'))),
        );
      }
    } catch (e) {
      debugPrint('Error saving attendance config: $e');
    }
  }

  int _calculateWorkingDays() {
    if (_attendanceStartDate == null || _attendanceEndDate == null) {
      return 30;
    }

    int workingDays = 0;
    DateTime current = _attendanceStartDate!;

    while (current.isBefore(_attendanceEndDate!) ||
        current.isAtSameMomentAs(_attendanceEndDate!)) {
      if (_workingDays.contains(current.weekday)) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays > 0 ? workingDays : 30;
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
            _loadAttendance();
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

  Future<void> _loadAttendance() async {
    if (_selectedClass == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final records = await TeacherDataService.getAttendance();

      final record = records.firstWhere(
        (r) => r.date == dateStr && r.classId == _selectedClass!.id,
        orElse: () => AttendanceRecord(
          date: dateStr,
          classId: _selectedClass!.id,
          attendance: {},
        ),
      );

      _attendance.clear();

      final classStudents =
          _students.where((s) => s.classId == _selectedClass!.id).toList();
      for (final student in classStudents) {
        _attendance[student.id] = record.attendance[student.id] ?? false;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await TeacherDataService.markAttendance(
        date: dateStr,
        classId: _selectedClass!.id,
        attendance: _attendance,
      );

      final students = await TeacherDataService.getStudents();
      for (final entry in _attendance.entries) {
        final studentIndex = students.indexWhere((s) => s.id == entry.key);
        if (studentIndex >= 0 && entry.value) {

          final student = students[studentIndex];
          if (!student.attendanceDates.contains(dateStr)) {
            students[studentIndex] = student.copyWith(
              attendanceDates: [...student.attendanceDates, dateStr],
            );
          }
        }
      }
      await TeacherDataService.saveStudents(students);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'attendance_saved'))),
        );
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadAttendance();
      });
    }
  }

  void _showAttendanceSettings(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            title: Text(
              t(context, 'attendance_settings'),
              style: TextStyle(
                color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date Range for Current Month',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _attendanceStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          _attendanceStartDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isDark
                                ? AppColors.salmonDark
                                : AppColors.salmon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attendanceStartDate != null
                                  ? 'Start: ${DateFormat('MMM d, yyyy').format(_attendanceStartDate!)}'
                                  : 'Select Start Date',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textDarkMode
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _attendanceEndDate ?? DateTime.now(),
                        firstDate: _attendanceStartDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          _attendanceEndDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isDark
                                ? AppColors.salmonDark
                                : AppColors.salmon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attendanceEndDate != null
                                  ? 'End: ${DateFormat('MMM d, yyyy').format(_attendanceEndDate!)}'
                                  : 'Select End Date',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textDarkMode
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Select Working Days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...[
                    (1, 'Monday'),
                    (2, 'Tuesday'),
                    (3, 'Wednesday'),
                    (4, 'Thursday'),
                    (5, 'Friday'),
                    (6, 'Saturday'),
                    (7, 'Sunday'),
                  ].map((day) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        day.$2,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                      value: _workingDays.contains(day.$1),
                      activeColor: isDark ? AppColors.mintDark : AppColors.mint,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            _workingDays.add(day.$1);
                          } else {
                            _workingDays.remove(day.$1);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 12),
                  if (_attendanceStartDate != null &&
                      _attendanceEndDate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.mintDark : AppColors.mint)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Working Days: ${_calculateWorkingDays()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveAttendanceConfig();
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Text(t(context, 'save')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          t(context, 'attendance'),
          style: TextStyle(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings,
                color: isDark ? AppColors.textDarkMode : Colors.black87),
            onPressed: () => _showAttendanceSettings(isDark),
            tooltip: t(context, 'attendance_settings'),
          ),
          IconButton(
            icon: Icon(Icons.save,
                color: isDark ? AppColors.textDarkMode : Colors.black87),
            onPressed: _saveAttendance,
            tooltip: t(context, 'save_attendance'),
          ),
        ],
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12),
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
                                    _loadAttendance();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: isDark
                                          ? AppColors.salmonDark
                                          : AppColors.salmon),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy')
                                        .format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textDarkMode
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedClass == null
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
                          : Builder(
                              builder: (context) {
                                final classStudents = _students
                                    .where(
                                        (s) => s.classId == _selectedClass!.id)
                                    .toList();

                                if (classStudents.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No students in this class',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textLightDark
                                            : AppColors.textLight,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: classStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = classStudents[index];
                                    final isPresent =
                                        _attendance[student.id] ?? false;

                                    return Card(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : Colors.white,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: CheckboxListTile(
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
                                          'Roll: ${student.rollNumber}',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.textLightDark
                                                : AppColors.textLight,
                                          ),
                                        ),
                                        value: isPresent,
                                        activeColor: isDark
                                            ? AppColors.mintDark
                                            : AppColors.mint,
                                        onChanged: (value) {
                                          setState(() {
                                            _attendance[student.id] =
                                                value ?? false;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
