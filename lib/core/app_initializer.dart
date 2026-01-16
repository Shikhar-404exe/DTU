

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
import '../services/fcm_service.dart';

enum InitStatus {
  notStarted,
  inProgress,
  success,
  failed,
}

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

class AppInitializer {
  static bool _isInitialized = false;
  static InitResult? _lastResult;

  static bool get isInitialized => _isInitialized;
  static InitResult? get lastResult => _lastResult;

  static Future<InitResult> initialize() async {
    if (_isInitialized) {
      return _lastResult ?? const InitResult(status: InitStatus.success);
    }

    final warnings = <String>[];

    try {

      WidgetsFlutterBinding.ensureInitialized();

      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        warnings.add('Environment file not found, using defaults');
        debugPrint('Warning: .env file not loaded: $e');
      }

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

        warnings.add('Firebase not available - using offline mode');

      }

      try {
        await ConnectivityService.instance.initialize();
        debugPrint('✓ Connectivity service initialized');
      } catch (e) {
        warnings.add('Connectivity monitoring unavailable');
        debugPrint('Warning: Connectivity service failed: $e');
      }

      try {
        await FirebaseAuthService.instance.initialize();
        debugPrint('✓ Auth service initialized');
      } catch (e) {
        warnings.add('Authentication service unavailable');
        debugPrint('Warning: Auth service failed: $e');
      }

      try {
        await EncryptionService.instance.initialize();
        debugPrint('✓ Encryption service initialized');
      } catch (e) {
        warnings.add('Encryption service unavailable');
        debugPrint('Warning: Encryption service failed: $e');
      }

      try {
        await FCMService().initialize();
        debugPrint('✓ FCM service initialized');

      } catch (e) {
        warnings.add('Push notifications unavailable');
        debugPrint('Warning: FCM service failed: $e');
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

  static void reset() {
    _isInitialized = false;
    _lastResult = null;
  }
}

class GlobalErrorHandler {
  static bool _isSetup = false;

  static void setup() {
    if (_isSetup) return;

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

      if (kReleaseMode) {

        debugPrint('Release mode error logged for crash reporting');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('  PLATFORM ERROR');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Error: $error');
      debugPrint('Stack trace:\n$stack');

      return true;
    };

    _isSetup = true;
    debugPrint('✓ Global error handler setup complete');
  }
}

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
