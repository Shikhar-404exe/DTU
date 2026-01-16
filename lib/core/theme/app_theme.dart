/// Enterprise-level Theme Configuration
/// Provides consistent theming across all platforms and device sizes
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/responsive_utils.dart';

/// App color palette
class AppThemeColors {
  AppThemeColors._();

  // Primary Colors
  static const Color primary = Color(0xFFFB7B6F);
  static const Color primaryDark = Color(0xFFE85A4F);
  static const Color primaryLight = Color(0xFFFFABA3);

  // Secondary Colors
  static const Color secondary = Color(0xFF98D4BB);
  static const Color secondaryDark = Color(0xFF6FB99D);
  static const Color secondaryLight = Color(0xFFC4E8DA);

  // Accent Colors
  static const Color accent = Color(0xFFFFC857);
  static const Color accentDark = Color(0xFFE0A820);
  static const Color accentLight = Color(0xFFFFE08A);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF252540);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D4A);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textPrimaryDark = Color(0xFFF8F9FA);
  static const Color textSecondaryDark = Color(0xFFADB5BD);

  // Border Colors
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderDark = Color(0xFF3D3D5C);
  static const Color divider = Color(0xFFDEE2E6);
  static const Color dividerDark = Color(0xFF3D3D5C);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFFB7B6F),
    Color(0xFFFFABA3),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF98D4BB),
    Color(0xFFC4E8DA),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFFFFF5F3),
    Color(0xFFF5FFF9),
  ];

  static const List<Color> backgroundGradientDark = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];
}

/// Enterprise theme data builder
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppThemeColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppThemeColors.primaryLight,
          onPrimaryContainer: AppThemeColors.primaryDark,
          secondary: AppThemeColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: AppThemeColors.secondaryLight,
          onSecondaryContainer: AppThemeColors.secondaryDark,
          tertiary: AppThemeColors.accent,
          onTertiary: Colors.white,
          error: AppThemeColors.error,
          onError: Colors.white,
          surface: AppThemeColors.surface,
          onSurface: AppThemeColors.textPrimary,
          outline: AppThemeColors.border,
        ),
        scaffoldBackgroundColor: AppThemeColors.background,
        cardColor: AppThemeColors.card,
        dividerColor: AppThemeColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppThemeColors.surface,
          foregroundColor: AppThemeColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppThemeColors.primary,
            side: const BorderSide(color: AppThemeColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppThemeColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppThemeColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppThemeColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.error, width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppThemeColors.surface,
          selectedItemColor: AppThemeColors.primary,
          unselectedItemColor: AppThemeColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppThemeColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppThemeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppThemeColors.background,
          selectedColor: AppThemeColors.primaryLight,
          disabledColor: AppThemeColors.border,
          labelStyle: const TextStyle(color: AppThemeColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide.none,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppThemeColors.primary,
          linearTrackColor: AppThemeColors.border,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppThemeColors.primary;
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppThemeColors.primaryLight;
            }
            return Colors.grey.shade300;
          }),
        ),
      );

  /// Dark theme
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppThemeColors.primaryLight,
          onPrimary: AppThemeColors.backgroundDark,
          primaryContainer: AppThemeColors.primaryDark,
          onPrimaryContainer: AppThemeColors.primaryLight,
          secondary: AppThemeColors.secondaryLight,
          onSecondary: AppThemeColors.backgroundDark,
          secondaryContainer: AppThemeColors.secondaryDark,
          onSecondaryContainer: AppThemeColors.secondaryLight,
          tertiary: AppThemeColors.accentLight,
          onTertiary: AppThemeColors.backgroundDark,
          error: Color(0xFFFF6B6B),
          onError: Colors.white,
          surface: AppThemeColors.surfaceDark,
          onSurface: AppThemeColors.textPrimaryDark,
          outline: AppThemeColors.borderDark,
        ),
        scaffoldBackgroundColor: AppThemeColors.backgroundDark,
        cardColor: AppThemeColors.cardDark,
        dividerColor: AppThemeColors.dividerDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppThemeColors.surfaceDark,
          foregroundColor: AppThemeColors.textPrimaryDark,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeColors.primaryLight,
            foregroundColor: AppThemeColors.backgroundDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppThemeColors.primaryLight,
            side: const BorderSide(
                color: AppThemeColors.primaryLight, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppThemeColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppThemeColors.surfaceDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppThemeColors.primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppThemeColors.error, width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppThemeColors.primaryLight,
          foregroundColor: AppThemeColors.backgroundDark,
          elevation: 4,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppThemeColors.surfaceDark,
          selectedItemColor: AppThemeColors.primaryLight,
          unselectedItemColor: AppThemeColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppThemeColors.surfaceDark,
          contentTextStyle:
              const TextStyle(color: AppThemeColors.textPrimaryDark),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppThemeColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppThemeColors.backgroundDark,
          selectedColor: AppThemeColors.primaryDark,
          disabledColor: AppThemeColors.borderDark,
          labelStyle: const TextStyle(color: AppThemeColors.textPrimaryDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide.none,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppThemeColors.primaryLight,
          linearTrackColor: AppThemeColors.borderDark,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppThemeColors.primaryLight;
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppThemeColors.primary;
            }
            return Colors.grey.shade700;
          }),
        ),
      );
}

/// Extension for easy theme access
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Colors
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get surfaceColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;

  // Responsive shortcuts
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
}
