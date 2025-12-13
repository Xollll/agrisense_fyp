// detection_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/http_retry_service.dart';
import 'services/validation_service.dart';
import 'config/network_config.dart';

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
          print('✅ Found disease label in field "$fieldName": $value');
          return value;
        }
      }
    }

    // If no standard field found, log the full response for debugging
    print('⚠️ Could not find disease label. Response keys: ${response.keys}');
    print('📋 Full response: $response');
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
          final score = value is double
              ? value
              : double.tryParse(value.toString());
          
          if (score != null && score >= 0.0 && score <= 1.0) {
            print('✅ Found confidence in field "$fieldName": $score');
            return score;
          }
        } catch (e) {
          continue;
        }
      }
    }

    print('⚠️ Could not find valid confidence score');
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
      final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';

      print('🔍 Fetching detection from: $serverUrl/latest_detection');

      // ✅ Use retry service with timeout
      final response = await HttpRetryService.get(
        Uri.parse("$serverUrl/latest_detection"),
      ).timeout(NetworkConfig.detectionFetchTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        print('📥 Raw response: $decoded');

        if (decoded["status"] != "ok") {
  print('ℹ️ No detection data available');
  return [];
}


        // Extract raw values using flexible field names
        final rawLabel = _extractLabel(decoded);
        final rawConfidence = _extractConfidence(decoded);
        final rawTimestamp = _extractTimestamp(decoded);

        // Handle case where label is empty but confidence exists
        if (rawLabel.isEmpty && rawConfidence > 0.0) {
          print('⚠️ ISSUE: Confidence detected ($rawConfidence) but label is empty!');
          print('📋 Response structure: ${decoded.keys}');
          // Still validate the confidence even with empty label
        }

        // ✅ Validate response with extracted values
        final validationInput = {
          'label': rawLabel,
          'confidence': rawConfidence,
          'timestamp': rawTimestamp,
        };
        
        final validation = ValidationService.validateDetectionResponse(validationInput);

        if (validation['errors'].isNotEmpty) {
          print('⚠️ Validation warnings: ${validation['errors']}');
        }

        final detection = NormalizedDetection(
          label: validation['label'] ?? "Unknown",
          confidence: validation['confidence'] ?? 0.0,
          time: validation['timestamp'] ?? "",
        );

        print('✅ Detection processed: Label=${detection.label}, Confidence=${detection.confidence}');
        return [detection];
      } else {
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print("❌ HTTP Fetch Error: $e");
    }

    return [];
  }
}

