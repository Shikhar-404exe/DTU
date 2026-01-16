/// Secure HTTP Client Service
/// Provides security-hardened HTTP requests with validation
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/security_helper.dart';

/// Secure HTTP client with built-in security measures
class SecureHttpClient {
  SecureHttpClient._();

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Whitelist of allowed domains (configure per environment)
  static final List<String> _allowedDomains = [
    'localhost',
    '127.0.0.1',
    '192.168.', // Local network
    '172.17.', // Local network
    '10.', // Local network
    'api.gemini.google.com',
    'generativelanguage.googleapis.com',
    'firebase.googleapis.com',
    'firebaseapp.com',
  ];

  /// Validate URL is safe and from allowed domain
  static bool _isUrlAllowed(String url) {
    try {
      final uri = Uri.parse(url);

      // Must be http or https
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        SecurityHelper.logSecurityEvent('Blocked non-HTTP scheme', details: {
          'scheme': uri.scheme,
          'url_host': uri.host,
        });
        return false;
      }

      // Check if domain is in whitelist
      final host = uri.host.toLowerCase();

      // Allow localhost and IPs for development
      if (kDebugMode) {
        // More permissive in debug mode for local testing
        return true;
      }

      // Production: strict domain whitelist
      for (var allowed in _allowedDomains) {
        if (host.contains(allowed)) {
          return true;
        }
      }

      SecurityHelper.logSecurityEvent('Blocked unauthorized domain', details: {
        'host': host,
        'url': SecurityHelper.maskSensitiveData(url, visibleChars: 20),
      });
      return false;
    } catch (e) {
      debugPrint('URL validation error: $e');
      return false;
    }
  }

  /// Sanitize request body
  static Map<String, dynamic> _sanitizeBody(Map<String, dynamic> body) {
    final sanitized = <String, dynamic>{};

    for (var entry in body.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        // Check for SQL injection
        if (SecurityHelper.containsSQLInjection(value)) {
          SecurityHelper.logSecurityEvent('SQL injection attempt blocked', details: {
            'field': key,
          });
          continue; // Skip this field
        }

        // Sanitize input
        sanitized[key] = SecurityHelper.sanitizeInput(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// POST request with security validation
  static Future<http.Response> post({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration timeout = _defaultTimeout,
    bool sanitizeBody = true,
    int retries = 0,
  }) async {
    // Validate URL
    if (!_isUrlAllowed(url)) {
      throw SecurityException('URL not allowed: $url');
    }

    // Sanitize body if enabled
    final sanitizedBody =
        sanitizeBody && body != null ? _sanitizeBody(body) : body;

    // Add default headers
    final secureHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'VidyarthiApp/1.0',
      ...?headers,
    };

    try {
      SecurityHelper.logSecurityEvent('HTTP POST', details: {
        'url': SecurityHelper.maskSensitiveData(url, visibleChars: 30),
        'has_body': sanitizedBody != null,
      });

      final response = await http
          .post(
            Uri.parse(url),
            headers: secureHeaders,
            body: sanitizedBody != null ? jsonEncode(sanitizedBody) : null,
          )
          .timeout(timeout);

      // Validate response
      _validateResponse(response);

      return response;
    } on SocketException catch (e) {
      // Network error - retry if configured
      if (retries < _maxRetries) {
        debugPrint('Network error, retrying (${retries + 1}/$_maxRetries)...');
        await Future.delayed(_retryDelay);
        return post(
          url: url,
          headers: headers,
          body: body,
          timeout: timeout,
          sanitizeBody: sanitizeBody,
          retries: retries + 1,
        );
      }

      SecurityHelper.logSecurityEvent('Network error after retries', details: {
        'error': e.message,
      });
      rethrow;
    } on http.ClientException catch (e) {
      SecurityHelper.logSecurityEvent('HTTP client error', details: {
        'error': e.message,
      });
      rethrow;
    } catch (e) {
      SecurityHelper.logSecurityEvent('Request error', details: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// GET request with security validation
  static Future<http.Response> get({
    required String url,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
    int retries = 0,
  }) async {
    // Validate URL
    if (!_isUrlAllowed(url)) {
      throw SecurityException('URL not allowed: $url');
    }

    // Add default headers
    final secureHeaders = {
      'Accept': 'application/json',
      'User-Agent': 'VidyarthiApp/1.0',
      ...?headers,
    };

    try {
      SecurityHelper.logSecurityEvent('HTTP GET', details: {
        'url': SecurityHelper.maskSensitiveData(url, visibleChars: 30),
      });

      final response = await http
          .get(
            Uri.parse(url),
            headers: secureHeaders,
          )
          .timeout(timeout);

      // Validate response
      _validateResponse(response);

      return response;
    } on SocketException catch (e) {
      // Network error - retry if configured
      if (retries < _maxRetries) {
        debugPrint('Network error, retrying (${retries + 1}/$_maxRetries)...');
        await Future.delayed(_retryDelay);
        return get(
          url: url,
          headers: headers,
          timeout: timeout,
          retries: retries + 1,
        );
      }

      SecurityHelper.logSecurityEvent('Network error after retries', details: {
        'error': e.message,
      });
      rethrow;
    } catch (e) {
      SecurityHelper.logSecurityEvent('Request error', details: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Validate HTTP response for security issues
  static void _validateResponse(http.Response response) {
    // Check for suspicious response sizes
    if (response.body.length > 10 * 1024 * 1024) {
      // 10MB
      SecurityHelper.logSecurityEvent('Unusually large response', details: {
        'size_bytes': response.body.length,
        'status': response.statusCode,
      });
    }

    // Log non-success status codes
    if (response.statusCode >= 400) {
      SecurityHelper.logSecurityEvent('HTTP error response', details: {
        'status': response.statusCode,
        'body_preview': response.body.substring(
          0,
          response.body.length > 100 ? 100 : response.body.length,
        ),
      });
    }
  }

  /// Parse JSON response securely
  static Map<String, dynamic> parseJsonResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object');
      }

      return decoded;
    } on FormatException catch (e) {
      SecurityHelper.logSecurityEvent('JSON parse error', details: {
        'error': e.message,
        'body_preview': response.body.substring(
          0,
          response.body.length > 100 ? 100 : response.body.length,
        ),
      });
      rethrow;
    }
  }
}

/// Security exception
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

