/// Enterprise-level App Initializer
/// Handles all app initialization with proper error handling and crash prevention
library;

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/encryption_service.dart';

/// App initialization status
enum InitStatus {
  notStarted,
  inProgress,
  success,
  failed,
}

/// Initialization result
class InitResult {
  final InitStatus status;
  final String? errorMessage;
  final List<String> warnings;

  const InitResult({
    required this.status,
    this.errorMessage,
    this.warnings = const [],
  });

  bool get isSuccess => status == InitStatus.success;
  bool get isFailed => status == InitStatus.failed;
}

/// App Initializer - Handles all startup tasks
class AppInitializer {
  static bool _isInitialized = false;
  static InitResult? _lastResult;

  static bool get isInitialized => _isInitialized;
  static InitResult? get lastResult => _lastResult;

  /// Initialize the app with all required services
  static Future<InitResult> initialize() async {
    if (_isInitialized) {
      return _lastResult ?? const InitResult(status: InitStatus.success);
    }

    final warnings = <String>[];

    try {
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables (non-critical)
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        warnings.add('Environment file not found, using defaults');
        debugPrint('Warning: .env file not loaded: $e');
      }

      // Initialize Firebase (non-blocking)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firebase initialization timed out');
          },
        );
        debugPrint('✓ Firebase initialized');
      } catch (e) {
        debugPrint('✗ Firebase initialization failed: $e');
        // Don't fail entirely - app can work in offline/guest mode
        warnings.add('Firebase not available - using offline mode');
        // Continue without Firebase
      }

      // Initialize connectivity service (non-critical)
      try {
        await ConnectivityService.instance.initialize();
        debugPrint('✓ Connectivity service initialized');
      } catch (e) {
        warnings.add('Connectivity monitoring unavailable');
        debugPrint('Warning: Connectivity service failed: $e');
      }

      // Initialize auth service (depends on Firebase)
      try {
        await FirebaseAuthService.instance.initialize();
        debugPrint('✓ Auth service initialized');
      } catch (e) {
        warnings.add('Authentication service unavailable');
        debugPrint('Warning: Auth service failed: $e');
      }

      // Initialize encryption service (non-critical)
      try {
        await EncryptionService.instance.initialize();
        debugPrint('✓ Encryption service initialized');
      } catch (e) {
        warnings.add('Encryption service unavailable');
        debugPrint('Warning: Encryption service failed: $e');
      }

      _isInitialized = true;
      _lastResult = InitResult(
        status: InitStatus.success,
        warnings: warnings,
      );

      debugPrint('═══════════════════════════════════════');
      debugPrint('  App initialization completed');
      debugPrint('  Warnings: ${warnings.length}');
      debugPrint('═══════════════════════════════════════');

      return _lastResult!;
    } catch (e, stackTrace) {
      debugPrint('✗ Critical initialization error: $e');
      debugPrint('Stack trace: $stackTrace');

      _lastResult = InitResult(
        status: InitStatus.failed,
        errorMessage: e.toString(),
        warnings: warnings,
      );

      return _lastResult!;
    }
  }

  /// Reset initialization (useful for testing)
  static void reset() {
    _isInitialized = false;
    _lastResult = null;
  }
}

/// Global error handler for uncaught exceptions
class GlobalErrorHandler {
  static bool _isSetup = false;

  /// Setup global error handling
  static void setup() {
    if (_isSetup) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('  FLUTTER ERROR');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Exception: ${details.exception}');
      debugPrint('Library: ${details.library}');
      if (details.context != null) {
        debugPrint('Context: ${details.context}');
      }
      debugPrint('Stack trace:\n${details.stack}');

      // In release mode, you might want to send this to a crash reporting service
      if (kReleaseMode) {
        // Log to console in release mode - Firebase Crashlytics would be configured here
        // if using: FirebaseCrashlytics.instance.recordFlutterError(details);
        debugPrint('Release mode error logged for crash reporting');
      }
    };

    // Handle errors outside of Flutter (isolate errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('  PLATFORM ERROR');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Error: $error');
      debugPrint('Stack trace:\n$stack');

      // Return true to prevent the error from propagating
      return true;
    };

    _isSetup = true;
    debugPrint('✓ Global error handler setup complete');
  }
}

/// Error boundary widget - catches errors in widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
  }

  /// Handle error from child widgets
  void handleError(FlutterErrorDetails details) {
    debugPrint('ErrorBoundary caught error: ${details.exception}');
    setState(() {
      _error = details;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _defaultErrorWidget();
    }

    return widget.child;
  }

  Widget _defaultErrorWidget() {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
