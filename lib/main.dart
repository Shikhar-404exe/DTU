import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sin, pi;
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

class AppColors {

  static const Color primary = Color(0xFFFFC8DD);
  static const Color secondary = Color(0xFFBDE0FE);
  static const Color background = Color(0xFFFFF5F8);
  static const Color textDark = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF8E8E8E);
  static const Color salmon = Color(0xFFFFAFCC);
  static const Color mint = Color(0xFFC7F9CC);
  static const Color salmonLight = Color(0xFFFFE5EF);
  static const Color mintLight = Color(0xFFE8FCEA);
  static const Color mauve = Color(0xFFCDB4DB);
  static const Color lavender = Color(0xFFE2CFEA);
  static const Color peach = Color(0xFFFFD6A5);
  static const Color sky = Color(0xFFA2D2FF);
  static const Color lilac = Color(0xFFD4C1EC);
  static const Color teal = Color(0xFFB8E0D2);
  static const Color skyLight = Color(0xFFE0F2FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardSoft = Color(0xFFFFFBFE);

  static const Color gradientStart = Color(0xFFFFF5F8);
  static const Color gradientMid = Color(0xFFFFF9FC);
  static const Color gradientEnd = Color(0xFFFFFDFE);

  static const Color accentOrange = Color(0xFFFFB380);
  static const Color accentGreen = Color(0xFF98D7C2);
  static const Color accentBlue = Color(0xFF87C4FF);
  static const Color accentPurple = Color(0xFFC3AED6);

  static const Color cardDark = cardLight;
  static const Color textDarkMode = textDark;
  static const Color textLightDark = textLight;
  static const Color salmonDark = salmon;
  static const Color mintDark = mint;
  static const Color backgroundDark = background;
  static const Color lavenderDark = lavender;
  static const Color mauveDark = mauve;
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
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardLight,
      background: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardLight.withAlpha(230),
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            AppTextStyles.wordmark.copyWith(color: AppColors.textDark),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              BorderSide(color: AppColors.primary.withAlpha(128), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              BorderSide(color: AppColors.primary.withAlpha(128), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cardLight.withAlpha(230),
        hintStyle: AppTextStyles.hint.copyWith(color: AppColors.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shadowColor: AppColors.primary.withAlpha(77),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 4,
        shadowColor: AppColors.primary.withAlpha(51),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: AppTextStyles.headline,
        bodyMedium: AppTextStyles.body,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.salmon,
        unselectedItemColor: AppColors.textLight,
        elevation: 8,
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE8E8),
            Color(0xFFFFF5F5),
            Color(0xFFFFF0F0),
            Color(0xFFFFEBEB),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [

          const _EnhancedVectorDecorations(),
          const _GeometricPatterns(),
          const _RotatingAshokaChakra(),
          child,
        ],
      ),
    );
  }
}

