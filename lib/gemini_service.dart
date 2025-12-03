// gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detection_service.dart';

class GeminiService {
  static Future<String> generateGeminiRecommendation(
      NormalizedDetection detection) async {
    try {
      final apiKey = "AIzaSyC2Xk6A_6A6IkxhKvfeo-0osIlWZdUCojU";
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
      );

      final prompt = """
Detection: ${detection.label}
Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%

Briefly explain the disease (1–2 sentences) and give actionable recommendations in bullets.
""";

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        print("Gemini API Error: ${response.body}");
        return "Error generating recommendation.";
      }
    } catch (e) {
      print("Gemini Exception: $e");
      return "Error generating recommendation.";
    }
  }
}
