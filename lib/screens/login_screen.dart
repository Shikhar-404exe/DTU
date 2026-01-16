import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'home_screen_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLangFromPrefs();
  }

  Future<void> _loadLangFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language_code') ?? 'en';
      if (!mounted) return;
      setState(() {
        _selectedLang = code;
      });
    } catch (e) {

      debugPrint('Failed to load language preference: $e');
    }
  }

  Future<void> _setLanguage(String code) async {
    final scope = AppLanguageScope.of(context);
    scope.setLanguage(code);
    setState(() {
      _selectedLang = code;
    });
  }

  Future<void> _login({required bool asGuest}) async {
    if (!asGuest) {
      if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'login.error.empty'))),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (asGuest) {
        await prefs.remove('token');
        await prefs.setBool('guest', true);
      } else {
        await prefs.setString('token', 'local_dummy_token');
        await prefs.setBool('guest', false);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const GradientBackground(child: HomeScreenWrapper()),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeScope = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark.withAlpha(204)
                    : Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.salmon)
                        .withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      size: 20,
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (value) => themeScope.setDarkMode(value),
                    activeThumbColor: AppColors.salmonDark,
                    activeTrackColor:
                        AppColors.salmonDark.withAlpha(102),
                    inactiveThumbColor: AppColors.salmon,
                    inactiveTrackColor:
                        AppColors.salmon.withAlpha(77),
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Text(
                    t(context, 'app.title'),
                    style: AppTextStyles.wordmark.copyWith(
                      fontSize: 32,
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t(context, 'login.subtitle'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.textLightDark : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: size.width > 420 ? 420 : size.width,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppColors.salmon)
                              .withAlpha(51),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                    .withAlpha(230)
                                : Colors.white.withAlpha(230),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.salmonDark
                                      .withAlpha(77)
                                  : Colors.white.withAlpha(179),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(context, 'login.title'),
                                style: AppTextStyles.headline.copyWith(
                                  color: isDark
                                      ? AppColors.textDarkMode
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t(context, 'login.language'),
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textLightDark
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildLanguageRow(isDark),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textDarkMode
                                      : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: t(context, 'login.email'),
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textLightDark
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passCtrl,
                                obscureText: true,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textDarkMode
                                      : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: t(context, 'login.password'),
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textLightDark
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () => _login(asGuest: false),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(t(context, 'login.button')),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => _login(asGuest: true),
                                  child: Text(
                                    t(context, 'login.guest'),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textLightDark
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(bool isDark) {
    return Row(
      children: [
        _languageChip("en", "English", isDark),
        const SizedBox(width: 8),
        _languageChip("hi", "हिन्दी", isDark),
        const SizedBox(width: 8),
        _languageChip("pa", "ਪੰਜਾਬੀ", isDark),
      ],
    );
  }

  Widget _languageChip(String code, String label, bool isDark) {
    final bool selected = _selectedLang == code;
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
