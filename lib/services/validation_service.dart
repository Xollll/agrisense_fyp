/// Centralized validation service for all API responses and data integrity
/// Ensures app stability by validating data before use
class ValidationService {
  // ============================================================
  // CONFIDENCE SCORE VALIDATION (0.0 - 1.0)
  // ============================================================

  static bool isValidConfidence(dynamic confidence) {
    if (confidence == null) return false;

    try {
      final score = confidence is double
          ? confidence
          : double.tryParse(confidence.toString());

      if (score == null) return false;

      return score >= 0.0 && score <= 1.0;
    } catch (e) {
      return false;
    }
  }

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

  /// Accepted YOLO disease labels
  static const List<String> acceptedLabels = [
    'Healthy',
    'Leaf Curl',
    'Leaf Spot',
    'Yellow Mosaic',
  ];

  /// Normalizes a label to match acceptedLabels
  static String normalizeLabel(String? label) {
    if (label == null || label.isEmpty) return 'unknown';

    // Normalize YOLO-style labels (lowercase, remove underscores/hyphens, trim)
    final normalized = label
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    // Fuzzy match: check if normalized contains any accepted label
    for (var valid in acceptedLabels) {
      final validNormalized = valid.toLowerCase();
      if (normalized == validNormalized || normalized.contains(validNormalized)) {
        return valid; // Return standard format
      }
    }

    // If no exact match, attempt minor typo correction
    for (var valid in acceptedLabels) {
      final validNormalized = valid.toLowerCase().replaceAll(' ', '');
      final candidate = normalized.replaceAll(' ', '');
      if (candidate.contains(validNormalized) || validNormalized.contains(candidate)) {
        return valid;
      }
    }

    // Otherwise, return the normalized label directly (prevents unknown)
    return normalized;
  }

  static bool isValidLabel(String? label) {
    if (label == null || label.isEmpty) return false;

    final normalized = normalizeLabel(label);
    return normalized.isNotEmpty;
  }

  // ============================================================
  // TIMESTAMP VALIDATION
  // ============================================================

  static bool isValidTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return false;

    try {
      DateTime.parse(timestamp);
      return true;
    } catch (e) {
      return false;
    }
  }

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

  static Map<String, dynamic> validateDetectionResponse(
      Map<String, dynamic> response) {
    return {
      'isValid': true,
      'label': normalizeLabel(response['label']),
      'confidence': isValidConfidence(response['confidence'])
          ? response['confidence']
          : 0.0,
      'timestamp': isValidTimestamp(response['timestamp'])
          ? response['timestamp']
          : DateTime.now().toIso8601String(),
      'errors': _collectErrors(response),
    };
  }

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

  static bool isValidAIResponse(String? response) {
    if (response == null) return false;
    if (response.isEmpty) return false;
    if (response.length < 10) return false;
    if (response.contains('Error') && response.contains('500')) return false;

    return true;
  }

  static String sanitizeAIResponse(String? response) {
    if (!isValidAIResponse(response)) {
      return "Unable to generate recommendation. Please try again.";
    }

    var cleaned = response!
        .replaceAll('You are an agricultural', '')
        .replaceAll('As an AI assistant', '')
        .replaceAll('Here are the', '')
        .trim();

    if (cleaned.length > 500) {
      cleaned = cleaned.substring(0, 500) + '...';
    }

    return cleaned;
  }

  // ============================================================
  // HISTORY DATA VALIDATION
  // ============================================================

  static bool isValidHistoryRecord(Map<String, dynamic> record) {
    return record.containsKey('id') &&
        isValidLabel(record['label']) &&
        isValidConfidence(record['confidence']) &&
        record.containsKey('solution');
  }

  static List<Map<String, dynamic>> validateHistoryList(
      List<Map<String, dynamic>> records) {
    return records.where((record) => isValidHistoryRecord(record)).toList();
  }
}
