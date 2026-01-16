

library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

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

    final originalOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {

      if (_isOurError(details)) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorDetails = details;
          });
        }
        widget.onError?.call(details);
      } else {

        originalOnError?.call(details);
      }
    };
  }

  bool _isOurError(FlutterErrorDetails details) {

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

extension ContextExtensions on BuildContext {

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