class _EnhancedVectorDecorations extends StatelessWidget {
  const _EnhancedVectorDecorations();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        children: [

          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withOpacity(0.25),
                    AppColors.teal.withOpacity(0.12),
                    AppColors.teal.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.05,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mauve.withOpacity(0.2),
                    AppColors.mauve.withOpacity(0.1),
                    AppColors.lavender.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.35,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(150),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.teal.withOpacity(0.18),
                    AppColors.mint.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.12,
            left: size.width * 0.08,
            child: Container(
              width: size.width * 0.22,
              height: size.width * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mauve.withOpacity(0.18),
                    AppColors.lavender.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.2,
            right: size.width * 0.02,
            child: Container(
              width: size.width * 0.28,
              height: size.width * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withOpacity(0.15),
                    AppColors.sky.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.55,
            left: size.width * 0.02,
            child: Container(
              width: size.width * 0.15,
              height: size.width * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mauve.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricPatterns extends StatelessWidget {
  const _GeometricPatterns();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        children: [

          Positioned(
            top: size.height * 0.08,
            left: size.width * 0.35,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.teal.withOpacity(0.15),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.45,
            right: size.width * 0.12,
            child: CustomPaint(
              size: const Size(30, 30),
              painter: _TrianglePainter(
                color: AppColors.mauve.withOpacity(0.15),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.65,
            left: size.width * 0.18,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.teal.withOpacity(0.12),
                  width: 2,
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.18,
            right: size.width * 0.15,
            child: _DotsPattern(
              color: AppColors.mauve.withOpacity(0.1),
            ),
          ),

          Positioned(
            bottom: size.height * 0.15,
            left: size.width * 0.1,
            child: _DotsPattern(
              color: AppColors.teal.withOpacity(0.08),
              rows: 3,
              cols: 4,
            ),
          ),

          Positioned(
            top: size.height * 0.75,
            right: size.width * 0.25,
            child: CustomPaint(
              size: const Size(60, 20),
              painter: _WaveLinePainter(
                color: AppColors.mauve.withOpacity(0.12),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.35,
            right: size.width * 0.08,
            child: CustomPaint(
              size: const Size(25, 25),
              painter: _HexagonPainter(
                color: AppColors.teal.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsPattern extends StatelessWidget {
  final Color color;
  final int rows;
  final int cols;

  const _DotsPattern({
    required this.color,
    this.rows = 3,
    this.cols = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
          rows,
          (i) => Row(
                children: List.generate(
                    cols,
                    (j) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        )),
              )),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveLinePainter extends CustomPainter {
  final Color color;
  _WaveLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 10) {
      path.quadraticBezierTo(
        x + 2.5,
        x % 20 == 0 ? 0 : size.height,
        x + 5,
        size.height / 2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RotatingAshokaChakra extends StatefulWidget {
  const _RotatingAshokaChakra();

  @override
  State<_RotatingAshokaChakra> createState() => _RotatingAshokaChakraState();
}

class _RotatingAshokaChakraState extends State<_RotatingAshokaChakra>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
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

    final screenSize = MediaQuery.sizeOf(context);
    final chakraSize = screenSize.width * 0.9;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: Offset(-chakraSize * 0.35, -chakraSize * 0.35),
          child: Opacity(
            opacity: 0.15,
            child: SizedBox(
              width: chakraSize,
              height: chakraSize,
              child: RotationTransition(
                turns: _controller!,
                child: Image.asset(
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
    return false;
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

String t(BuildContext context, String key) {
  final scope = AppLanguageScope.of(context);
  return AppLocalizations.translate(scope.langCode, key);
}

String backendUrl = dotenv.env['BACKEND_URL'] ?? "http://172.17.4.116:8000";
String notesApiUrl = dotenv.env['NOTES_API_URL'] ?? "$backendUrl/generate-note";

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

Future<void> main() async {

  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Platform Error: $error');
        debugPrint('Stack trace: $stack');
        return true;
      };

      final initResult = await AppInitializer.initialize();

      if (!initResult.isSuccess) {
        debugPrint('⚠️ App initialization failed: ${initResult.errorMessage}');
      } else {
        debugPrint('✅ App initialized successfully');
      }

      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('Environment file not loaded: $e');
      }

      _checkBackendConnection();

      runApp(const MyApp());
    } catch (e, stackTrace) {
      debugPrint('Fatal error in main: $e');
      debugPrint('Stack trace: $stackTrace');

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _langCode = 'en';
  bool _loadedLang = false;
  final bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language_code') ?? 'en';

      if (!mounted) return;
      setState(() {
        _langCode = code;
        _loadedLang = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _langCode = 'en';
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
      debugPrint('Failed to save language preference: $e');
    }
  }

  void _setDarkMode(bool value) {

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
          themeMode: ThemeMode.light,
          home: const SplashOrHome(),
        ),
      ),
    );
  }
}

class SplashOrHome extends StatefulWidget {
  const SplashOrHome({super.key});

  @override
  State<SplashOrHome> createState() => _SplashOrHomeState();
}

class _SplashOrHomeState extends State<SplashOrHome> {
  bool _loading = true;
  bool _isAuthenticated = false;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

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

        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Critical auth check error: $e');
      debugPrint('Stack trace: $stackTrace');

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
