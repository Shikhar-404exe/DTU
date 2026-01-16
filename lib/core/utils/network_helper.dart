import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkHelper {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static Future<http.Response> getWithRetry(
    String url, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
    int retries = maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < retries) {
      try {
        debugPrint(
            '📡 GET request to: $url (attempt ${attempts + 1}/$retries)');

        final response =
            await http.get(Uri.parse(url), headers: headers).timeout(timeout);

        debugPrint('✓ Response status: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode >= 500 && attempts < retries - 1) {
          debugPrint('⚠ Server error ${response.statusCode}, retrying...');
          await Future.delayed(retryDelay);
          attempts++;
          continue;
        }

        return response;
      } on TimeoutException {
        debugPrint('⏱ Request timeout (attempt ${attempts + 1}/$retries)');
        if (attempts >= retries - 1) rethrow;
      } catch (e) {
        debugPrint('❌ Request error: $e');
        if (attempts >= retries - 1) rethrow;
      }

      attempts++;
      await Future.delayed(retryDelay);
    }

    throw Exception('Failed after $retries attempts');
  }

  static Future<http.Response> postWithRetry(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = defaultTimeout,
    int retries = maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < retries) {
      try {
        debugPrint(
            '📤 POST request to: $url (attempt ${attempts + 1}/$retries)');

        final response = await http
            .post(
              Uri.parse(url),
              headers: headers ?? {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);

        debugPrint('✓ Response status: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode >= 500 && attempts < retries - 1) {
          debugPrint('⚠ Server error ${response.statusCode}, retrying...');
          await Future.delayed(retryDelay);
          attempts++;
          continue;
        }

        return response;
      } on TimeoutException {
        debugPrint('⏱ Request timeout (attempt ${attempts + 1}/$retries)');
        if (attempts >= retries - 1) rethrow;
      } catch (e) {
        debugPrint('❌ Request error: $e');
        if (attempts >= retries - 1) rethrow;
      }

      attempts++;
      await Future.delayed(retryDelay);
    }

    throw Exception('Failed after $retries attempts');
  }

  static Future<bool> checkBackendHealth(String backendUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }

  static String parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
    } catch (e) {
      debugPrint('Failed to parse error message: $e');
    }

    switch (response.statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Request failed with status ${response.statusCode}';
    }
  }

  static Map<String, dynamic>? safeJsonDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }
}
