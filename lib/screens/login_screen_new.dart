/// Enterprise-level Login Screen
/// Provides secure Firebase authentication with comprehensive error handling
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

/// Login mode
enum LoginMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLang = 'en';
  String? _errorMessage;
  LoginMode _mode = LoginMode.signIn;
  String _selectedRole = 'student'; // 'student' or 'teacher'

  // Services
  final _authService = FirebaseAuthService.instance;
  final _connectivityService = ConnectivityService.instance;

  // Animation
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

    // Save language to SharedPreferences to persist across screens
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

  /// Handle login/signup with Firebase
  Future<void> _handleAuth() async {
    _clearError();

    // Rate limiting - prevent brute force
    final email = _emailCtrl.text.trim();
    if (!SecurityHelper.checkRateLimit('auth_$email',
        cooldown: const Duration(seconds: 3))) {
      _showError('Too many attempts. Please wait a moment.');
      return;
    }

    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check connectivity
    if (!_connectivityService.isOnline) {
      _showError('No internet connection. Please check your network.');
      return;
    }

    // Sanitize email input
    final sanitizedEmail = SecurityHelper.sanitizeInput(email);

    // Additional email validation
    if (!SecurityHelper.isValidEmail(sanitizedEmail)) {
      _showError('Please enter a valid email address');
      return;
    }

    // Check for SQL injection attempts
    if (SecurityHelper.containsSQLInjection(sanitizedEmail) ||
        SecurityHelper.containsSQLInjection(_passCtrl.text)) {
      SecurityHelper.logSecurityEvent('Login injection attempt', details: {
        'email': SecurityHelper.maskSensitiveData(sanitizedEmail),
      });
      _showError('Invalid input detected');
      return;
    } // Validate password match for signup
    if (_mode == LoginMode.signUp && _passCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match');
      return;
    }

    // Validate password strength for signup
    if (_mode == LoginMode.signUp) {
      // Check weak passwords
      if (SecurityHelper.isWeakPassword(_passCtrl.text)) {
        _showError('Password is too weak. Please choose a stronger password.');
        return;
      }

      // Check password strength
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

  /// Continue as guest
  Future<void> _continueAsGuest() async {
    _clearError();
    setState(() => _loading = true);

    try {
      final result = await _authService.continueAsGuest();

      if (!mounted) return;

      if (result.isSuccess) {
        // Save role and navigate based on selection
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

  /// Sign in with Google
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
        // Save role and navigate based on selection
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

  /// Send password reset email
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
      // Navigate based on selected role
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Offline indicator
            if (!_connectivityService.isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _buildOfflineIndicator(isDark),
              ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // App title
                    Text(
                      t(context, 'app.title'),
                      style: AppTextStyles.wordmark.copyWith(
                        fontSize: 32,
                        color: isDark ? AppColors.textDarkMode : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login card
                    _buildLoginCard(size, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator(bool isDark) {
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

  Widget _buildLoginCard(Size size, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: size.width > 420 ? 420 : size.width,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.salmon).withAlpha(51),
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
                  ? AppColors.cardDark.withAlpha(230)
                  : Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark
                    ? AppColors.salmonDark.withAlpha(77)
                    : Colors.white.withAlpha(179),
                width: 1.2,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _mode == LoginMode.signIn
                        ? t(context, 'login.title')
                        : 'Create Account',
                    style: AppTextStyles.headline.copyWith(
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Language selector
                  Text(
                    t(context, 'login.language'),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildLanguageRow(isDark),
                  const SizedBox(height: 16),

                  // Role selection
                  Text(
                    'Select Role',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Student'),
                          value: 'student',
                          groupValue: _selectedRole,
                          activeColor:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Teacher'),
                          value: 'teacher',
                          groupValue: _selectedRole,
                          activeColor:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(isDark),
                    const SizedBox(height: 12),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_loading,
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: t(context, 'login.email'),
                      labelStyle: TextStyle(
                        color:
                            isDark ? AppColors.textLightDark : Colors.black54,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: isDark ? AppColors.salmonDark : AppColors.salmon,
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

                  // Password field
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: _mode == LoginMode.signUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    enabled: !_loading,
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: t(context, 'login.password'),
                      labelStyle: TextStyle(
                        color:
                            isDark ? AppColors.textLightDark : Colors.black54,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color:
                              isDark ? AppColors.textLightDark : Colors.black54,
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

                  // Confirm password (signup only)
                  if (_mode == LoginMode.signUp) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_loading,
                      style: TextStyle(
                        color: isDark ? AppColors.textDarkMode : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color:
                              isDark ? AppColors.textLightDark : Colors.black54,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDark
                                ? AppColors.textLightDark
                                : Colors.black54,
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

                  // Forgot password (sign in only)
                  if (_mode == LoginMode.signIn) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.salmonDark
                                : AppColors.salmon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Login/Signup button
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

                  // Toggle mode button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _mode == LoginMode.signIn
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
                        style: TextStyle(
                          color:
                              isDark ? AppColors.textLightDark : Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.textLightDark.withAlpha(77)
                                : Colors.black26,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textLightDark
                                  : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.textLightDark.withAlpha(77)
                                : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Google Sign-In button
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
                        foregroundColor:
                            isDark ? AppColors.textDarkMode : Colors.black87,
                        side: BorderSide(
                          color:
                              isDark ? AppColors.textLightDark : Colors.black38,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor:
                            isDark ? Colors.transparent : Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Guest button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _continueAsGuest,
                      icon: const Icon(Icons.person_outline),
                      label: Text(t(context, 'login.guest')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.textDarkMode : Colors.black87,
                        side: BorderSide(
                          color:
                              isDark ? AppColors.textLightDark : Colors.black38,
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

  Widget _buildErrorBanner(bool isDark) {
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
