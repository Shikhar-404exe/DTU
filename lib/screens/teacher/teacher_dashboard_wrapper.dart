

library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../core/services/firebase_auth_service.dart';
import '../login_screen_new.dart';
import 'dashboard_home_screen.dart';
import 'attendance_screen.dart';
import 'marks_management_screen.dart';
import 'analytics_screen.dart';

class TeacherDashboardWrapper extends StatefulWidget {
  const TeacherDashboardWrapper({super.key});

  @override
  State<TeacherDashboardWrapper> createState() =>
      _TeacherDashboardWrapperState();
}

class _TeacherDashboardWrapperState extends State<TeacherDashboardWrapper> {
  int _currentIndex = 0;
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _verifyTeacherAccess();
  }

  Future<void> _verifyTeacherAccess() async {
    try {
      final authService = FirebaseAuthService.instance;
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      if (authService.currentUser == null || userRole != 'teacher') {
        debugPrint('Security: Unauthorized teacher dashboard access attempt');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isVerifying = false);
      }
    } catch (e) {
      debugPrint('Teacher access verification error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  final List<Widget> _screens = const [
    DashboardHomeScreen(),
    AttendanceScreen(),
    MarksManagementScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isVerifying) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: isDark ? AppColors.salmonDark : AppColors.salmon,
          unselectedItemColor:
              isDark ? AppColors.textLightDark : AppColors.textLight,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: t(context, 'teacher_dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.check_circle_outline),
              label: t(context, 'attendance'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.grade),
              label: t(context, 'marks_management'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics),
              label: t(context, 'analytics'),
            ),
          ],
        ),
      ),
    );
  }
}
