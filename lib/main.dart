import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_initializer.dart';
import 'core/services/firebase_auth_service.dart';
import 'screens/login_screen_new.dart';
import 'screens/home_screen_wrapper.dart';
import 'screens/teacher/teacher_dashboard_wrapper.dart';

/// ---------------------------------------------------------------------------
///  🎨 Global UI: Colors & Text (Light & Dark Mode)
/// ---------------------------------------------------------------------------

class AppColors {
  // Light Mode Colors
  static const Color primary = Color(0xFFFFB4A2); // pastel salmon
  static const Color secondary = Color(0xFFB5E8CC); // pastel mint
  static const Color background = Color(0xFFFFDAD0); // light salmon background
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFF5C5C5C);
  static const Color salmon = Color(0xFFFFB4A2); // pastel salmon
  static const Color mint = Color(0xFFB5E8CC); // pastel mint
  static const Color salmonLight = Color(0xFFFFE5DF); // lighter salmon
  static const Color mintLight = Color(0xFFD8F5E3); // lighter mint
  static const Color mauve = Color(0xFFE0B0D5); // pastel mauve
  static const Color lavender = Color(0xFFD4B5FF); // pastel lavender
  static const Color teal = Color(0xFF5F9EA0); // dark teal green pastel
  static const Color cardLight = Color(0xFFFFFFFF); // white card for light mode

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF1A1A2E); // deep navy dark
  static const Color cardDark = Color(0xFF252542); // dark card
  static const Color salmonDark = Color(0xFFE8998D); // muted salmon for dark
  static const Color mintDark = Color(0xFF7EC8A3); // muted mint for dark
  static const Color mauveDark = Color(0xFFC89EB8); // muted mauve for dark
  static const Color lavenderDark =
      Color(0xFFB89FD9); // muted lavender for dark
  static const Color textDarkMode = Color(0xFFF5F5F5); // light text for dark
  static const Color textLightDark =
      Color(0xFFB0B0B0); // secondary text for dark
}

class AppTextStyles {
  static TextStyle get wordmark => GoogleFonts.ibmPlexSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: Colors.white,
      );

  static TextStyle get headline => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get body => GoogleFonts.nunitoSans(
        fontSize: 17,
        height: 1.5,
        color: AppColors.textDark,
      );

  static TextStyle get hint => GoogleFonts.nunitoSans(
        fontSize: 16,
        color: AppColors.textLight,
      );
}

class AppTheme {
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withAlpha(25), // ~0.10 opacity
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.wordmark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.white54, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.white54, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(64), // ~0.25 opacity
        hintStyle: AppTextStyles.hint.copyWith(color: Colors.white70),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.salmon,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shadowColor: AppColors.salmon.withAlpha(102), // ~0.4 opacity
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: AppTextStyles.headline,
        bodyMedium: AppTextStyles.body,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.salmonDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardDark.withAlpha(217), // ~0.85 opacity
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            AppTextStyles.wordmark.copyWith(color: AppColors.textDarkMode),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
              color: AppColors.textLightDark.withAlpha(77),
              width: 1.0), // ~0.3 opacity
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
              color: AppColors.textLightDark.withAlpha(77),
              width: 1.0), // ~0.3 opacity
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.salmonDark, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cardDark.withAlpha(153), // ~0.6 opacity
        hintStyle: AppTextStyles.hint.copyWith(color: AppColors.textLightDark),
        labelStyle: const TextStyle(color: AppColors.textLightDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.salmonDark,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shadowColor: AppColors.salmonDark.withAlpha(102), // ~0.4 opacity
        ),
      ),
      textTheme: TextTheme(
        headlineSmall:
            AppTextStyles.headline.copyWith(color: AppColors.textDarkMode),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textDarkMode),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  🌈 Gradient + Rotating Ashoka Chakra Background (Supports Dark/Light)
/// ---------------------------------------------------------------------------

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFFFDAD0);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          _RotatingAshokaChakra(isDark: isDark), // big, soft watermark
          child,
        ],
      ),
    );
  }
}

