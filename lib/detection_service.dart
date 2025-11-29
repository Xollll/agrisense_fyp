// detection_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final response = await http.get(
        Uri.parse("http://192.168.8.76:1880/latest_detection"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "no_data") {
          return [];
        }

        final detection = NormalizedDetection(
          label: decoded["message"] ?? "Unknown",
          confidence: 1.0,
          time: decoded["timestamp"] ?? "",
        );

        return [detection];
      }
    } catch (e) {
      print("HTTP Fetch Error: $e");
    }

    return [];
  }
}
