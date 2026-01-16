

library;

import 'package:flutter/foundation.dart';

class SecurityHelper {
  SecurityHelper._();

  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    String sanitized = input
        .replaceAll(
            RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false),
            '');

    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');

    return sanitized.trim();
  }

  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialChars) strength++;

    if (strength >= 5) return PasswordStrength.strong;
    if (strength >= 3) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  static bool isWeakPassword(String password) {
    const weakPasswords = [
      '123456',
      'password',
      '123456789',
      '12345678',
      '12345',
      '1234567',
      '1234567890',
      'qwerty',
      'abc123',
      'password123',
      '111111',
      '123123',
      'admin',
      'letmein',
      'welcome',
    ];

    return weakPasswords.contains(password.toLowerCase());
  }

  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'unnamed_file';

    String sanitized = filename
        .replaceAll('..', '')
        .replaceAll('/', '')
        .replaceAll('\\', '')
        .replaceAll(':', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '');

    // Limit length
    if (sanitized.length > 255) {
      sanitized = sanitized.substring(0, 255);
    }

    return sanitized.trim();
  }

  /// Validate URL safety
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Only allow http and https schemes
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      // Prevent javascript: or data: URLs
      if (url.toLowerCase().startsWith('javascript:') ||
          url.toLowerCase().startsWith('data:')) {
        return false;
      }

      return uri.hasAuthority && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Rate limiting helper
  static final Map<String, DateTime> _rateLimitMap = {};

  static bool checkRateLimit(String key,
      {Duration cooldown = const Duration(seconds: 2)}) {
    final now = DateTime.now();

    if (_rateLimitMap.containsKey(key)) {
      final lastCall = _rateLimitMap[key]!;
      if (now.difference(lastCall) < cooldown) {
        return false; // Too soon, rate limited
      }
    }

    _rateLimitMap[key] = now;

    // Clean up old entries
    _rateLimitMap.removeWhere((k, v) => now.difference(v) > cooldown * 2);

    return true; // Allowed
  }

  /// Mask sensitive data for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }

    return data.substring(0, visibleChars) + '*' * (data.length - visibleChars);
  }

  /// Log security event
  static void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    if (kDebugMode) {
      debugPrint('🔒 Security Event: $event');
      if (details != null) {
        debugPrint('   Details: $details');
      }
    }
    // In production, send to security monitoring service
  }

  /// Validate phone number format (basic)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Should be 10-15 digits
    return RegExp(r'^\d{10,15}$').hasMatch(cleaned);
  }

  /// Check for SQL injection patterns
  static bool containsSQLInjection(String input) {
    final sqlPatterns = [
      r"'\s*OR\s*'1'\s*=\s*'1",
      r"'\s*OR\s*1\s*=\s*1",
      r"--",
      r";\s*DROP\s+TABLE",
      r";\s*DELETE\s+FROM",
      r"UNION\s+SELECT",
      r"<script",
    ];

    for (var pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        logSecurityEvent('SQL Injection attempt detected', details: {
          'pattern': pattern,
          'input_length': input.length,
        });
        return true;
      }
    }

    return false;
  }
}

/// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Password strength extension
extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return 'Too weak. Add uppercase, numbers, and symbols.';
      case PasswordStrength.medium:
        return 'Fair. Add more characters or symbols.';
      case PasswordStrength.strong:
        return 'Strong password!';
    }
  }
}