class _RotatingAshokaChakra extends StatefulWidget {
  final bool isDark;
  const _RotatingAshokaChakra({this.isDark = false});

  @override
  State<_RotatingAshokaChakra> createState() => _RotatingAshokaChakraState();
}

class _RotatingAshokaChakraState extends State<_RotatingAshokaChakra>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    // Slow, smooth rotation ~40s per full turn
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    // Get screen size to make chakra cover 1/4 of screen (top-left quadrant)
    final screenSize = MediaQuery.sizeOf(context);
    final chakraSize =
        screenSize.width * 0.9; // Big enough to cover quarter of screen

    // Position so center is at top-left corner, chakra appears ABOVE app bar
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: Offset(-chakraSize * 0.35,
              -chakraSize * 0.35), // Show about 1/4 of chakra
          child: Opacity(
            opacity: widget.isDark ? 0.25 : 0.22,
            child: SizedBox(
              width: chakraSize,
              height: chakraSize,
              child: RotationTransition(
                turns: _controller!,
                // Only apply color filter in dark mode to invert, light mode uses original image
                child: widget.isDark
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: Image.asset(
                          'assets/ashoka_chakra.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      )
                    : Image.asset(
                        'assets/ashoka_chakra.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  🌐 Simple Offline Localization (EN / HI / PA)
/// ---------------------------------------------------------------------------

class AppLanguageScope extends InheritedWidget {
  final String langCode;
  final void Function(String) setLanguage;

  const AppLanguageScope({
    super.key,
    required this.langCode,
    required this.setLanguage,
    required super.child,
  });

  static AppLanguageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
  }

  static AppLanguageScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
        scope != null, 'No AppLanguageScope found above in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppLanguageScope oldWidget) {
    return oldWidget.langCode != langCode;
  }
}

/// ---------------------------------------------------------------------------
///  🌙 Theme Mode Scope (Dark / Light)
/// ---------------------------------------------------------------------------

class AppThemeScope extends InheritedWidget {
  final bool isDarkMode;
  final void Function(bool) setDarkMode;

  const AppThemeScope({
    super.key,
    required this.isDarkMode,
    required this.setDarkMode,
    required super.child,
  });

  static AppThemeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
  }

  static AppThemeScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppThemeScope found above in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppThemeScope oldWidget) {
    return oldWidget.isDarkMode != isDarkMode;
  }
}

class AppLocalizations {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app.title': 'Vidyarthi',
      'login.title': 'Welcome back',
      'login.subtitle':
          'Sign in to generate notes, scan PDFs and share via QR.',
      'login.email': 'Email',
      'login.password': 'Password',
      'login.button': 'Login',
      'login.guest': 'Continue as guest',
      'login.language': 'Language',
      'login.error.empty': 'Please enter both email and password.',
      'home.subtitle': 'What do you want to study today?',
      'home.chip.quick': 'Quick tools',
      'home.chip.multi': 'Multi-language',
      'home.card.notes': 'Generate Notes',
      'home.card.saved': 'Saved Notes',
      'home.card.math': 'Photomath',
      'home.card.timetable': 'Timetable',
      'home.card.scanqr': 'Scan QR',
      'home.card.scanpdf': 'Scan to PDF',
      'home.card.ebook': 'Get E-Book',
      'profile.title': 'Profile',
      'profile.name': 'Full Name',
      'profile.class': 'Class / Grade',
      'profile.school': 'School / Institute',
      'profile.language': 'App Language',
      'profile.save': 'Save details',
      'profile.changePhoto': 'Change photo',
      // Teacher Dashboard
      'teacher_dashboard': 'Teacher Dashboard',
      'students': 'Students',
      'classes': 'Classes',
      'quick_actions': 'Quick Actions',
      'manage_students': 'Manage Students',
      'manage_students_sub': 'Add, edit, or remove students',
      'manage_classes': 'Manage Classes',
      'manage_classes_sub': 'Create and organize class sections',
      'student_overview': 'Student Overview',
      'no_students_yet': 'No students added yet',
      'enter_main_app': 'Enter Main App',
      'attendance': 'Attendance',
      'marks_management': 'Marks Management',
      'analytics': 'Analytics',
      'logout': 'Logout',
      'app_language': 'App Language',
      'profile': 'Profile',
      'delete': 'Delete',
      'delete_student': 'Delete Student',
      'delete_class': 'Delete Class',
      'remove': 'Remove',
      'cancel': 'Cancel',
      'save': 'Save',
      'roll': 'Roll',
      'average_marks': 'Average Marks',
      'total_subjects': 'Total Subjects',
      'grade_distribution': 'Grade Distribution',
      'close': 'Close',
      'average_attendance': 'Average Attendance',
      'marks_distribution': 'Marks Distribution',
      'student_analytics': 'Student Analytics',
      'no_classes_yet': 'No classes created yet',
      'attendance_saved': 'Attendance saved',
      'attendance_settings': 'Attendance Settings',
      'attendance_settings_saved': 'Attendance settings saved',
      'create_class_first': 'Please create a class first',
    },
    'hi': {
      'app.title': 'विद्यार्थी',
      'login.title': 'वापस स्वागत है',
      'login.subtitle':
          'नोट्स बनाने, PDF स्कैन करने और QR से शेयर करने के लिए लॉगिन करें।',
      'login.email': 'ईमेल',
      'login.password': 'पासवर्ड',
      'login.button': 'लॉगिन',
      'login.guest': 'मेहमान के रूप में जारी रखें',
      'login.language': 'भाषा',
      'login.error.empty': 'कृपया ईमेल और पासवर्ड दोनों भरें।',
      'home.subtitle': 'आज क्या पढ़ना चाहते हैं?',
      'home.chip.quick': 'फास्ट टूल्स',
      'home.chip.multi': 'बहुभाषी',
      'home.card.notes': 'नोट्स बनाएं',
      'home.card.saved': 'सेव्ड नोट्स',
      'home.card.math': 'फोटोमैथ',
      'home.card.timetable': 'टाइमटेबल',
      'home.card.scanqr': 'QR स्कैन',
      'home.card.scanpdf': 'PDF स्कैन',
      'home.card.ebook': 'ई-बुक्स',
      'profile.title': 'प्रोफ़ाइल',
      'profile.name': 'पूरा नाम',
      'profile.class': 'कक्षा',
      'profile.school': 'स्कूल / संस्थान',
      'profile.language': 'ऐप भाषा',
      'profile.save': 'विवरण सेव करें',
      'profile.changePhoto': 'फोटो बदलें',
      // Teacher Dashboard
      'teacher_dashboard': 'शिक्षक डैशबोर्ड',
      'students': 'छात्र',
      'classes': 'कक्षाएं',
      'quick_actions': 'त्वरित कार्य',
      'manage_students': 'छात्रों का प्रबंधन',
      'manage_students_sub': 'छात्रों को जोड़ें, संपादित करें या हटाएं',
      'manage_classes': 'कक्षाओं का प्रबंधन',
      'manage_classes_sub': 'कक्षा अनुभाग बनाएं और व्यवस्थित करें',
      'student_overview': 'छात्र अवलोकन',
      'no_students_yet': 'अभी तक कोई छात्र नहीं जोड़ा गया',
      'enter_main_app': 'मुख्य ऐप में जाएं',
      'attendance': 'उपस्थिति',
      'marks_management': 'अंक प्रबंधन',
      'analytics': 'विश्लेषण',
      'logout': 'लॉगआउट',
      'app_language': 'ऐप भाषा',
      'profile': 'प्रोफ़ाइल',
      'delete': 'हटाएं',
      'delete_student': 'छात्र हटाएं',
      'delete_class': 'कक्षा हटाएं',
      'remove': 'हटाएं',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'roll': 'रोल',
      'average_marks': 'औसत अंक',
      'total_subjects': 'कुल विषय',
      'grade_distribution': 'ग्रेड वितरण',
      'close': 'बंद करें',
      'average_attendance': 'औसत उपस्थिति',
      'marks_distribution': 'अंक वितरण',
      'student_analytics': 'छात्र विश्लेषण',
      'no_classes_yet': 'अभी तक कोई कक्षा नहीं बनाई गई',
      'attendance_saved': 'उपस्थिति सहेजी गई',
      'attendance_settings': 'उपस्थिति सेटिंग्स',
      'attendance_settings_saved': 'उपस्थिति सेटिंग सहेजी गई',
      'create_class_first': 'कृपया पहले एक कक्षा बनाएं',
    },
    'pa': {
      'app.title': 'ਵਿਦਿਆਰਥੀ',
      'login.title': 'ਵਾਪਸ ਸੁਆਗਤ ਹੈ',
      'login.subtitle':
          'ਨੋਟ ਬਣਾਉਣ, PDF ਸਕੈਨ ਕਰਨ ਅਤੇ QR ਨਾਲ ਸਾਂਝਾ ਕਰਨ ਲਈ ਲੌਗਿਨ ਕਰੋ।',
      'login.email': 'ਈਮੇਲ',
      'login.password': 'ਪਾਸਵਰਡ',
      'login.button': 'ਲੌਗਿਨ',
      'login.guest': 'ਗੈਸਟ ਵਜੋਂ ਜਾਰੀ ਰੱਖੋ',
      'login.language': 'ਭਾਸ਼ਾ',
      'login.error.empty': 'ਕਿਰਪਾ ਕਰਕੇ ਈਮੇਲ ਅਤੇ ਪਾਸਵਰਡ ਦੋਵੇਂ ਭਰੋ।',
      'home.subtitle': 'ਅੱਜ ਕੀ ਪੜ੍ਹਨਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'home.chip.quick': 'ਤੁਰੰਤ ਟੂਲ',
      'home.chip.multi': 'ਬਹੁ-ਭਾਸ਼ੀ',
      'home.card.notes': 'ਨੋਟ ਬਣਾਓ',
      'home.card.saved': 'ਸੇਵ ਕੀਤੇ ਨੋਟ',
      'home.card.math': 'ਫੋਟੋਮੈਥ',
      'home.card.timetable': 'ਟਾਈਮ ਟੇਬਲ',
      'home.card.scanqr': 'QR ਸਕੈਨ',
      'home.card.scanpdf': 'PDF ਸਕੈਨ',
      'home.card.ebook': 'ਈ-ਬੁੱਕ',
      'profile.title': 'ਪ੍ਰੋਫਾਈਲ',
      'profile.name': 'ਪੂਰਾ ਨਾਮ',
      'profile.class': 'ਕਲਾਸ / ਜਮਾਤ',
      'profile.school': 'ਸਕੂਲ / ਇੰਸਟੀਚਿਊਟ',
      'profile.language': 'ਐਪ ਭਾਸ਼ਾ',
      'profile.save': 'ਵੇਰਵੇ ਸੇਵ ਕਰੋ',
      'profile.changePhoto': 'ਫੋਟੋ ਬਦਲੋ',
      // Teacher Dashboard
      'teacher_dashboard': 'ਅਧਿਆਪਕ ਡੈਸ਼ਬੋਰਡ',
      'students': 'ਵਿਦਿਆਰਥੀ',
      'classes': 'ਕਲਾਸਾਂ',
      'quick_actions': 'ਤੁਰੰਤ ਕਾਰਵਾਈਆਂ',
      'manage_students': 'ਵਿਦਿਆਰਥੀਆਂ ਦਾ ਪ੍ਰਬੰਧਨ',
      'manage_students_sub': 'ਵਿਦਿਆਰਥੀਆਂ ਨੂੰ ਜੋੜੋ, ਸੰਪਾਦਿਤ ਕਰੋ ਜਾਂ ਹਟਾਓ',
      'manage_classes': 'ਕਲਾਸਾਂ ਦਾ ਪ੍ਰਬੰਧਨ',
      'manage_classes_sub': 'ਕਲਾਸ ਸੈਕਸ਼ਨ ਬਣਾਓ ਅਤੇ ਵਿਵਸਥਿਤ ਕਰੋ',
      'student_overview': 'ਵਿਦਿਆਰਥੀ ਝਲਕ',
      'no_students_yet': 'ਅਜੇ ਤੱਕ ਕੋਈ ਵਿਦਿਆਰਥੀ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ',
      'enter_main_app': 'ਮੁੱਖ ਐਪ ਵਿੱਚ ਜਾਓ',
      'attendance': 'ਹਾਜ਼ਰੀ',
      'marks_management': 'ਅੰਕ ਪ੍ਰਬੰਧਨ',
      'analytics': 'ਵਿਸ਼ਲੇਸ਼ਣ',
      'logout': 'ਲੌਗਆਉਟ',
      'app_language': 'ਐਪ ਭਾਸ਼ਾ',
      'profile': 'ਪ੍ਰੋਫਾਈਲ',
      'delete': 'ਮਿਟਾਓ',
      'delete_student': 'ਵਿਦਿਆਰਥੀ ਮਿਟਾਓ',
      'delete_class': 'ਕਲਾਸ ਮਿਟਾਓ',
      'remove': 'ਹਟਾਓ',
      'cancel': 'ਰੱਦ ਕਰੋ',
      'save': 'ਸੇਵ ਕਰੋ',
      'roll': 'ਰੋਲ',
      'average_marks': 'ਔਸਤ ਅੰਕ',
      'total_subjects': 'ਕੁੱਲ ਵਿਸ਼ੇ',
      'grade_distribution': 'ਗ੍ਰੇਡ ਵੰਡ',
      'close': 'ਬੰਦ ਕਰੋ',
      'average_attendance': 'ਔਸਤ ਹਾਜ਼ਰੀ',
      'marks_distribution': 'ਅੰਕ ਵੰਡ',
      'student_analytics': 'ਵਿਦਿਆਰਥੀ ਵਿਸ਼ਲੇਸ਼ਣ',
      'no_classes_yet': 'ਅਜੇ ਤੱਕ ਕੋਈ ਕਲਾਸ ਨਹੀਂ ਬਣਾਈ ਗਈ',
      'attendance_saved': 'ਹਾਜ਼ਰੀ ਸੰਭਾਲੀ ਗਈ',
      'attendance_settings': 'ਹਾਜ਼ਰੀ ਸੈਟਿੰਗਾਂ',
      'attendance_settings_saved': 'ਹਾਜ਼ਰੀ ਸੈਟਿੰਗਾਂ ਸੰਭਾਲੀਆਂ ਗਈਆਂ',
      'create_class_first': 'ਕਿਰਪਾ ਕਰਕੇ ਪਹਿਲਾਂ ਕਲਾਸ ਬਣਾਓ',
    },
  };

  static String translate(String langCode, String key) {
    final langMap = _values[langCode] ?? _values['en']!;
    return langMap[key] ?? _values['en']![key] ?? key;
  }
}

