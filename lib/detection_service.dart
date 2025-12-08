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
  static Future<List<NormalizedDetection>> fetchDetections() async {
    try {
      // Get detection server URL from environment variables
      final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';

      // ✅ Use retry service with timeout
      final response = await HttpRetryService.get(
        Uri.parse("$serverUrl/latest_detection"),
      ).timeout(NetworkConfig.detectionFetchTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "no_data") {
          return [];
        }

        // ✅ Validate response
        final validation = ValidationService.validateDetectionResponse(decoded);

        if (validation['errors'].isNotEmpty) {
          print('⚠️ Validation errors: ${validation['errors']}');
        }

        final detection = NormalizedDetection(
          label: validation['label'] ?? "Unknown",
          confidence: validation['confidence'] ?? 0.0,
          time: validation['timestamp'] ?? "",
        );

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

