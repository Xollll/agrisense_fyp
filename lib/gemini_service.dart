// gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detection_service.dart';

class GeminiService {
  // Single detection (kept for backward compatibility)
  static Future<String> generateGeminiRecommendation(
      NormalizedDetection detection) async {
    return generateMultipleRecommendation([detection]);
  }

  // Multiple detections - combines all into ONE unified recommendation
  static Future<String> generateMultipleRecommendation(
      List<NormalizedDetection> detections) async {
    try {
      // Filter out "healthy" detections
      final diseaseDetections = detections
          .where((d) => d.label.toLowerCase() != "healthy")
          .toList();

      // If no diseases, return healthy message
      if (diseaseDetections.isEmpty) {
        return "All leaves appear healthy. No action needed. Continue regular maintenance.";
      }

      // Get unique disease names and their counts
      final Map<String, int> uniqueDiseases = {};
      final Map<String, double> highestConfidence = {};

      for (var detection in diseaseDetections) {
        final label = detection.label.toLowerCase();
        uniqueDiseases[label] = (uniqueDiseases[label] ?? 0) + 1;
        
        // Store highest confidence for each disease
        if (!highestConfidence.containsKey(label) ||
            detection.confidence > highestConfidence[label]!) {
          highestConfidence[label] = detection.confidence;
        }
      }

      // Build disease list for prompt
      final diseaseList = uniqueDiseases.entries
          .map((e) =>
              "${e.key} (${e.value} detected, ${(highestConfidence[e.key]! * 100).toStringAsFixed(0)}% confidence)")
          .join("\n");

      final apiKey = "AIzaSyC2Xk6A_6A6IkxhKvfeo-0osIlWZdUCojU";
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
      );

      final prompt = """You are an agricultural AI assistant for a chili farm health monitoring system.

Detections found:
$diseaseList

Your task:
1. Combine detection results into UNIQUE disease categories.
2. Ignore "healthy" detections.
3. Generate ONE unified recommendation response for all diseases found.
4. Keep your explanation simple, short, and actionable for small-scale farmers.

Response format:

Detected Issues:
- List all unique diseases found

Explanation:
- 1–2 very short sentences describing what these diseases mean

Recommended Actions:
- Bullet points with clear, practical steps to fix the issues
- Use simple farming language
- Focus on affordable solutions small farmers can use

Keep it brief and practical.""";

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
