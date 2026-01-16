

library;

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';
import '../../widgets/pie_chart_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<StudentRecord> _students = [];
  List<ClassSection> _classes = [];
  ClassSection? _selectedClass;
  bool _loading = true;

  double _averageAttendance = 0.0;
  Map<String, int> _marksDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students = await TeacherDataService.getStudents();
      final classes = await TeacherDataService.getClasses();

      if (mounted) {
        setState(() {
          _students = students;
          _classes = classes;
          _loading = false;
          if (_classes.isNotEmpty) {
            _selectedClass = _classes.first;
            _calculateStats();
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

  void _calculateStats() {
    if (_selectedClass == null) return;

    final classStudents = _students
        .where((s) => _selectedClass!.studentIds.contains(s.id))
        .toList();

    if (classStudents.isEmpty) {
      _averageAttendance = 0.0;
      _marksDistribution = {};
      return;
    }

    const totalDays = 30;
    final totalAttendance = classStudents.fold<double>(
      0.0,
      (sum, student) {
        final attendancePercentage = student.attendanceDates.isNotEmpty
            ? (student.attendanceDates.length / totalDays) * 100
            : 0.0;
        return sum + attendancePercentage;
      },
    );
    _averageAttendance = totalAttendance / classStudents.length;

    _marksDistribution = {
      'A (90+)': 0,
      'B (75-89)': 0,
      'C (60-74)': 0,
      'D (<60)': 0,
    };

    for (final student in classStudents) {
      if (student.marks.isEmpty) continue;

      final avgMarks = student.marks.values.fold<double>(
            0.0,
            (sum, mark) => sum + mark,
          ) /
          student.marks.length;

      if (avgMarks >= 90) {
        _marksDistribution['A (90+)'] = _marksDistribution['A (90+)']! + 1;
      } else if (avgMarks >= 75) {
        _marksDistribution['B (75-89)'] = _marksDistribution['B (75-89)']! + 1;
      } else if (avgMarks >= 60) {
        _marksDistribution['C (60-74)'] = _marksDistribution['C (60-74)']! + 1;
      } else {
        _marksDistribution['D (<60)'] = _marksDistribution['D (<60)']! + 1;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          t(context, 'analytics'),
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
                    t(context, 'no_classes_yet'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textLightDark
                          : AppColors.textLight,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
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
                                _calculateStats();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _MetricCard(
                        title: t(context, 'average_attendance'),
                        value: '${_averageAttendance.toStringAsFixed(1)}%',
                        icon: Icons.people,
                        color: isDark ? AppColors.mintDark : AppColors.mint,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        t(context, 'marks_distribution'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ..._marksDistribution.entries.map((entry) {
                        final total = _marksDistribution.values
                            .fold<int>(0, (sum, val) => sum + val);
                        final percentage = total > 0
                            ? (entry.value / total * 100).toStringAsFixed(1)
                            : '0.0';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DistributionBar(
                            label: entry.key,
                            count: entry.value,
                            percentage: percentage,
                            isDark: isDark,
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      Text(
                        t(context, 'student_analytics'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ..._getClassStudents().map((student) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StudentAnalyticsCard(
                            student: student,
                            isDark: isDark,
                            onTap: () => _showStudentDetailDialog(student),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  List<StudentRecord> _getClassStudents() {
    if (_selectedClass == null) return [];
    return _students
        .where((s) => _selectedClass!.studentIds.contains(s.id))
        .toList();
  }

  void _showStudentDetailDialog(StudentRecord student) {
    const totalDays = 30;
    final presentDays = student.attendanceDates.length;
    final absentDays = totalDays - presentDays;
    final attendancePercent =
        (presentDays / totalDays * 100).toStringAsFixed(1);

    final avgMarks = student.marks.isEmpty
        ? 0.0
        : student.marks.values.fold<double>(0.0, (sum, mark) => sum + mark) /
            student.marks.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Roll No: ${student.rollNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textLightDark
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? AppColors.textLightDark
                            : AppColors.textLight,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  t(context, 'attendance_overview'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChartWidget(
                    data: [
                      PieChartData(
                        label: 'Present',
                        value: presentDays.toDouble(),
                        color: isDark ? AppColors.mintDark : AppColors.mint,
                      ),
                      PieChartData(
                        label: 'Absent',
                        value: absentDays.toDouble(),
                        color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      ),
                    ],
                    showLegend: true,
                    size: 180,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Attendance: $attendancePercent%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (student.marks.isNotEmpty) ...[
                  Text(
                    t(context, 'subject_wise_performance'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChartWidget(
                      data: student.marks.entries.map((entry) {
                        return PieChartData(
                          label: entry.key,
                          value: entry.value,
                          color: _getSubjectColor(entry.key, isDark),
                        );
                      }).toList(),
                      showLegend: true,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Average: ${avgMarks.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkMode
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...student.marks.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No marks recorded yet',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textLightDark
                              : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject, bool isDark) {
    final colors = isDark
        ? [
            AppColors.salmonDark,
            AppColors.mintDark,
            AppColors.mauveDark,
            AppColors.lavenderDark,
            AppColors.teal,
          ]
        : [
            AppColors.salmon,
            AppColors.mint,
            AppColors.mauve,
            AppColors.lavender,
            AppColors.teal,
          ];

    final index = subject.hashCode.abs() % colors.length;
    return colors[index];
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textLightDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final String percentage;
  final bool isDark;

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              ),
            ),
            Text(
              '$count students ($percentage%)',
              style: TextStyle(
                color: isDark ? AppColors.textLightDark : AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: double.tryParse(percentage)! / 100,
            minHeight: 12,
            backgroundColor: isDark ? Colors.white24 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.salmonDark : AppColors.salmon,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentAnalyticsCard extends StatelessWidget {
  final StudentRecord student;
  final bool isDark;
  final VoidCallback onTap;

  const _StudentAnalyticsCard({
    required this.student,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const totalDays = 30;
    final presentDays = student.attendanceDates.length;
    final attendancePercent =
        (presentDays / totalDays * 100).toStringAsFixed(1);

    final avgMarks = student.marks.isEmpty
        ? 0.0
        : student.marks.values.fold<double>(0.0, (sum, mark) => sum + mark) /
            student.marks.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
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
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: isDark ? AppColors.mintDark : AppColors.mint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Attendance: $attendancePercent%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Avg Marks: ${avgMarks.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
