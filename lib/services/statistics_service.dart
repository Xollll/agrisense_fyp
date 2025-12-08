// lib/services/statistics_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for disease statistics
class DiseaseStats {
  final String disease;
  final int count;
  final double percentage;
  final DateTime lastDetected;

  DiseaseStats({
    required this.disease,
    required this.count,
    required this.percentage,
    required this.lastDetected,
  });
}

/// Model for detection timeline data
class TimelineData {
  final DateTime date;
  final int count;

  TimelineData({required this.date, required this.count});
}

/// Statistics service for analyzing detection history
class StatisticsService {
  static const String _historyKey = 'detection_history';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all detection history
  Future<List<Map<String, dynamic>>> getDetectionHistory() async {
    final historyJson = _prefs.getStringList(_historyKey) ?? [];
    return historyJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  /// Get disease statistics (frequency, percentage)
  Future<List<DiseaseStats>> getDiseaseStats() async {
    final history = await getDetectionHistory();

    if (history.isEmpty) {
      return [];
    }

    // Count diseases
    final diseaseMap = <String, int>{};
    final lastDetectedMap = <String, DateTime>{};

    for (var detection in history) {
      final disease = detection['disease_label'] as String? ?? 'Unknown';
      final timestamp = detection['timestamp'] as String? ?? '';

      diseaseMap[disease] = (diseaseMap[disease] ?? 0) + 1;

      // Track last detection time
      if (timestamp.isNotEmpty) {
        final detectionTime = DateTime.tryParse(timestamp);
        if (detectionTime != null) {
          if (!lastDetectedMap.containsKey(disease) ||
              detectionTime.isAfter(lastDetectedMap[disease]!)) {
            lastDetectedMap[disease] = detectionTime;
          }
        }
      }
    }

    // Convert to stats with percentages
    final total = history.length;
    return diseaseMap.entries
        .map((e) => DiseaseStats(
          disease: e.key,
          count: e.value,
          percentage: (e.value / total) * 100,
          lastDetected: lastDetectedMap[e.key] ?? DateTime.now(),
        ))
        .toList()
        ..sort((a, b) => b.count.compareTo(a.count)); // Sort by count descending
  }

  /// Get timeline data for the last N days
  Future<List<TimelineData>> getTimelineData({int days = 30}) async {
    final history = await getDetectionHistory();

    if (history.isEmpty) {
      return [];
    }

    // Group by date
    final timelineMap = <String, int>{};
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    for (var detection in history) {
      final timestamp = detection['timestamp'] as String? ?? '';
      if (timestamp.isNotEmpty) {
        final detectionTime = DateTime.tryParse(timestamp);
        if (detectionTime != null && detectionTime.isAfter(startDate)) {
          final dateKey =
              '${detectionTime.year}-${detectionTime.month.toString().padLeft(2, '0')}-${detectionTime.day.toString().padLeft(2, '0')}';
          timelineMap[dateKey] = (timelineMap[dateKey] ?? 0) + 1;
        }
      }
    }

    // Convert to sorted list
    return timelineMap.entries
        .map((e) {
          final parts = e.key.split('-');
          return TimelineData(
            date: DateTime(int.parse(parts[0]), int.parse(parts[1]),
                int.parse(parts[2])),
            count: e.value,
          );
        })
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get total number of detections
  Future<int> getTotalDetections() async {
    final history = await getDetectionHistory();
    return history.length;
  }

  /// Get healthy detection percentage (healthy leaves detected)
  Future<double> getHealthyPercentage() async {
    final history = await getDetectionHistory();

    if (history.isEmpty) {
      return 0.0;
    }

    int healthyCount = 0;
    for (var detection in history) {
      final diseaseLabel = (detection['disease_label'] as String?)?.toLowerCase() ?? '';
      if (diseaseLabel.contains('healthy') ||
          diseaseLabel.contains('no disease') ||
          diseaseLabel == 'normal') {
        healthyCount++;
      }
    }

    return (healthyCount / history.length) * 100;
  }

  /// Get the most common disease
  Future<String?> getMostCommonDisease() async {
    final stats = await getDiseaseStats();
    if (stats.isEmpty) return null;
    return stats.first.disease;
  }

  /// Get disease count for a specific disease
  Future<int> getDiseaseCount(String disease) async {
    final stats = await getDiseaseStats();
    final stat = stats.firstWhere(
      (s) => s.disease.toLowerCase() == disease.toLowerCase(),
      orElse: () => DiseaseStats(
        disease: disease,
        count: 0,
        percentage: 0.0,
        lastDetected: DateTime.now(),
      ),
    );
    return stat.count;
  }

  /// Get statistics summary
  Future<Map<String, dynamic>> getStatisticsSummary() async {
    final totalDetections = await getTotalDetections();
    final healthyPercentage = await getHealthyPercentage();
    final diseaseStats = await getDiseaseStats();
    final mostCommon = await getMostCommonDisease();

    return {
      'total_detections': totalDetections,
      'healthy_percentage': healthyPercentage.toStringAsFixed(1),
      'diseased_percentage': (100 - healthyPercentage).toStringAsFixed(1),
      'most_common_disease': mostCommon ?? 'None',
      'unique_diseases': diseaseStats.length,
      'last_detection': totalDetections > 0
          ? (await getDetectionHistory()).last['timestamp'] ?? 'Unknown'
          : 'No detections yet',
    };
  }

  /// Add detection to history (called after each detection)
  Future<void> addDetection({
    required String diseaseLabel,
    required double confidence,
    required String recommendation,
  }) async {
    final history = await getDetectionHistory();

    final newDetection = {
      'disease_label': diseaseLabel,
      'confidence': confidence,
      'recommendation': recommendation,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final updatedHistory = [
      ...history.map((h) => jsonEncode(h)).toList(),
      jsonEncode(newDetection),
    ];

    await _prefs.setStringList(_historyKey, updatedHistory);
    print('✅ Detection added to history: $diseaseLabel');
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
    print('🗑️ Detection history cleared');
  }

  /// Export statistics as JSON
  Future<String> exportAsJson() async {
    final summary = await getStatisticsSummary();
    final diseaseStats = await getDiseaseStats();
    final timelineData = await getTimelineData();

    final export = {
      'summary': summary,
      'disease_stats': diseaseStats
          .map((s) => {
            'disease': s.disease,
            'count': s.count,
            'percentage': s.percentage.toStringAsFixed(2),
            'last_detected': s.lastDetected.toIso8601String(),
          })
          .toList(),
      'timeline': timelineData
          .map((t) => {
            'date': t.date.toIso8601String(),
            'count': t.count,
          })
          .toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    return jsonEncode(export);
  }
}
