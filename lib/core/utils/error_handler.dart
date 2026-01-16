import 'package:flutter/material.dart';

class ErrorHandler {
  static void logError(String context, dynamic error,
      [StackTrace? stackTrace]) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('ERROR in $context');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
    debugPrint('═══════════════════════════════════════');
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<T?> handleAsyncError<T>({
    required Future<T> Function() operation,
    required String context,
    T? defaultValue,
    Function(dynamic error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logError(context, e, stackTrace);
      if (onError != null) {
        onError(e);
      }
      return defaultValue;
    }
  }

  static T? handleSyncError<T>({
    required T Function() operation,
    required String context,
    T? defaultValue,
    Function(dynamic error)? onError,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      logError(context, e, stackTrace);
      if (onError != null) {
        onError(e);
      }
      return defaultValue;
    }
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
      }
      return _buildErrorWidget(details.exception);
    };
  }

  Widget _buildErrorWidget(Object error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(error);
    }

    return Material(
      child: Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }
    return widget.child;
  }
}
