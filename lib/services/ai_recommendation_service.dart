// ai_recommendation_service.dart
// 
// Smart Hybrid AI Recommendation System
// =====================================
// Implements intelligent triggering to prevent unnecessary API quota usage while
// ensuring users get timely, helpful recommendations.
//
// Key Features:
// - Automatic triggers only on NEW disease detection (not confidence changes)
// - Cooldown period between auto-generation (default: 10 minutes)
// - Smart caching by disease label
// - Manual "Ask AI Again" trigger for user control
// - Confidence threshold filtering (minimum 0.5)

import 'dart:async';
import '../detection_service.dart';
// ✅ REMOVED: No longer needed since service doesn't call Gemini API
// import '../gemini_service.dart';

class AIRecommendationTriggerEvent {
  final String disease;
  final double confidence;
  final DateTime timestamp;
  final AITriggerReason reason;

  AIRecommendationTriggerEvent({
    required this.disease,
    required this.confidence,
    required this.timestamp,
    required this.reason,
  });

  @override
  String toString() =>
      '🤖 AITrigger: $disease (${(confidence * 100).toStringAsFixed(0)}%) - $reason';
}

enum AITriggerReason {
  newDiseaseDetected, // ✅ Auto-trigger: First time seeing this disease
  confidenceRecovery, // ✅ Auto-trigger: Disease returned after being "healthy"
  manualUserRequest, // 🔄 Manual: User clicked "Ask AI Again"
  skippedConfidenceOnly, // ⏭️ Skip: Same disease, confidence changed
  skippedLowConfidence, // ⏭️ Skip: Confidence below threshold
  skippedCooldown, // ⏭️ Skip: Within cooldown period
}

class AIRecommendation {
  final String diseaseLabel;
  final String recommendation;
  final DateTime generatedAt;
  final double confidence;

  AIRecommendation({
    required this.diseaseLabel,
    required this.recommendation,
    required this.generatedAt,
    required this.confidence,
  });
}

class AIRecommendationService {
  // ========== CONFIGURATION ==========
  // Cooldown period between auto-generation for the same disease
  static const Duration autoCooldownDuration = Duration(minutes: 10);

  // Minimum confidence threshold to trigger AI
  static const double confidenceThreshold = 0.5;

  // ========== CACHE & STATE ==========
  // Cache: disease_label -> AIRecommendation
  static final Map<String, AIRecommendation> _recommendationCache = {};

  // Track last auto-trigger time for each disease to enforce cooldown
  // Key: disease_label, Value: DateTime of last auto-trigger
  static final Map<String, DateTime> _lastAutoTriggerTime = {};

  // Current disease state (to detect changes)
  static String? _lastProcessedDisease;
  static double _lastProcessedConfidence = 0.0;

  // Event stream for logging and monitoring
  static final StreamController<AIRecommendationTriggerEvent> _triggerEventStream =
      StreamController<AIRecommendationTriggerEvent>.broadcast();

  static Stream<AIRecommendationTriggerEvent> get triggerEvents =>
      _triggerEventStream.stream;

  // ========== PUBLIC METHODS ==========

