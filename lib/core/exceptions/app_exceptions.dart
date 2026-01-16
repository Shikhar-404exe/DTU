/// Enterprise-level exception handling
/// Provides structured error types for the entire application
library;

import 'package:flutter/foundation.dart';

/// Base exception for all app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($code): $message';

  /// Log the exception for debugging
  void log() {
    debugPrint('[$runtimeType] $code: $message');
    if (originalError != null) {
      debugPrint('  Original error: $originalError');
    }
    if (stackTrace != null) {
      debugPrint('  Stack trace: $stackTrace');
    }
  }
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  // Common auth error codes
  static const String invalidEmail = 'invalid-email';
  static const String userDisabled = 'user-disabled';
  static const String userNotFound = 'user-not-found';
  static const String wrongPassword = 'wrong-password';
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String weakPassword = 'weak-password';
  static const String operationNotAllowed = 'operation-not-allowed';
  static const String tooManyRequests = 'too-many-requests';
  static const String networkError = 'network-request-failed';
  static const String unknown = 'unknown';

  /// Get user-friendly message based on error code
  String get userFriendlyMessage {
    switch (code) {
      case invalidEmail:
        return 'Please enter a valid email address.';
      case userDisabled:
        return 'This account has been disabled. Please contact support.';
      case userNotFound:
        return 'No account found with this email. Please sign up.';
      case wrongPassword:
        return 'Incorrect password. Please try again.';
      case emailAlreadyInUse:
        return 'An account already exists with this email.';
      case weakPassword:
        return 'Password is too weak. Use at least 6 characters.';
      case operationNotAllowed:
        return 'This sign-in method is not enabled.';
      case tooManyRequests:
        return 'Too many attempts. Please try again later.';
      case networkError:
        return 'Network error. Please check your connection.';
      default:
        return message.isNotEmpty
            ? message
            : 'An authentication error occurred.';
    }
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  final int? statusCode;
  final bool isTimeout;
  final bool isOffline;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
    this.isTimeout = false,
    this.isOffline = false,
  });

  /// Get user-friendly message
  String get userFriendlyMessage {
    if (isOffline) {
      return 'You appear to be offline. Please check your internet connection.';
    }
    if (isTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (statusCode != null) {
      if (statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }
      if (statusCode == 404) {
        return 'Resource not found.';
      }
      if (statusCode == 403) {
        return 'Access denied.';
      }
      if (statusCode == 401) {
        return 'Session expired. Please log in again.';
      }
    }
    return message.isNotEmpty ? message : 'A network error occurred.';
  }
}

/// Storage/Cache related exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  String get userFriendlyMessage {
    return 'Unable to save data. Please try again.';
  }
}

/// Validation related exceptions
class ValidationException extends AppException {
  final String? field;

  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.field,
  });

  String get userFriendlyMessage {
    if (field != null) {
      return 'Invalid $field: $message';
    }
    return message;
  }
}

/// File operation exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  String get userFriendlyMessage {
    return 'File operation failed. Please try again.';
  }
}

/// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) => Result._(data: data, isSuccess: true);

  factory Result.failure(AppException error) =>
      Result._(error: error, isSuccess: false);

  /// Map the result to another type
  Result<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      return Result.success(mapper(data as T));
    }
    return Result.failure(error!);
  }

  /// Get data or throw
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data as T;
    }
    throw error ?? const AuthException(message: 'Unknown error');
  }

  /// Get data or default value
  T getOrElse(T defaultValue) {
    if (isSuccess && data != null) {
      return data as T;
    }
    return defaultValue;
  }

  /// Execute callback on success
  void onSuccess(void Function(T) callback) {
    if (isSuccess && data != null) {
      callback(data as T);
    }
  }

  /// Execute callback on failure
  void onFailure(void Function(AppException) callback) {
    if (!isSuccess && error != null) {
      callback(error!);
    }
  }
}
