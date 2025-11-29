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
You are an agriculture assistant AI. Analyze the detection result and provide:

1. A short explanation of the disease (2–3 sentences only).
2. Actionable recommendations in bullet points (4–6 bullets).
3. Keep the language simple and suitable for farmers.

Detection details:
Disease: ${detection.label}
Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%

Formatting rules:
- No long paragraphs.
- Give disease explanation first.
- Followed by bullet-point solutions.
- No introduction messages.
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
