/// Enterprise-level app constants
/// Centralized configuration for the entire application
library;

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Vidyarthi';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 4);

  // Cache Keys
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

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxEmailLength = 254;
  static const int maxNoteContentLength = 50000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // API Limits
  static const int maxRetries = 3;
  static const int paginationLimit = 20;

  // UI Constants
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 24.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = true;

  // Gemini AI Configuration
  static const String geminiApiKey = 'AIzaSyCSzJ9j0nOqnhyAqmrDacJTm9daye9t59w';
  static const String geminiProjectId = 'sih-2025';
  static const String geminiProjectNumber = '886469668564';
  static const String geminiModel = 'gemini-2.5-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  // OpenAI Configuration - DISABLED (no credits)
  // static const String openAiApiKey = '';
  // static const String openAiModel = 'gpt-4o-mini';
  // static const String openAiBaseUrl = 'https://api.openai.com/v1';

  // Hugging Face Configuration - DISABLED (invalid token)
  // static const String huggingFaceApiKey = '';
  // static const String huggingFaceBaseUrl = 'https://api-inference.huggingface.co/models';
}
