// gemini_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/http_retry_service.dart';
import 'services/validation_service.dart';
import 'detection_service.dart';
import 'config/network_config.dart';
import 'utils/app_log.dart';

class GeminiService {
  // Cache for hybrid recommendations
  // Key: disease combination + confidence levels (smart key)
  // Value: cached recommendation
  static final Map<String, String> _recommendationCache = {};

  // Track last processed disease combination for auto-detection
  static String? _lastCacheKey;

  // ✅ ANTI-REDUNDANCY: Track in-flight requests to prevent duplicate API calls
  // If same cache key already being fetched, return existing future instead of making new request
  static final Map<String, Future<String>> _pendingRequests = {};

  // ✅ RATE LIMITING: Prevent same disease from requesting too frequently
  // Minimum interval between API calls for same disease
  static const Duration _minRequestInterval = Duration(minutes: 5);
  static final Map<String, DateTime> _lastRequestTime = {};

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
  static String _buildSmartCacheKey(Map<String, int> uniqueDiseases,
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
      final smartCacheKey =
          _buildSmartCacheKey(uniqueDiseases, highestConfidence);

      // ✅ ANTI-REDUNDANCY: Check if request is already in-flight
      // If same cache key is being fetched, return existing future
      // This prevents duplicate API calls when multiple widgets request simultaneously
      if (_pendingRequests.containsKey(smartCacheKey)) {
        appLog('Request already in-flight for [$smartCacheKey], waiting for result...');
        return _pendingRequests[smartCacheKey]!;
      }

      // ✅ RATE LIMITING: Check if we're making requests too frequently for same disease
      // Minimum interval is 5 minutes between API calls for same disease combination
      if (!forceRefresh && _lastRequestTime.containsKey(smartCacheKey)) {
        final timeSinceLastRequest =
            DateTime.now().difference(_lastRequestTime[smartCacheKey]!);
        if (timeSinceLastRequest < _minRequestInterval) {
          // Within cooldown period - return cached result if available
          if (_recommendationCache.containsKey(smartCacheKey)) {
            appLog('Cache HIT (Rate Limited): Using cached recommendation for [$smartCacheKey]');
            appLog('Time since last request: ${timeSinceLastRequest.inSeconds}s (min: ${_minRequestInterval.inSeconds}s)');
            _lastCacheKey = smartCacheKey;
            return _recommendationCache[smartCacheKey]!;
          }
        }
      }

      // Determine if we should use cache or generate fresh recommendation
      bool shouldGenerateFresh = forceRefresh || // User explicitly requested refresh
          smartCacheKey != _lastCacheKey || // Disease/confidence changed
          !_recommendationCache.containsKey(smartCacheKey); // Not in cache

      // If cache hit and no force refresh: return cached recommendation
      if (!shouldGenerateFresh &&
          _recommendationCache.containsKey(smartCacheKey)) {
        appLog('Cache HIT: Using cached recommendation for [$smartCacheKey]');
        _lastCacheKey = smartCacheKey;
        return _recommendationCache[smartCacheKey]!;
      }

      // Cache MISS or FORCE REFRESH: Generate fresh recommendation
      appLog('Cache MISS or FORCE REFRESH: Making Gemini API call');
      appLog('Current key: $smartCacheKey');
      appLog('Last key: $_lastCacheKey');

      // Build disease list for prompt
      final diseaseList = uniqueDiseases.entries
          .map((e) =>
              "${e.key} (${e.value} detected, ${(highestConfidence[e.key]! * 100).toStringAsFixed(0)}% confidence)")
          .join("\n");

      // Get API key from environment variables
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }

      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
      );

      final prompt = """You are AgriSense, an agricultural assistant for chili farmers.

Input:
$diseaseList

TASK
Write a short recommendation.

OUTPUT FORMAT (follow exactly)
Diseases: <comma-separated disease names>
Why: <1 short sentence>
Actions:
- <action 1>
- <action 2>
- <optional action 3>

RULES
- Use ONLY the diseases in Input. Ignore healthy.
- Keep total under 70 words.
- Use simple farming language.
- Actions must be practical and specific (what to do now).
- No extra headings, no emojis, no disclaimers.
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

      // ✅ Create future for this request and mark it as pending
      // This prevents duplicate API calls if same request is made again
      final requestFuture = _makeApiRequest(url, body, smartCacheKey);
      _pendingRequests[smartCacheKey] = requestFuture;

      try {
        final result = await requestFuture;
        // ✅ Update rate limit timer after successful API call
        _lastRequestTime[smartCacheKey] = DateTime.now();
        return result;
      } finally {
        // ✅ Remove from pending requests once complete
        _pendingRequests.remove(smartCacheKey);
      }
    } catch (e) {
      appLog('Gemini Exception: $e');
      return "Error generating recommendation.";
    }
  }

  // ✅ Internal method to make actual API call
  // Separated from main logic to support deduplication
  static Future<String> _makeApiRequest(
    Uri url,
    String body,
    String smartCacheKey,
  ) async {
    // ✅ Use retry service with timeout
    final response = await HttpRetryService.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
      timeout: NetworkConfig.geminiRequestTimeout,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final recommendation =
          json["candidates"][0]["content"]["parts"][0]["text"];

      // ✅ Validate AI response before caching
      if (!ValidationService.isValidAIResponse(recommendation)) {
        appLog('AI response validation failed');
        return "Unable to generate valid recommendation. Please try again.";
      }

      final sanitized = ValidationService.sanitizeAIResponse(recommendation);

      // Store validated response in cache for future use
      _recommendationCache[smartCacheKey] = sanitized;
      _lastCacheKey = smartCacheKey;

      appLog('Recommendation cached for key: $smartCacheKey');

      return sanitized;
    } else {
      appLog('Gemini API Error: ${response.body}');
      return "Error generating recommendation.";
    }
  }
}