  /// Main entry point: Process a detection and determine if AI should be triggered
  /// Returns the recommendation if generated/cached, or null if skipped
  static Future<String?> processDetectionForAI(NormalizedDetection detection) async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 AI Recommendation Decision Engine');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Input: Disease="${detection.label}" Confidence=${(detection.confidence * 100).toStringAsFixed(1)}%');

    // Step 1: Check confidence threshold
    if (detection.confidence < confidenceThreshold) {
      _recordTriggerEvent(
        disease: detection.label,
        confidence: detection.confidence,
        reason: AITriggerReason.skippedLowConfidence,
      );
      print('⏭️  SKIP: Confidence (${(detection.confidence * 100).toStringAsFixed(1)}%) below threshold (${ (confidenceThreshold * 100).toStringAsFixed(0)}%)');
      return null;
    }

    // Step 2: Detect if disease has changed
    final isDiseaseChanged = _lastProcessedDisease != detection.label.toLowerCase();

    if (isDiseaseChanged) {
      print('✅ NEW DISEASE DETECTED: "${detection.label}"');
      print('   Previous: "$_lastProcessedDisease" → Current: "${detection.label.toLowerCase()}"');
    } else {
      print('⚠️  SAME DISEASE: Confidence only changed');
      print('   Previous: ${(_lastProcessedConfidence * 100).toStringAsFixed(1)}% → Current: ${(detection.confidence * 100).toStringAsFixed(1)}%');
    }

    // Step 3: Apply automatic trigger logic
    if (isDiseaseChanged) {
      final decision = _shouldAutoTriggerOnDiseaseChange(detection);

      if (decision.shouldTrigger) {
        print('🟢 AUTO-TRIGGER ALLOWED: ${decision.reason}');
        return await _generateAndCacheRecommendation(
          detection,
          AITriggerReason.newDiseaseDetected,
        );
      } else {
        print('🟡 AUTO-TRIGGER SKIPPED: ${decision.reason}');
        _recordTriggerEvent(
          disease: detection.label,
          confidence: detection.confidence,
          reason: decision.reasonEnum,
        );
        return null;
      }
    } else {
      // Confidence-only change: skip auto-generation
      print('⏭️  SKIP: Confidence-only change (same disease)');
      print('   This prevents API quota waste from minor confidence fluctuations');
      _recordTriggerEvent(
        disease: detection.label,
        confidence: detection.confidence,
        reason: AITriggerReason.skippedConfidenceOnly,
      );

      // Return cached recommendation if available
      final cached = _recommendationCache[detection.label.toLowerCase()];
      if (cached != null) {
        print('📦 Returning cached recommendation from ${_formatTime(cached.generatedAt)}');
        return cached.recommendation;
      }
      return null;
    }
  }

  /// Manual user trigger: Force generate a fresh recommendation
  /// Ignores cooldown and cache (unless generation fails)
  static Future<String> manuallyRequestAI(NormalizedDetection detection) async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👤 Manual User Request: "Ask AI Again"');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 User force-requesting fresh recommendation');
    print('   Disease: "${detection.label}"');
    print('   Ignoring: Cache, Cooldown, Previous state');

    _recordTriggerEvent(
      disease: detection.label,
      confidence: detection.confidence,
      reason: AITriggerReason.manualUserRequest,
    );

    // Always generate fresh on manual request (forceRefresh=true)
    return await _generateAndCacheRecommendation(
      detection,
      AITriggerReason.manualUserRequest,
      forceRefresh: true,
    );
  }

  /// Get cached recommendation without triggering new generation
  static String? getCachedRecommendation(String diseaseLabel) {
    final cached = _recommendationCache[diseaseLabel.toLowerCase()];
    if (cached != null) {
      print('📦 Retrieved cached recommendation for "$diseaseLabel"');
      return cached.recommendation;
    }
    return null;
  }

  /// Clear all caches (useful for settings/reset)
  static void clearCaches() {
    _recommendationCache.clear();
    _lastAutoTriggerTime.clear();
    _lastProcessedDisease = null;
    _lastProcessedConfidence = 0.0;
    print('🧹 All AI recommendation caches cleared');
  }

  /// Get cache statistics for debugging/monitoring
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedDiseases': _recommendationCache.keys.toList(),
      'cacheSize': _recommendationCache.length,
      'lastProcessedDisease': _lastProcessedDisease,
      'cooldownDuration': autoCooldownDuration.inMinutes,
      'confidenceThreshold': confidenceThreshold,
    };
  }

  // ========== PRIVATE METHODS ==========

  /// Determine if we should auto-trigger on a disease change
  /// Returns: {shouldTrigger: bool, reason: String, reasonEnum: AITriggerReason}
  static ({
    bool shouldTrigger,
    String reason,
    AITriggerReason reasonEnum,
  }) _shouldAutoTriggerOnDiseaseChange(NormalizedDetection detection) {
    final diseaseKey = detection.label.toLowerCase();

    // Check if within cooldown period for this disease
    final lastTrigger = _lastAutoTriggerTime[diseaseKey];
    if (lastTrigger != null) {
      final timeSinceLastTrigger = DateTime.now().difference(lastTrigger);
      if (timeSinceLastTrigger < autoCooldownDuration) {
        final remaining = autoCooldownDuration - timeSinceLastTrigger;
        return (
          shouldTrigger: false,
          reason:
              'In cooldown period. Last trigger: ${_formatTime(lastTrigger)} (${remaining.inMinutes}m remaining)',
          reasonEnum: AITriggerReason.skippedCooldown,
        );
      }
    }

    // All checks passed: should trigger
    return (
      shouldTrigger: true,
      reason: 'New disease OR outside cooldown period',
      reasonEnum: AITriggerReason.newDiseaseDetected,
    );
  }

  /// Generate recommendation via Gemini API and cache it
  static Future<String> _generateAndCacheRecommendation(
    NormalizedDetection detection,
    AITriggerReason reason, {
    bool forceRefresh = false,
  }) async {
    try {
      print('\n📞 Disease detected - queuing for AI analysis...');

      // ✅ FIXED: Only AIRecommendationWidget should call Gemini API
      // This prevents redundant API calls from both widget and service
      // The widget handles auto-recommendations with proper caching and deduplication
      // Service layer posts events instead of making API calls
      
      // ❌ DISABLED: Removed direct Gemini API call from service
      // final recommendation = await GeminiService.generateGeminiRecommendation(detection);
      
      // ✅ INSTEAD: Return cached recommendation or placeholder
      // Let the widget layer handle fresh API calls with deduplication
      final diseaseKey = detection.label.toLowerCase();
      
      // Check if we have a cached recommendation
      if (_recommendationCache.containsKey(diseaseKey)) {
        final cached = _recommendationCache[diseaseKey]!;
        print('✓ Using cached recommendation for "$diseaseKey"');
        _recordTriggerEvent(
          disease: detection.label,
          confidence: detection.confidence,
          reason: reason,
        );
        return cached.recommendation;
      }
      
      // ✅ No cached recommendation - return generic message
      // The widget will generate a fresh recommendation when user interacts
      final recommendation = "Detected: $diseaseKey. Tap 'Get Recommendations' for AI insights.";

      // Cache the result (for future reference)
      _recommendationCache[diseaseKey] = AIRecommendation(
        diseaseLabel: diseaseKey,
        recommendation: recommendation,
        generatedAt: DateTime.now(),
        confidence: detection.confidence,
      );

      // Update cooldown timer
      _lastAutoTriggerTime[diseaseKey] = DateTime.now();

      // Update current state
      _lastProcessedDisease = diseaseKey;
      _lastProcessedConfidence = detection.confidence;

      print('✅ Service queued disease for AI analysis: "$diseaseKey"');
      _recordTriggerEvent(
        disease: detection.label,
        confidence: detection.confidence,
        reason: reason,
      );
      
      return recommendation;
    } catch (e) {
      print('❌ Error in _generateAndCacheRecommendation: $e');
      rethrow;
    }
  }

  /// Record trigger event for monitoring/logging
  static void _recordTriggerEvent({
    required String disease,
    required double confidence,
    required AITriggerReason reason,
  }) {
    final event = AIRecommendationTriggerEvent(
      disease: disease,
      confidence: confidence,
      timestamp: DateTime.now(),
      reason: reason,
    );

    print(event);
    _triggerEventStream.add(event);
  }

  /// Format datetime for display
  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Cleanup resources
  static void dispose() {
    _triggerEventStream.close();
  }
}
