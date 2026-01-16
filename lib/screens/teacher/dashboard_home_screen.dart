// filepath: lib/screens/teacher/dashboard_home_screen.dart
/// Teacher Dashboard Home - Quick overview and actions

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/utils/image_utils.dart';
import '../../services/teacher_data_service.dart';
import '../../models/teacher_models.dart';
import '../home_screen_wrapper.dart';
import 'student_management_screen.dart';
import 'class_management_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  int _totalStudents = 0;
  int _totalClasses = 0;
  bool _loading = true;
  String _teacherPhotoPath = '';
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _teacherPhotoPath = prefs.getString('teacher_profile_photo') ?? '';
          _teacherName = prefs.getString('teacher_profile_name') ?? 'Teacher';
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher profile: $e');
    }
  }

  Future<void> _pickTeacherPhoto() async {
    try {
      final picker = ImagePicker();
      final res = await picker.pickImage(source: ImageSource.gallery);
      if (res == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacher_profile_photo', res.path);

      if (mounted) {
        setState(() => _teacherPhotoPath = res.path);
      }
    } catch (e) {
      debugPrint('Failed to pick photo: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final students = await TeacherDataService.getStudents();
      final classes = await TeacherDataService.getClasses();

      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          _totalClasses = classes.length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Clear user role from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('token');

      // Sign out from Firebase
      try {
        await FirebaseAuthService.instance.signOut();
      } catch (e) {
        debugPrint('Firebase sign out error: $e');
      }

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Widget _buildProfileDrawer(bool isDark) {
    final langScope = AppLanguageScope.maybeOf(context);
    final currentLang = langScope?.langCode ?? 'en';

    return Drawer(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile Photo with Edit Button
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? AppColors.salmonDark
                                    : AppColors.salmon)
                                .withAlpha(77),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ImageUtils.buildProfileImage(
                        imagePath: _teacherPhotoPath,
                        radius: 50,
                        backgroundColor:
                            isDark ? AppColors.salmonDark : AppColors.salmon,
                        placeholder: const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickTeacherPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.mintDark : AppColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark ? AppColors.mintDark : AppColors.mint)
                                      .withAlpha(102),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: isDark ? AppColors.textDarkMode : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _teacherName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t(context, 'teacher_dashboard'),
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 16),

                // Language Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t(context, 'app_language'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLanguageChip(
                        'en', 'English', currentLang, langScope, isDark),
                    _buildLanguageChip(
                        'hi', 'हिन्दी', currentLang, langScope, isDark),
                    _buildLanguageChip(
                        'pa', 'ਪੰਜਾਬੀ', currentLang, langScope, isDark),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 16),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(t(context, 'logout')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildLanguageChip(String code, String label, String currentLang,
      AppLanguageScope? scope, bool isDark) {
    final isSelected = currentLang == code;

    return GestureDetector(
      onTap: () {
        if (scope != null) {
          scope.setLanguage(code);
          if (mounted) setState(() {});
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.salmonDark : AppColors.salmon)
              : (isDark
                  ? AppColors.mintDark.withAlpha(77)
                  : AppColors.mint.withAlpha(128)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.salmonDark : AppColors.salmon)
                : (isDark
                    ? AppColors.mintDark.withAlpha(102)
                    : Colors.white.withAlpha(153)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.salmonDark : AppColors.salmon)
                        .withAlpha(77),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textDarkMode : Colors.black87),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          t(context, 'teacher_dashboard'),
          style: TextStyle(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.school,
              color: isDark ? AppColors.textDarkMode : Colors.black87,
            ),
            onPressed: () async {
              // Navigate to student app, preserving teacher dashboard in stack
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GradientBackground(
                    child: HomeScreenWrapper(),
                  ),
                ),
              );
              // When returning, reload stats
              if (mounted) {
                _loadStats();
              }
            },
            tooltip: t(context, 'enter_main_app'),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.account_circle,
                color: isDark ? AppColors.textDarkMode : Colors.black87,
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: t(context, 'profile'),
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(isDark),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: t(context, 'students'),
                          value: '$_totalStudents',
                          icon: Icons.people,
                          color:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: t(context, 'classes'),
                          value: '$_totalClasses',
                          icon: Icons.class_,
                          color: isDark ? AppColors.mintDark : AppColors.mint,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    t(context, 'quick_actions'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ActionCard(
                    title: t(context, 'manage_students'),
                    subtitle: t(context, 'manage_students_sub'),
                    icon: Icons.person_add,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentManagementScreen(),
                      ),
                    ).then((_) {
                      _loadStats();
                      setState(() {}); // Refresh the entire page
                    }),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _ActionCard(
                    title: t(context, 'manage_classes'),
                    subtitle: t(context, 'manage_classes_sub'),
                    icon: Icons.class_,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClassManagementScreen(),
                      ),
                    ).then((_) => _loadStats()),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Student Cards Section
                  Text(
                    t(context, 'student_overview'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textDarkMode : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _StudentCardsSection(isDark: isDark),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDarkMode : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.cardDark : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              (isDark ? AppColors.salmonDark : AppColors.salmon).withAlpha(50),
          child: Icon(
            icon,
            color: isDark ? AppColors.salmonDark : AppColors.salmon,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textLightDark : AppColors.textLight,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? AppColors.textLightDark : AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Student Cards Section with Analytics
class _StudentCardsSection extends StatefulWidget {
  final bool isDark;

  const _StudentCardsSection({required this.isDark});

  @override
  State<_StudentCardsSection> createState() => _StudentCardsSectionState();
}

class _StudentCardsSectionState extends State<_StudentCardsSection> {
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

  void _showStudentAnalytics(StudentRecord student) {
    showDialog(
      context: context,
      builder: (context) => _StudentAnalyticsDialog(
        student: student,
        isDark: widget.isDark,
      ),
    );
  }

  Future<void> _deleteStudent(int index) async {
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
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            t(context, 'no_students_yet'),
            style: TextStyle(
              color:
                  widget.isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final avgMarks = student.marks.isEmpty
            ? 0.0
            : student.marks.values.reduce((a, b) => a + b) /
                student.marks.length;
        // Calculate attendance percentage - if no attendance data, show 0%
        // Otherwise show percentage of days present
        final attendancePercent = student.attendanceDates.isEmpty
            ? 0.0
            : (student.attendanceDates.length /
                    (student.attendanceDates.length > 30
                        ? student.attendanceDates.length
                        : 30)) *
                100;

        return Card(
          color: widget.isDark ? AppColors.cardDark : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      (widget.isDark ? AppColors.salmonDark : AppColors.salmon)
                          .withAlpha(100),
                  child: Text(
                    student.name
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.salmonDark
                          : AppColors.salmon,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: widget.isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll: ${student.rollNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDark
                              ? AppColors.textLightDark
                              : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MiniStatBadge(
                            icon: Icons.check_circle,
                            label: '${attendancePercent.toStringAsFixed(0)}%',
                            color: widget.isDark
                                ? AppColors.mintDark
                                : AppColors.mint,
                          ),
                          const SizedBox(width: 8),
                          _MiniStatBadge(
                            icon: Icons.star,
                            label: avgMarks.toStringAsFixed(1),
                            color: widget.isDark
                                ? AppColors.lavenderDark
                                : AppColors.lavender,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.analytics,
                        color: widget.isDark
                            ? AppColors.salmonDark
                            : AppColors.salmon,
                      ),
                      onPressed: () => _showStudentAnalytics(student),
                      tooltip: t(context, 'analytics'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: widget.isDark
                            ? Colors.red.shade300
                            : Colors.red.shade400,
                      ),
                      onPressed: () => _deleteStudent(index),
                      tooltip: t(context, 'delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentAnalyticsDialog extends StatelessWidget {
  final StudentRecord student;
  final bool isDark;

  const _StudentAnalyticsDialog({
    required this.student,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final avgMarks = student.marks.isEmpty
        ? 0.0
        : student.marks.values.reduce((a, b) => a + b) / student.marks.length;
    // More accurate attendance calculation
    final totalAttendanceDays = student.attendanceDates.length;
    final attendancePercent = totalAttendanceDays == 0
        ? 0.0
        : (totalAttendanceDays /
                (totalAttendanceDays > 30 ? totalAttendanceDays : 30)) *
            100;

    final gradeA = student.marks.values.where((m) => m >= 90).length;
    final gradeB = student.marks.values.where((m) => m >= 75 && m < 90).length;
    final gradeC = student.marks.values.where((m) => m >= 60 && m < 75).length;
    final gradeD = student.marks.values.where((m) => m < 60).length;
    final totalSubjects = student.marks.length;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        (isDark ? AppColors.salmonDark : AppColors.salmon)
                            .withAlpha(100),
                    child: Text(
                      student.name
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: TextStyle(
                        color: isDark ? AppColors.salmonDark : AppColors.salmon,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textDarkMode
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${t(context, 'roll')}: ${student.rollNumber}',
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
                ],
              ),
              const SizedBox(height: 24),
              _StatRow(
                label: t(context, 'average_marks'),
                value: avgMarks.toStringAsFixed(1),
                icon: Icons.star,
                color: isDark ? AppColors.lavenderDark : AppColors.lavender,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: t(context, 'attendance'),
                value: '${attendancePercent.toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: isDark ? AppColors.mintDark : AppColors.mint,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: t(context, 'total_subjects'),
                value: totalSubjects.toString(),
                icon: Icons.book,
                color: isDark ? AppColors.salmonDark : AppColors.salmon,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              if (totalSubjects > 0) ...[
                Text(
                  t(context, 'grade_distribution'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _GradeBar(
                  grade: 'A (90+)',
                  count: gradeA,
                  total: totalSubjects,
                  color: const Color(0xFF4CAF50),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _GradeBar(
                  grade: 'B (75-89)',
                  count: gradeB,
                  total: totalSubjects,
                  color: const Color(0xFF2196F3),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _GradeBar(
                  grade: 'C (60-74)',
                  count: gradeC,
                  total: totalSubjects,
                  color: const Color(0xFFFF9800),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _GradeBar(
                  grade: 'D (<60)',
                  count: gradeD,
                  total: totalSubjects,
                  color: const Color(0xFFF44336),
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.salmonDark : AppColors.salmon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t(context, 'close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final String grade;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  const _GradeBar({
    required this.grade,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              grade,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor:
                (isDark ? Colors.white : Colors.black).withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
