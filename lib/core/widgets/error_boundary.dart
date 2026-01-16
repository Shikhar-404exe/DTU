/// Enterprise-level Error Boundary Widget
/// Catches and gracefully handles widget-level errors to prevent app crashes
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Error boundary widget that catches errors in its child tree
/// and displays a fallback UI instead of crashing the app
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Store original error handler
    final originalOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if error is in our widget tree
      if (_isOurError(details)) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorDetails = details;
          });
        }
        widget.onError?.call(details);
      } else {
        // Pass to original handler
        originalOnError?.call(details);
      }
    };
  }

  bool _isOurError(FlutterErrorDetails details) {
    // Simple heuristic - could be enhanced
    return details.context
            ?.toString()
            .contains(widget.child.runtimeType.toString()) ??
        false;
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ??
          _DefaultErrorWidget(
            errorDetails: _errorDetails,
            onRetry: _retry,
          );
    }
    return widget.child;
  }
}

/// Default error widget shown when an error occurs
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    this.errorDetails,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An error occurred while loading this section',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (kDebugMode && errorDetails != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.shade900.withAlpha(100)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.red.shade700 : Colors.red.shade200,
                  ),
                ),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  errorDetails!.exceptionAsString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Safe area wrapper that handles errors gracefully
class SafeArea2 extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimumPadding;

  const SafeArea2({
    super.key,
    required this.child,
    this.minimumPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return SafeArea(
        minimum: minimumPadding,
        child: child,
      );
    } catch (e) {
      debugPrint('SafeArea2 error: $e');
      return Padding(
        padding: minimumPadding,
        child: child,
      );
    }
  }
}

/// Async operation wrapper with loading and error states
class AsyncBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? onError;

  const AsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        if (snapshot.hasError) {
          final error = snapshot.error!;
          final stackTrace = snapshot.stackTrace;

          if (onError != null) {
            return onError!(error, stackTrace);
          }

          return _DefaultErrorWidget(
            errorDetails: FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
            ),
          );
        }

        if (snapshot.hasData) {
          return builder(snapshot.data as T);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Stream wrapper with loading and error states
class StreamBuilder2<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? onError;

  const StreamBuilder2({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.loading,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return loading ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        if (snapshot.hasError) {
          final error = snapshot.error!;
          final stackTrace = snapshot.stackTrace;

          if (onError != null) {
            return onError!(error, stackTrace);
          }

          return _DefaultErrorWidget(
            errorDetails: FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
            ),
          );
        }

        if (snapshot.hasData) {
          return builder(snapshot.data as T);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Extension methods for easier error handling
extension ContextExtensions on BuildContext {
  /// Show a snackbar with error message
  void showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: duration ?? AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(this).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a snackbar with success message
  void showSuccessSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: duration ?? AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a snackbar with info message
  void showInfoSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        duration: duration ?? AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
