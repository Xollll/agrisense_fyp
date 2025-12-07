// gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detection_service.dart';

class GeminiService {
  // Cache for hybrid recommendations
  // Key: disease combination + confidence levels (smart key)
  // Value: cached recommendation
  static final Map<String, String> _recommendationCache = {};
  
  // Track last processed disease combination for auto-detection
  static String? _lastCacheKey;

  // Single detection (kept for backward compatibility)
  static Future<String> generateGeminiRecommendation(
      NormalizedDetection detection) async {
    return generateMultipleRecommendation([detection], forceRefresh: false);
  }

  // Build smart cache key from disease combination + confidence levels
  // Rounded to 10% to allow minor confidence fluctuations without cache miss
  // This enables:
  // - Cache HIT: when same diseases + similar confidence
  // - Cache MISS: when diseases change OR confidence changes > 10%
  static String _buildSmartCacheKey(
      Map<String, int> uniqueDiseases,
      Map<String, double> highestConfidence) {
    final entries = uniqueDiseases.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Consistent ordering
    
    final keyParts = entries.map((e) {
      final confidence = highestConfidence[e.key] ?? 0.0;
      // Round confidence to nearest 10% (0.0, 0.1, 0.2, ... 1.0)
      // This prevents cache misses from tiny confidence fluctuations
      final confidenceRounded = (confidence * 10).round() / 10;
      return "${e.key}:${confidenceRounded.toStringAsFixed(1)}";
    }).toList();
    
    return keyParts.join("|");
  }

  // Multiple detections - combines all into ONE unified recommendation
  // [forceRefresh]: if true, ignore cache and always generate fresh recommendation
  static Future<String> generateMultipleRecommendation(
      List<NormalizedDetection> detections,
      {bool forceRefresh = false}) async {
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

      // Build smart cache key (includes disease names + rounded confidence)
      final smartCacheKey = _buildSmartCacheKey(uniqueDiseases, highestConfidence);
      
      // Determine if we should use cache or generate fresh recommendation
      bool shouldGenerateFresh = forceRefresh || // User explicitly requested refresh
                                 smartCacheKey != _lastCacheKey || // Disease/confidence changed
                                 !_recommendationCache.containsKey(smartCacheKey); // Not in cache
      
      // If cache hit and no force refresh: return cached recommendation
      if (!shouldGenerateFresh && _recommendationCache.containsKey(smartCacheKey)) {
        print("✓ Cache HIT: Using cached recommendation for [$smartCacheKey]");
        _lastCacheKey = smartCacheKey;
        return _recommendationCache[smartCacheKey]!;
      }
      
      // Cache MISS or FORCE REFRESH: Generate fresh recommendation
      print("⚠ Cache MISS or FORCE REFRESH: Generating new recommendation");
      print("   Current key: $smartCacheKey");
      print("   Last key: $_lastCacheKey");
      
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
        final recommendation = json["candidates"][0]["content"]["parts"][0]["text"];
        
        // Store in cache for future use
        _recommendationCache[smartCacheKey] = recommendation;
        _lastCacheKey = smartCacheKey;
        
        print("✓ Recommendation cached for key: $smartCacheKey");
        
        return recommendation;
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
