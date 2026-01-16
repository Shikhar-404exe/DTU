
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/note_organization.dart';
import '../core/services/firebase_auth_service.dart';
import '../core/utils/image_utils.dart';
import 'login_screen_new.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  String _photoPath = "";
  String _selectedLang = 'en';
  String _selectedClassId = 'class_10';
  bool _loading = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = prefs.getString('profile_name') ?? "";
        _selectedClassId = prefs.getString('profile_class_id') ?? 'class_10';
        _schoolCtrl.text = prefs.getString('profile_school') ?? "";
        _photoPath = prefs.getString('profile_photo') ?? "";
        _selectedLang = prefs.getString('language_code') ?? 'en';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('profile_name', _nameCtrl.text.trim());
      await prefs.setString('profile_class_id', _selectedClassId);
      await prefs.setString('profile_school', _schoolCtrl.text.trim());
      await prefs.setString('profile_photo', _photoPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile")),
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final res = await picker.pickImage(source: ImageSource.gallery);
      if (res == null) return;

      if (!mounted) return;
      setState(() => _photoPath = res.path);
    } catch (e) {
      debugPrint('Failed to pick photo: $e');
    }
  }

  Future<void> _setLanguage(String code) async {
    final scope = AppLanguageScope.of(context);
    scope.setLanguage(code);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', code);
    } catch (e) {
      debugPrint('Failed to save language: $e');
    }

    if (!mounted) return;
    setState(() => _selectedLang = code);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      await FirebaseAuthService.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const GradientBackground(child: LoginScreen()),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to logout")),
      );
    }
  }

  Widget _buildClassDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedClassId,
      style: TextStyle(
        color: isDark ? AppColors.textDarkMode : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: t(context, 'profile.class'),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textLightDark : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.school,
          color: isDark ? AppColors.textLightDark : Colors.black54,
        ),
      ),
      dropdownColor: isDark ? AppColors.cardDark : Colors.white,
      items: NoteClass.allClasses.map((cls) {
        return DropdownMenuItem<String>(
          value: cls.id,
          child: Text(
            cls.name,
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedClassId = value;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.salmonDark : AppColors.salmon,
          ),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.cardDark.withAlpha(217)
              : Colors.white.withAlpha(217),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textDarkMode : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            t(context, 'profile.title'),
            style: AppTextStyles.wordmark.copyWith(
              fontSize: 24,
              color: isDark ? AppColors.textDarkMode : Colors.black87,
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.salmon)
                        .withAlpha(51),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 480,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark.withAlpha(230)
                          : Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? AppColors.salmonDark.withAlpha(77)
                            : Colors.white.withAlpha(179),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        _avatar(isDark),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameCtrl,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkMode
                                : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: t(context, 'profile.name'),
                            labelStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textLightDark
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildClassDropdown(isDark),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _schoolCtrl,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkMode
                                : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: t(context, 'profile.school'),
                            labelStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textLightDark
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t(context, 'profile.language'),
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightDark
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _langChip("en", "English", isDark),
                            const SizedBox(width: 8),
                            _langChip("hi", "हिन्दी", isDark),
                            const SizedBox(width: 8),
                            _langChip("pa", "ਪੰਜਾਬੀ", isDark),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(t(context, 'profile.save')),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacySettingsScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.privacy_tip_rounded,
                              color:
                                  isDark ? AppColors.mintDark : AppColors.teal,
                            ),
                            label: Text(
                              'Privacy & Data',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.mintDark
                                    : AppColors.teal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.mintDark.withAlpha(128)
                                    : AppColors.teal.withAlpha(128),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loggingOut ? null : _logout,
                            icon: _loggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.logout_rounded,
                                    color: Colors.red),
                            label: Text(
                              _loggingOut ? 'Logging out...' : 'Logout',
                              style: TextStyle(
                                color: _loggingOut ? Colors.grey : Colors.red,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _loggingOut
                                    ? Colors.grey
                                    : Colors.red.withAlpha(128),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(bool isDark) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.salmonDark : AppColors.salmon)
                    .withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ImageUtils.buildProfileImage(
            imagePath: _photoPath,
            radius: 45,
            backgroundColor: isDark ? AppColors.salmonDark : AppColors.salmon,
            placeholder: const Icon(
              Icons.person_rounded,
              size: 45,
              color: Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.mintDark : AppColors.mint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.mintDark : AppColors.mint)
                      .withAlpha(102),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.edit_rounded,
              color: isDark ? AppColors.textDarkMode : Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _langChip(String code, String label, bool isDark) {
    final selected = _selectedLang == code;

    return GestureDetector(
      onTap: () => _setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.salmonDark : AppColors.salmon)
              : (isDark
                  ? AppColors.mintDark.withAlpha(77)
                  : AppColors.mint.withAlpha(128)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.salmonDark : AppColors.salmon)
                : (isDark
                    ? AppColors.mintDark.withAlpha(102)
                    : Colors.white.withAlpha(153)),
          ),
          boxShadow: selected
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
            color: selected
                ? Colors.white
                : (isDark ? AppColors.textDarkMode : Colors.black87),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
