// lib/screens/home_screen_wrapper.dart
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'home_screen.dart';
import 'saved_notes_organized_screen.dart';
import 'timetable_screen.dart';
import 'photomath_screen.dart';
import 'note_scan_qr.dart';
import 'profile_screen.dart';

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  // Helper to access state from child widgets
  static _HomeScreenWrapperState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeScreenWrapperState>();
    if (state == null) {
      throw Exception(
          'HomeScreenWrapper state not found. Make sure HomeScreenWrapper is an ancestor.');
    }
    return state;
  }

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  int _currentIndex = 0;
  String _profilePhotoPath = "";

  // keep screens in the order of bottom nav
  final List<Widget> _screens = const [
    HomeScreen(),
    SavedNotesOrganizedScreen(),
    TimetableScreen(),
    PhotomathScreen(),
    NoteScanQR(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _profilePhotoPath = prefs.getString('profile_photo') ?? "";
      });
    } catch (e) {
      debugPrint('Failed to load profile photo: $e');
    }
  }

  // expose jumpTo for children to switch tabs while preserving the wrapper
  void jumpTo(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() => _currentIndex = index);
  }

  void _openProfileDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Open drawer from right side
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile Drawer',
      barrierColor: Colors.black.withAlpha(77), // ~0.3 opacity
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _ProfileDrawer(
            photoPath: _profilePhotoPath,
            isDark: isDark,
            onProfileTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => _loadProfilePhoto());
            },
            onLogout: () async {
              Navigator.pop(context);

              // Sign out from Firebase
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                debugPrint('Firebase signOut error: $e');
              }

              // Clear local data
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.setBool('guest', false);
              await prefs.remove('user_email');

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashOrHome()),
                (route) => false,
              );
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), // Slide from right
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final File? imgFile =
        _profilePhotoPath.isNotEmpty ? File(_profilePhotoPath) : null;
    final hasPhoto = imgFile != null && imgFile.existsSync();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, // Allow body to extend behind app bar
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to blend with body
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t(context, 'app.title'),
          style: AppTextStyles.wordmark.copyWith(
            color: isDark ? AppColors.textDarkMode : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          // Profile icon button
          GestureDetector(
            onTap: _openProfileDrawer,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.salmonDark : AppColors.salmon)
                        .withAlpha(102), // ~0.4 opacity
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(26), // ~0.1 opacity
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    isDark ? AppColors.salmonDark : AppColors.salmon,
                backgroundImage: hasPhoto ? FileImage(imgFile) : null,
                child: !hasPhoto
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.salmon)
                  .withAlpha(51), // ~0.2 opacity
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark
                  ? AppColors.cardDark.withAlpha(230) // ~0.9 opacity
                  : Colors.white.withAlpha(230),
              selectedItemColor: isDark
                  ? AppColors.salmonDark
                  : const Color(0xFFE07B64), // darker salmon
              unselectedItemColor:
                  isDark ? AppColors.textLightDark : Colors.black54,
              showUnselectedLabels: true,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_outline),
                  activeIcon: Icon(Icons.bookmark),
                  label: "Saved",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_note_outlined),
                  activeIcon: Icon(Icons.event_note),
                  label: "Timetable",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calculate_outlined),
                  activeIcon: Icon(Icons.calculate),
                  label: "Math",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  activeIcon: Icon(Icons.qr_code_scanner),
                  label: "Scan QR",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile Drawer Widget - Slides from right
class _ProfileDrawer extends StatelessWidget {
  final String photoPath;
  final bool isDark;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  const _ProfileDrawer({
    required this.photoPath,
    required this.isDark,
    required this.onProfileTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final File? imgFile = photoPath.isNotEmpty ? File(photoPath) : null;
    final hasPhoto = imgFile != null && imgFile.existsSync();
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        height: screenHeight,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.salmon)
                  .withAlpha(77), // ~0.3 opacity
              blurRadius: 30,
              offset: const Offset(-10, 0),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(26), // ~0.1 opacity
              blurRadius: 10,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                                .withAlpha(128) // ~0.5 opacity
                            : AppColors.salmonLight.withAlpha(128),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.textDarkMode
                            : AppColors.textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile avatar with 3D effect
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark ? AppColors.salmonDark : AppColors.salmon)
                                  .withAlpha(102), // ~0.4 opacity
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(26), // ~0.1 opacity
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          isDark ? AppColors.salmonDark : AppColors.salmon,
                      backgroundImage: hasPhoto ? FileImage(imgFile) : null,
                      child: !hasPhoto
                          ? const Icon(Icons.person_rounded,
                              color: Colors.white, size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Profile option
                _DrawerOption(
                  icon: Icons.person_outline_rounded,
                  label: t(context, 'profile.title'),
                  isDark: isDark,
                  onTap: onProfileTap,
                ),
                const SizedBox(height: 12),

                // Dark/Light Mode Toggle
                _ThemeToggleOption(isDark: isDark),

                const Spacer(),

                // Logout option at bottom
                _DrawerOption(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDark: isDark,
                  onTap: onLogout,
                  isDestructive: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.redAccent
        : (isDark ? AppColors.textDarkMode : AppColors.textDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark.withAlpha(128) // ~0.5 opacity
                : AppColors.salmonLight.withAlpha(77), // ~0.3 opacity
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.salmon)
                    .withAlpha(26), // ~0.1 opacity
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withAlpha(128), // ~0.5 opacity
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleOption extends StatelessWidget {
  final bool isDark;

  const _ThemeToggleOption({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final themeScope = AppThemeScope.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withAlpha(128) // ~0.5 opacity
            : AppColors.mintLight.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.mint)
                .withAlpha(26), // ~0.1 opacity
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? AppColors.textDarkMode : AppColors.textDark,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            isDark ? 'Dark Mode' : 'Light Mode',
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeScope.setDarkMode(value);
              Navigator.pop(context); // Close drawer after toggle
            },
            activeThumbColor: AppColors.salmonDark,
            activeTrackColor:
                AppColors.salmonDark.withAlpha(102), // ~0.4 opacity
            inactiveThumbColor: AppColors.salmon,
            inactiveTrackColor: AppColors.salmon.withAlpha(77), // ~0.3 opacity
          ),
        ],
      ),
    );
  }
}
