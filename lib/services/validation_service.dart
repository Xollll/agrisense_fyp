// lib/services/validation_service.dart
/// Centralized validation service for all API responses and data integrity
/// Ensures app stability by validating data before use
class ValidationService {
  // ============================================================
  // CONFIDENCE SCORE VALIDATION (0.0 - 1.0)
  // ============================================================

  /// Validates that confidence is within valid range [0.0, 1.0]
  /// Returns true if valid, false otherwise
  static bool isValidConfidence(dynamic confidence) {
    if (confidence == null) return false;

    try {
      final score = confidence is double
          ? confidence
          : double.tryParse(confidence.toString());

      if (score == null) return false;

      // Must be between 0.0 and 1.0
      return score >= 0.0 && score <= 1.0;
    } catch (e) {
      return false;
    }
  }

  /// Clamps confidence to valid range [0.0, 1.0]
  /// Useful for automatic correction
  static double clampConfidence(dynamic confidence) {
    try {
      final score = confidence is double
          ? confidence
          : double.tryParse(confidence.toString()) ?? 0.0;

      return score.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  // ============================================================
  // DISEASE LABEL VALIDATION
  // ============================================================

  /// Valid disease categories based on the ML model
  static const List<String> validDiseaseLabels = [
    'healthy',
    'leaf spot',
    'early blight',
    'late blight',
    'powdery mildew',
    'bacterial wilt',
    'anthracnose',
    'leaf curl',
    'yellow leaf',
    'rust',
    'septoria',
  ];

  /// Validates disease label exists in model output
  static bool isValidLabel(String? label) {
    if (label == null || label.isEmpty) return false;

    final normalized = label.toLowerCase().trim();

    // Exact match
    if (validDiseaseLabels.contains(normalized)) return true;

    // Partial match (in case of variations)
    return validDiseaseLabels.any(
      (disease) =>
          normalized.contains(disease) || disease.contains(normalized),
    );
  }

  /// Normalizes disease label to standard format
  static String normalizeLabel(String? label) {
    if (label == null || label.isEmpty) return 'unknown';

    final normalized = label.toLowerCase().trim();

    // Return exact match if found
    for (var disease in validDiseaseLabels) {
      if (normalized == disease) return disease;
    }

    // Return closest match
    for (var disease in validDiseaseLabels) {
      if (normalized.contains(disease) || disease.contains(normalized)) {
        return disease;
      }
    }

    return 'unknown';
  }

  // ============================================================
  // TIMESTAMP VALIDATION
  // ============================================================

  /// Validates timestamp is in ISO 8601 format
  static bool isValidTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return false;

    try {
      DateTime.parse(timestamp);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parses and validates timestamp
  /// Returns parsed DateTime or current time if invalid
  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    try {
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.parse(timestamp);
      return DateTime.now();
    } catch (e) {
      print('❌ Invalid timestamp format: $timestamp');
      return DateTime.now();
    }
  }

  // ============================================================
  // API RESPONSE VALIDATION
  // ============================================================

  /// Validates complete detection response from server
  /// Returns map with validation result and corrected data
  static Map<String, dynamic> validateDetectionResponse(
      Map<String, dynamic> response) {
    return {
      'isValid': true,
      'label': isValidLabel(response['label'])
          ? normalizeLabel(response['label'])
          : 'unknown',
      'confidence':
          isValidConfidence(response['confidence']) ? response['confidence'] : 0.0,
      'timestamp': isValidTimestamp(response['timestamp'])
          ? response['timestamp']
          : DateTime.now().toIso8601String(),
      'errors': _collectErrors(response),
    };
  }

  /// Collects all validation errors from response
  static List<String> _collectErrors(Map<String, dynamic> response) {
    final errors = <String>[];

    if (!isValidLabel(response['label'])) {
      errors.add('Invalid disease label: ${response['label']}');
    }
    if (!isValidConfidence(response['confidence'])) {
      errors.add('Invalid confidence score: ${response['confidence']}');
    }
    if (!isValidTimestamp(response['timestamp'])) {
      errors.add('Invalid timestamp format: ${response['timestamp']}');
    }

    return errors;
  }

  // ============================================================
  // GEMINI RESPONSE VALIDATION
  // ============================================================

  /// Validates AI recommendation is not empty or malformed
  static bool isValidAIResponse(String? response) {
    if (response == null) return false;
    if (response.isEmpty) return false;
    if (response.length < 10) return false; // Too short
    if (response.contains('Error') && response.contains('500')) return false;

    return true;
  }

  /// Sanitizes AI response for display
  static String sanitizeAIResponse(String? response) {
    if (!isValidAIResponse(response)) {
      return "Unable to generate recommendation. Please try again.";
    }

    // Remove common prefixes
    var cleaned = response!
        .replaceAll('You are an agricultural', '')
        .replaceAll('As an AI assistant', '')
        .replaceAll('Here are the', '')
        .trim();

    // Remove if too long (API sometimes returns massive responses)
    if (cleaned.length > 500) {
      cleaned = cleaned.substring(0, 500) + '...';
    }

    return cleaned;
  }

  // ============================================================
  // HISTORY DATA VALIDATION
  // ============================================================

  /// Validates history record from Supabase
  static bool isValidHistoryRecord(Map<String, dynamic> record) {
    return record.containsKey('id') &&
        isValidLabel(record['label']) &&
        isValidConfidence(record['confidence']) &&
        record.containsKey('solution');
  }

  /// Filters and validates history list
  static List<Map<String, dynamic>> validateHistoryList(
      List<Map<String, dynamic>> records) {
    return records.where((record) => isValidHistoryRecord(record)).toList();
  }
}
