

library;

class AppConstants {

  AppConstants._();

  static const String appName = 'Vidyarthi';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 4);

  static const String languageCodeKey = 'language_code';
  static const String darkModeKey = 'dark_mode';
  static const String tokenKey = 'token';
  static const String guestKey = 'guest';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String profilePhotoKey = 'profile_photo';
  static const String notesKey = 'notes_v1';
  static const String timetableKey = 'timetable_v1';
  static const String onboardingCompleteKey = 'onboarding_complete';

  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxEmailLength = 254;
  static const int maxNoteContentLength = 50000;
  static const int maxFileSize = 10 * 1024 * 1024;

  static const int maxRetries = 3;
  static const int paginationLimit = 20;

  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 24.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = true;

  static const String openRouterApiKey =
      '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';
  static const String openRouterModel = 'xiaomi/mimo-v2-flash:free';
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  static const String youtubeApiKey = 'AIzaSyCN9uZH6-Go2C8H14htrrSS15KrY_M9_-k';
}