// helper
String t(BuildContext context, String key) {
  final scope = AppLanguageScope.of(context);
  return AppLocalizations.translate(scope.langCode, key);
}

/// ---------------------------------------------------------------------------
///  🔌 Backend Config (same names as before)
/// ---------------------------------------------------------------------------

String backendUrl = dotenv.env['BACKEND_URL'] ?? "http://172.17.4.116:8000";
String notesApiUrl = dotenv.env['NOTES_API_URL'] ?? "$backendUrl/generate-note";

/// ---------------------------------------------------------------------------
///  🔍 Backend Connection Helper
/// ---------------------------------------------------------------------------

Future<void> _checkBackendConnection() async {
  try {
    debugPrint('🔍 Checking backend connection...');

    final response = await http
        .get(Uri.parse("$backendUrl/ping"))
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        final serverIp = data["server_ip"];
        final serverPort = data["server_port"] ?? 8000;
        backendUrl = "http://$serverIp:$serverPort";
        notesApiUrl = "$backendUrl/generate-note";

        debugPrint('✓ Backend connected: $backendUrl');
      } else {
        debugPrint('⚠ Backend responded but status not ok');
      }
    } else {
      debugPrint('⚠ Backend returned status ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Backend connection failed: $e');
    debugPrint('   Using fallback URL: $backendUrl');
  }
}

