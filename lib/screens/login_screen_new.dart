

library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../core/services/firebase_auth_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/utils/security_helper.dart';
import 'home_screen_wrapper.dart';
import 'teacher/teacher_dashboard_wrapper.dart';

enum LoginMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLang = 'en';
  String? _errorMessage;
  LoginMode _mode = LoginMode.signIn;
  String _selectedRole = 'student';

  final _authService = FirebaseAuthService.instance;
  final _connectivityService = ConnectivityService.instance;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isLanguageLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLanguageLoaded) {
      _loadLangFromPrefs();
      _isLanguageLoaded = true;
    }
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  Future<void> _loadLangFromPrefs() async {
    try {
      final scope = AppLanguageScope.maybeOf(context);
      if (scope != null && mounted) {
        setState(() {
          _selectedLang = scope.langCode;
        });
      }
    } catch (e) {
      debugPrint('Failed to load language preference: $e');
    }
  }

  Future<void> _setLanguage(String code) async {
    final scope = AppLanguageScope.maybeOf(context);
    scope?.setLanguage(code);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', code);
    } catch (e) {
      debugPrint('Failed to save language preference: $e');
    }

    if (mounted) {
      setState(() {
        _selectedLang = code;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == LoginMode.signIn ? LoginMode.signUp : LoginMode.signIn;
      _errorMessage = null;
      _confirmPassCtrl.clear();
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _handleAuth() async {
    _clearError();

    final email = _emailCtrl.text.trim();
    if (!SecurityHelper.checkRateLimit('auth_$email',
        cooldown: const Duration(seconds: 3))) {
      _showError('Too many attempts. Please wait a moment.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_connectivityService.isOnline) {
      _showError('No internet connection. Please check your network.');
      return;
    }

    final sanitizedEmail = SecurityHelper.sanitizeInput(email);

    if (!SecurityHelper.isValidEmail(sanitizedEmail)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (SecurityHelper.containsSQLInjection(sanitizedEmail) ||
        SecurityHelper.containsSQLInjection(_passCtrl.text)) {
      SecurityHelper.logSecurityEvent('Login injection attempt', details: {
        'email': SecurityHelper.maskSensitiveData(sanitizedEmail),
      });
      _showError('Invalid input detected');
      return;
    }
    if (_mode == LoginMode.signUp && _passCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_mode == LoginMode.signUp) {

      if (SecurityHelper.isWeakPassword(_passCtrl.text)) {
        _showError('Password is too weak. Please choose a stronger password.');
        return;
      }

      final strength = SecurityHelper.checkPasswordStrength(_passCtrl.text);
      if (strength == PasswordStrength.weak) {
        _showError('Password is too weak. ${strength.description}');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      Result<AppUser> result;

      if (_mode == LoginMode.signIn) {
        result = await _authService.signInWithEmailAndPassword(
          email: sanitizedEmail,
          password: _passCtrl.text,
        );
      } else {
        result = await _authService.createAccountWithEmailAndPassword(
          email: sanitizedEmail,
          password: _passCtrl.text,
        );
      }

      if (!mounted) return;

      if (result.isSuccess) {
        _navigateToHome();
      } else {
        final error = result.error;
        if (error is AuthException) {
          _showError(error.userFriendlyMessage);
        } else if (error is ValidationException) {
          _showError(error.userFriendlyMessage);
        } else {
          _showError(error?.message ?? 'An error occurred');
        }
      }
    } catch (e) {
      debugPrint('Auth error: $e');
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    _clearError();
    setState(() => _loading = true);

    try {
      final result = await _authService.continueAsGuest();

      if (!mounted) return;

      if (result.isSuccess) {

        await _navigateToHome();
      } else {
        _showError(result.error?.message ?? 'Failed to continue as guest');
      }
    } catch (e) {
      debugPrint('Guest login error: $e');
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_connectivityService.isOnline) {
      _showError('No internet connection');
      return;
    }

    setState(() => _loading = true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {

        await _navigateToHome();
      } else {
        final error = result.error;
        if (error is AuthException) {
          _showError(error.userFriendlyMessage);
        } else {
          _showError(result.error?.message ?? 'Google sign-in failed');
        }
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address first');
      return;
    }

    if (!_connectivityService.isOnline) {
      _showError('No internet connection');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.sendPasswordResetEmail(email);

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = result.error;
        if (error is AuthException) {
          _showError(error.userFriendlyMessage);
        } else {
          _showError(error?.message ?? 'Failed to send reset email');
        }
      }
    } catch (e) {
      _showError('Failed to send reset email');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
    }
  }

  Future<void> _navigateToHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _selectedRole);
    } catch (e) {
      debugPrint('Error saving user role: $e');
    }

    if (mounted) {

      final Widget destination = _selectedRole == 'teacher'
          ? const TeacherDashboardWrapper()
          : const HomeScreenWrapper();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => GradientBackground(child: destination),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [

            if (!_connectivityService.isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _buildOfflineIndicator(),
              ),

            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.salmon, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.salmon.withAlpha(128),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      t(context, 'app.title'),
                      style: AppTextStyles.wordmark.copyWith(
                        fontSize: 32,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📚 Learn Anywhere, Anytime',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textLight,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildLoginCard(size),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Offline',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(Size size) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: size.width > 420 ? 420 : size.width,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.salmon.withAlpha(51),
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
              color: Colors.white.withAlpha(245),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withAlpha(179),
                width: 1.2,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Text(
                        _mode == LoginMode.signIn ? '👋 ' : '✨ ',
                        style: const TextStyle(fontSize: 28),
                      ),
                      Text(
                        _mode == LoginMode.signIn
                            ? t(context, 'login.title')
                            : 'Create Account',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    t(context, 'login.language'),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildLanguageRow(),
                  const SizedBox(height: 16),

                  Text(
                    '🎓 Select Role',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleCard(
                          'student',
                          '👨‍🎓',
                          'Student',
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleCard(
                          'teacher',
                          '👩‍🏫',
                          'Teacher',
                          AppColors.lavender,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_loading,
                    style: const TextStyle(
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: t(context, 'login.email'),
                      labelStyle: const TextStyle(
                        color: AppColors.textLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.salmon,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    onChanged: (_) => _clearError(),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: _mode == LoginMode.signUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    enabled: !_loading,
                    style: const TextStyle(
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: t(context, 'login.password'),
                      labelStyle: const TextStyle(
                        color: AppColors.textLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.salmon,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textLight,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => _clearError(),
                    onFieldSubmitted: (_) {
                      if (_mode == LoginMode.signIn) {
                        _handleAuth();
                      }
                    },
                  ),

                  if (_mode == LoginMode.signUp) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_loading,
                      style: const TextStyle(
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(
                          color: AppColors.textLight,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.salmon,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (_mode == LoginMode.signUp) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passCtrl.text) {
                            return 'Passwords do not match';
                          }
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleAuth(),
                    ),
                  ],

                  if (_mode == LoginMode.signIn) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.salmon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleAuth,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_mode == LoginMode.signIn
                              ? t(context, 'login.button')
                              : 'Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _mode == LoginMode.signIn
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
                        style: const TextStyle(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.black26,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.g_mobiledata, size: 24);
                        },
                      ),
                      label: const Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(
                          color: Colors.black38,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _continueAsGuest,
                      icon: const Icon(Icons.person_outline),
                      label: Text(t(context, 'login.guest')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(
                          color: Colors.black38,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String emoji, String label, Color color) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withAlpha(128),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textDark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: _clearError,
            child: const Icon(Icons.close, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow() {
    return Row(
      children: [
        _languageChip("en", "🇬🇧 English"),
        const SizedBox(width: 8),
        _languageChip("hi", "🇮🇳 हिन्दी"),
        const SizedBox(width: 8),
        _languageChip("pa", "ਪੰਜਾਬੀ"),
      ],
    );
  }

  Widget _languageChip(String code, String label) {
    final bool selected = _selectedLang == code;
    return GestureDetector(
      onTap: () => _setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.salmon : AppColors.mint.withAlpha(128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.salmon : Colors.white.withAlpha(153),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.salmon.withAlpha(77),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
