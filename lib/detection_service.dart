// detection_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/http_retry_service.dart';
import 'services/validation_service.dart';
import 'utils/app_log.dart';

class NormalizedDetection {
  final String label;
  final double confidence;
  final String? time;

  NormalizedDetection({
    required this.label,
    required this.confidence,
    this.time,
  });
}

class DetectionService {
  /// Extracts disease label from response using multiple field name variations
  /// Tries: label, disease, class, prediction, name, disease_name, etc.
  static String _extractLabel(Map<String, dynamic> response) {
    // Common field names for disease label (in order of priority)
    final labelFieldNames = [
      'label',
      'disease',
      'class',
      'prediction',
      'name',
      'disease_name',
      'disease_label',
      'detected_disease',
      'detected_class',
    ];

    for (var fieldName in labelFieldNames) {
      if (response.containsKey(fieldName) && response[fieldName] != null) {
        final value = response[fieldName];
        if (value is String && value.isNotEmpty) {
          appLog('✅ Found disease label in field "$fieldName": $value');
          return value;
        }
      }
    }

    // If no standard field found, log the full response for debugging
    appLog('⚠️ Could not find disease label. Response keys: ${response.keys}');
    appLog('📋 Full response: $response');
    return '';
  }

  /// Extracts confidence score from response using multiple field name variations
  static double _extractConfidence(Map<String, dynamic> response) {
    // Common field names for confidence score
    final confidenceFieldNames = [
      'confidence',
      'score',
      'confidence_score',
      'accuracy',
      'probability',
      'prob',
      'certainty',
    ];

    for (var fieldName in confidenceFieldNames) {
      if (response.containsKey(fieldName) && response[fieldName] != null) {
        try {
          final value = response[fieldName];
          final score = value is double ? value : double.tryParse(value.toString());

          if (score != null && score >= 0.0 && score <= 1.0) {
            appLog('✅ Found confidence in field "$fieldName": $score');
            return score;
          }
        } catch (e) {
          continue;
        }
      }
    }

    appLog('⚠️ Could not find valid confidence score');
    return 0.0;
  }

  /// Extracts timestamp from response
  static String? _extractTimestamp(Map<String, dynamic> response) {
    final timestampFieldNames = [
      'timestamp',
      'time',
      'detected_at',
      'detection_time',
      'created_at',
      'date',
    ];

    for (var fieldName in timestampFieldNames) {
      if (response.containsKey(fieldName) && response[fieldName] != null) {
        final value = response[fieldName];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  static Future<List<NormalizedDetection>> fetchDetections() async {
    try {
      // Get detection server URL from environment variables
      final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ??
          'http://172.20.10.3:5000';

      appLog('🔍 Fetching detection from: $serverUrl/latest_detection');

      // ✅ Use very aggressive timeout for fast fail-over
      final response = await HttpRetryService.get(
        Uri.parse("$serverUrl/latest_detection"),
      ).timeout(const Duration(seconds: 3)); // Total timeout: 3 seconds max

      if (response.statusCode != 200) {
        appLog('❌ Server error: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);
      appLog('📥 Raw response: $decoded');

      // Some backends wrap payloads (status/data), others return direct list/map.
      dynamic payload = decoded;
      if (decoded is Map<String, dynamic>) {
        if (decoded["status"] != null && decoded["status"] != "ok") {
          appLog('ℹ️ No detection data available');
          return [];
        }
        payload = decoded['detections'] ?? decoded['data'] ?? decoded;
      }

      // Normalize to a List<Map<String, dynamic>>
      final List<Map<String, dynamic>> items;
      if (payload is List) {
        items = payload
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } else if (payload is Map<String, dynamic>) {
        items = [payload];
      } else {
        appLog('⚠️ Unexpected detection payload type: ${payload.runtimeType}');
        return [];
      }

      final results = <NormalizedDetection>[];

      for (final item in items) {
        // Extract raw values using flexible field names
        final rawLabel = _extractLabel(item);
        final rawConfidence = _extractConfidence(item);
        final rawTimestamp = _extractTimestamp(item);

        // Handle case where label is empty but confidence exists
        if (rawLabel.isEmpty && rawConfidence > 0.0) {
          appLog(
              '⚠️ ISSUE: Confidence detected ($rawConfidence) but label is empty!');
          appLog('📋 Item structure: ${item.keys}');
        }

        // ✅ Validate response with extracted values
        final validationInput = {
          'label': rawLabel,
          'confidence': rawConfidence,
          'timestamp': rawTimestamp,
        };

        final validation =
            ValidationService.validateDetectionResponse(validationInput);

        if (validation['errors'].isNotEmpty) {
          appLog('⚠️ Validation warnings: ${validation['errors']}');
        }

        results.add(
          NormalizedDetection(
            label: (validation['label'] as String?)?.isNotEmpty == true
                ? validation['label']
                : 'Unknown',
            confidence: (validation['confidence'] as double?) ?? 0.0,
            time: (validation['timestamp'] as String?) ?? "",
          ),
        );
      }

      appLog('✅ Detections processed: ${results.length}');
      return results;
    } catch (e) {
      appLog('❌ HTTP Fetch Error: $e');
      return [];
    }
  }
}

