import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/services/secure_http_client.dart';
import '../core/utils/security_helper.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 30);

  static String get baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      // Sanitize and validate inputs
      final sanitizedEmail = SecurityHelper.sanitizeInput(email);

      if (!SecurityHelper.isValidEmail(sanitizedEmail)) {
        throw Exception('Invalid email format');
      }

      if (SecurityHelper.containsSQLInjection(sanitizedEmail) ||
          SecurityHelper.containsSQLInjection(password)) {
        SecurityHelper.logSecurityEvent('Auth login injection attempt');
        throw Exception('Invalid input detected');
      }

      // Use secure HTTP client
      final res = await SecureHttpClient.post(
        url: '$baseUrl/auth/login',
        body: {'email': sanitizedEmail, 'password': password},
        timeout: _timeout,
      );

      if (res.statusCode == 200) {
        final decoded = SecureHttpClient.parseJsonResponse(res);
        return decoded;
      }
      throw Exception('Login failed: ${res.statusCode}');
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(
      String email, String password) async {
    try {
      // Sanitize and validate inputs
      final sanitizedEmail = SecurityHelper.sanitizeInput(email);

      if (!SecurityHelper.isValidEmail(sanitizedEmail)) {
        throw Exception('Invalid email format');
      }

      // Check password strength
      if (SecurityHelper.isWeakPassword(password)) {
        throw Exception('Password is too weak');
      }

      final strength = SecurityHelper.checkPasswordStrength(password);
      if (strength == PasswordStrength.weak) {
        throw Exception('Password is too weak. ${strength.description}');
      }

      if (SecurityHelper.containsSQLInjection(sanitizedEmail) ||
          SecurityHelper.containsSQLInjection(password)) {
        SecurityHelper.logSecurityEvent('Auth registration injection attempt');
        throw Exception('Invalid input detected');
      }

      // Use secure HTTP client
      final res = await SecureHttpClient.post(
        url: '$baseUrl/auth/register',
        body: {'email': sanitizedEmail, 'password': password},
        timeout: _timeout,
      );

      if (res.statusCode == 200) {
        final decoded = SecureHttpClient.parseJsonResponse(res);
        return decoded;
      }
      throw Exception('Registration failed: ${res.statusCode}');
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }
}
