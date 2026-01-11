// lib/services/statistics_service.dart
import 'dart:convert';
import 'supabase_service.dart';
import 'package:agrisense/utils/app_log.dart';

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
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> initialize() async {
    // Supabase is initialized globally; no additional setup needed
  }

  /// Get all detection history from Supabase
  Future<List<Map<String, dynamic>>> getDetectionHistory() async {
    try {
      return await _supabaseService.getDetectionHistory();
    } catch (e) {
      appLog('Error fetching detection history: $e');
      return [];
    }
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
      // Support both 'label' and 'disease_label' fields
      final disease = (detection['disease_label'] ?? detection['label'] ?? 'Unknown') as String;
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
  /// If days is null or -1, returns ALL historical data
  Future<List<TimelineData>> getTimelineData({int days = 30}) async {
    final history = await getDetectionHistory();

    if (history.isEmpty) {
      return [];
    }

    // Group by date
    final timelineMap = <String, int>{};
    final now = DateTime.now();
    final startDate = days < 0 ? null : now.subtract(Duration(days: days));

    for (var detection in history) {
      final timestamp = detection['timestamp'] as String? ?? '';
      if (timestamp.isNotEmpty) {
        final detectionTime = DateTime.tryParse(timestamp);
        // If startDate is null (all time), include all data; otherwise filter by date
        if (detectionTime != null && (startDate == null || detectionTime.isAfter(startDate))) {
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
      // Support both 'label' and 'disease_label' fields
      final diseaseLabel = ((detection['disease_label'] ?? detection['label']) as String?)?.toLowerCase() ?? '';
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
    
    // Calculate month-over-month health comparison
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    
    final history = await getDetectionHistory();
    
    // Current month: detections from last 30 days
    final currentMonthDetections = history
        .where((d) {
          final timestamp = DateTime.tryParse(d['timestamp']?.toString() ?? '');
          return timestamp != null && timestamp.isAfter(thirtyDaysAgo);
        })
        .toList();
    
    // Previous month: detections from 30-60 days ago
    var previousMonthDetections = history
        .where((d) {
          final timestamp = DateTime.tryParse(d['timestamp']?.toString() ?? '');
          return timestamp != null && 
                 timestamp.isAfter(sixtyDaysAgo) && 
                 timestamp.isBefore(thirtyDaysAgo);
        })
        .toList();
    
    // If no data from 30-60 days ago, use first half of all available data for comparison
    if (previousMonthDetections.isEmpty && history.isNotEmpty) {
      final midpoint = (history.length / 2).floor();
      previousMonthDetections = history.sublist(0, midpoint);
    }
    
    // Calculate healthy percentage for current month
    double currentMonthHealth = 0;
    if (currentMonthDetections.isNotEmpty) {
      final healthyCount = currentMonthDetections
          .where((d) {
            // Support both 'label' and 'disease_label' fields
            final label = ((d['disease_label'] ?? d['label']) as String?)?.toLowerCase() ?? '';
            return label.contains('healthy') || label.contains('no disease') || label == 'normal';
          })
          .length;
      currentMonthHealth = (healthyCount / currentMonthDetections.length) * 100;
    }
    
    // Calculate healthy percentage for previous month
    double previousMonthHealth = 0;
    if (previousMonthDetections.isNotEmpty) {
      final healthyCount = previousMonthDetections
          .where((d) {
            // Support both 'label' and 'disease_label' fields
            final label = ((d['disease_label'] ?? d['label']) as String?)?.toLowerCase() ?? '';
            return label.contains('healthy') || label.contains('no disease') || label == 'normal';
          })
          .length;
      previousMonthHealth = (healthyCount / previousMonthDetections.length) * 100;
    } else {
      // If no data at all, use current as baseline
      previousMonthHealth = currentMonthHealth;
    }

    return {
      'total_detections': totalDetections,
      'healthy_percentage': healthyPercentage.toStringAsFixed(1),
      'diseased_percentage': (100 - healthyPercentage).toStringAsFixed(1),
      'most_common_disease': mostCommon ?? 'None',
      'unique_diseases': diseaseStats.length,
      'last_detection': totalDetections > 0
          ? (await getDetectionHistory()).last['timestamp'] ?? 'Unknown'
          : 'No detections yet',
      'previous_month_health': previousMonthHealth.toStringAsFixed(1),
      'current_month_detections': currentMonthDetections.length,
      'previous_month_detections': previousMonthDetections.length,
    };
  }

  /// Add detection to history (called after each detection)
  Future<void> addDetection({
    required String diseaseLabel,
    required double confidence,
    required String recommendation,
  }) async {
    try {
      // Save detection via Supabase
      await _supabaseService.saveDetection(
        label: diseaseLabel,
        confidence: confidence,
        solution: recommendation,
      );
      appLog('Detection added to Supabase: $diseaseLabel');
    } catch (e) {
      appLog('Error adding detection: $e');
      rethrow;
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      // For now, we don't support bulk delete in SupabaseService
      // This would typically be done via a backend function or direct DB access
      appLog('Clear history not yet implemented for Supabase');
      // TODO: Implement bulk delete in SupabaseService if needed
    } catch (e) {
      appLog('Error clearing history: $e');
      rethrow;
    }
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