/// ---------------------------------------------------------------------------
///  🏁 main()
/// ---------------------------------------------------------------------------

Future<void> main() async {
  // Wrap everything in try-catch to prevent crashes
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Setup global error handlers
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      // Catch errors outside Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Platform Error: $error');
        debugPrint('Stack trace: $stack');
        return true;
      };

      // Initialize Firebase and all core services (MUST wait for Firebase)
      final initResult = await AppInitializer.initialize();

      if (!initResult.isSuccess) {
        debugPrint('⚠️ App initialization failed: ${initResult.errorMessage}');
      } else {
        debugPrint('✅ App initialized successfully');
      }

      // Load environment variables (optional)
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('Environment file not loaded: $e');
      }

      // Optional: try ping backend with better error handling (non-blocking)
      _checkBackendConnection();

      runApp(const MyApp());
    } catch (e, stackTrace) {
      debugPrint('Fatal error in main: $e');
      debugPrint('Stack trace: $stackTrace');

      // Run app with minimal functionality in case of critical error
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'App Initialization Failed',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $e',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Attempt to restart
                        main();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Unhandled error: $error');
    debugPrint('Stack trace: $stack');
  });
}

/// ---------------------------------------------------------------------------
///  🌱 Root with language and theme handling
/// ---------------------------------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _langCode = 'en';
  bool _loadedLang = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language_code') ?? 'en';
      final darkMode = prefs.getBool('dark_mode') ?? false;
      if (!mounted) return;
      setState(() {
        _langCode = code;
        _isDarkMode = darkMode;
        _loadedLang = true;
      });
    } catch (e) {
      // Fallback to defaults if preferences fail to load
      if (!mounted) return;
      setState(() {
        _langCode = 'en';
        _isDarkMode = false;
        _loadedLang = true;
      });
    }
  }

  Future<void> _setLanguage(String code) async {
    setState(() {
      _langCode = code;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', code);
    } catch (e) {
      // Silently fail - UI already updated
      debugPrint('Failed to save language preference: $e');
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', value);
    } catch (e) {
      // Silently fail - UI already updated
      debugPrint('Failed to save dark mode preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedLang) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppThemeScope(
      isDarkMode: _isDarkMode,
      setDarkMode: _setDarkMode,
      child: AppLanguageScope(
        langCode: _langCode,
        setLanguage: _setLanguage,
        child: MaterialApp(
          title: 'Vidyarthi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashOrHome(),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  🚦 SplashOrHome
/// ---------------------------------------------------------------------------

class SplashOrHome extends StatefulWidget {
  const SplashOrHome({super.key});

  @override
  State<SplashOrHome> createState() => _SplashOrHomeState();
}

class _SplashOrHomeState extends State<SplashOrHome> {
  bool _loading = true;
  bool _isAuthenticated = false;
  String _userRole = 'student'; // 'student' or 'teacher'

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Give initialization a moment
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Try to get auth service (may fail if Firebase not initialized)
      try {
        final authService = FirebaseAuthService.instance;
        final isAuthenticated =
            authService.authState == AuthState.authenticated ||
                authService.currentUser != null;

        if (isAuthenticated) {
          if (!mounted) return;
          setState(() {
            _isAuthenticated = true;
            _loading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Firebase auth service not available: $e');
      }

      // Fallback: check SharedPreferences for guest or token
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final guest = prefs.getBool('guest') ?? false;
        final userRole = prefs.getString('user_role') ?? 'student';

        if (!mounted) return;
        setState(() {
          _isAuthenticated = (token != null && token.isNotEmpty) || guest;
          _userRole = userRole;
          _loading = false;
        });
      } catch (e) {
        debugPrint('SharedPreferences error: $e');
        // Default to login screen
        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Critical auth check error: $e');
      debugPrint('Stack trace: $stackTrace');
      // On error, show login screen
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      // Route to teacher or student dashboard based on role
      if (_userRole == 'teacher') {
        return const GradientBackground(child: TeacherDashboardWrapper());
      } else {
        return const GradientBackground(child: HomeScreenWrapper());
      }
    } else {
      return const GradientBackground(child: LoginScreen());
    }
  }
}
