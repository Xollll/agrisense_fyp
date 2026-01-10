// lib/providers/statistics_provider.dart
import 'package:flutter/material.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();

  // Data
  List<DiseaseStats> _diseaseStats = [];
  List<TimelineData> _timelineData = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DiseaseStats> get diseaseStats => _diseaseStats;
  List<TimelineData> get timelineData => _timelineData;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StatisticsProvider() {
    initialize();
  }

  /// Initialize service and load data
  Future<void> initialize() async {
    await _statisticsService.initialize();
    await loadStatistics();
  }

  /// Load all statistics
  Future<void> loadStatistics() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load in parallel
      // Use -1 to get ALL historical data (no date filter)
      final results = await Future.wait([
        _statisticsService.getDiseaseStats(),
        _statisticsService.getTimelineData(days: -1), // -1 = all historical data
        _statisticsService.getStatisticsSummary(),
      ]);

      _diseaseStats = results[0] as List<DiseaseStats>;
      _timelineData = results[1] as List<TimelineData>;
      _summary = results[2] as Map<String, dynamic>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get disease stats
  Future<List<DiseaseStats>> getDiseaseStats() =>
      _statisticsService.getDiseaseStats();

  /// Get timeline data
  Future<List<TimelineData>> getTimelineData({int days = 30}) =>
      _statisticsService.getTimelineData(days: days);

  /// Get total detections
  Future<int> getTotalDetections() =>
      _statisticsService.getTotalDetections();

  /// Get healthy percentage
  Future<double> getHealthyPercentage() =>
      _statisticsService.getHealthyPercentage();

  /// Get most common disease
  Future<String?> getMostCommonDisease() =>
      _statisticsService.getMostCommonDisease();

  /// Add a new detection
  Future<void> addDetection({
    required String diseaseLabel,
    required double confidence,
    required String recommendation,
  }) async {
    await _statisticsService.addDetection(
      diseaseLabel: diseaseLabel,
      confidence: confidence,
      recommendation: recommendation,
    );
    await loadStatistics(); // Refresh statistics
  }

  /// Clear history
  Future<void> clearHistory() async {
    await _statisticsService.clearHistory();
    await loadStatistics(); // Refresh statistics
  }

  /// Export statistics
  Future<String> exportAsJson() =>
      _statisticsService.exportAsJson();
}
