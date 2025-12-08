// lib/services/http_retry_service.dart
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

/// HTTP client with automatic retry logic using exponential backoff
/// Handles network failures gracefully with automatic retries
class HttpRetryService {
  // Configuration
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(milliseconds: 500);
  static const double backoffMultiplier = 2.0;
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Performs GET request with retry logic
  /// Retries automatically on network failures
  /// Returns response or throws exception after all retries fail
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    int retries = maxRetries,
    Duration? delay,
  }) async {
    delay ??= initialDelay;

    try {
      print('🔄 GET $url (attempt ${maxRetries - retries + 1}/$maxRetries)');

      final response = await http.get(url, headers: headers).timeout(requestTimeout);

      // Success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success: ${response.statusCode}');
        return response;
      }

      // Server error (5xx) - retry
      if (response.statusCode >= 500) {
        print('⚠️ Server error ${response.statusCode}, retrying...');
        if (retries > 0) {
          await Future.delayed(delay);
          return get(
            url,
            headers: headers,
            retries: retries - 1,
            delay: Duration(
              milliseconds:
                  (delay.inMilliseconds * backoffMultiplier).toInt(),
            ),
          );
        }
      }

      return response;
    } on TimeoutException {
      print('⏱️ Timeout, retrying...');

      if (retries > 0) {
        await Future.delayed(delay);
        return get(
          url,
          headers: headers,
          retries: retries - 1,
          delay: Duration(
            milliseconds:
                (delay.inMilliseconds * backoffMultiplier).toInt(),
          ),
        );
      }

      rethrow;
    } catch (e) {
      print('❌ Network error: $e');

      if (retries > 0) {
        await Future.delayed(delay);
        return get(
          url,
          headers: headers,
          retries: retries - 1,
          delay: Duration(
            milliseconds:
                (delay.inMilliseconds * backoffMultiplier).toInt(),
          ),
        );
      }

      rethrow;
    }
  }

  /// Performs POST request with retry logic
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int retries = maxRetries,
    Duration? delay,
  }) async {
    delay ??= initialDelay;

    try {
      print('🔄 POST $url (attempt ${maxRetries - retries + 1}/$maxRetries)');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ).timeout(requestTimeout);

      // Success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success: ${response.statusCode}');
        return response;
      }

      // Server error (5xx) - retry
      if (response.statusCode >= 500) {
        print('⚠️ Server error ${response.statusCode}, retrying...');
        if (retries > 0) {
          await Future.delayed(delay);
          return post(
            url,
            headers: headers,
            body: body,
            encoding: encoding,
            retries: retries - 1,
            delay: Duration(
              milliseconds:
                  (delay.inMilliseconds * backoffMultiplier).toInt(),
            ),
          );
        }
      }

      return response;
    } on TimeoutException {
      print('⏱️ Timeout, retrying...');

      if (retries > 0) {
        await Future.delayed(delay);
        return post(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          retries: retries - 1,
          delay: Duration(
            milliseconds:
                (delay.inMilliseconds * backoffMultiplier).toInt(),
          ),
        );
      }

      rethrow;
    } catch (e) {
      print('❌ Network error: $e');

      if (retries > 0) {
        await Future.delayed(delay);
        return post(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          retries: retries - 1,
          delay: Duration(
            milliseconds:
                (delay.inMilliseconds * backoffMultiplier).toInt(),
          ),
        );
      }

      rethrow;
    }
  }

  /// Retry backoff calculation: 500ms, 1s, 2s, 4s...
  static Duration calculateBackoff(int failureCount) {
    final milliseconds = initialDelay.inMilliseconds *
        (backoffMultiplier.toInt() ^ failureCount);
    return Duration(milliseconds: milliseconds);
  }
}
