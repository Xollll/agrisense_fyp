// detection_manager.dart
// 
// Integration point between detection and AI recommendation systems
// ================================================================
// Uses AIRecommendationService to intelligently trigger AI generation
// Prevents API quota waste while ensuring timely recommendations
//
import 'dart:async';
import '../detection_service.dart';
import 'ai_recommendation_service.dart';
import 'supabase_service.dart';
import 'local_cache_service.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/notification_provider.dart';

class DetectionManager {
  Timer? _timer;
  final SupabaseService _supabase = SupabaseService();
  final SyncService _sync = SyncService();
  NotificationProvider? _notificationProvider;

  bool _isProcessing = false;
  AppSettingsProvider? _settings;

  // Set notification provider for in-app notifications
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  // Start polling every 10s (or any interval you choose)
  void startPolling(Duration interval, [AppSettingsProvider? settings]) {
    _settings = settings;
    if (_timer != null) return;

    final actualInterval =
        _settings != null ? Duration(seconds: _settings!.updateIntervalSeconds) : interval;

    _timer = Timer.periodic(actualInterval, (_) => _pollOnce());
    _pollOnce(); // optional immediate first run
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce() async {
    if (_isProcessing) return;

    // ✅ Check if live updates are enabled in settings
    if (_settings != null && !_settings!.liveUpdatesEnabled) {
      print('⏸️ Live updates disabled in settings');
      return;
    }

    _isProcessing = true;

    try {
      // 1️⃣ Fetch detection
      final detections = await DetectionService.fetchDetections();
      if (detections.isEmpty) {
        _isProcessing = false;
        return;
      }
      final detection = detections.first;

      // 2️⃣ Skip low confidence
      if (detection.confidence <= 0.01) {
        print('Detection confidence too low; skipping.');
        _isProcessing = false;
        return;
      }

      // 3️⃣ Use smart AI recommendation service
      // This will only trigger AI if:
      // - New disease detected (not confidence-only changes)
      // - Confidence >= 0.5
      // - Outside cooldown period (default: 10 minutes)
      final solution = await AIRecommendationService.processDetectionForAI(detection);

      // If AI was skipped (solution is null), try to use cached recommendation
      final finalSolution = solution ?? AIRecommendationService.getCachedRecommendation(detection.label) ?? '';

      // 🔔 Show notifications (always, regardless of AI trigger)
      final notificationService = NotificationService();
      await notificationService.showDiseaseDetectionNotification(
        diseaseName: detection.label,
        confidence: detection.confidence,
        solution: finalSolution,
      );

      // Add to notification provider for in-app display
      if (_notificationProvider != null) {
        await _notificationProvider!.addNotification(
          disease: detection.label,
          confidence: detection.confidence,
          solution: finalSolution,
        );
      }

      if (finalSolution.isNotEmpty) {
        await notificationService.showRecommendationNotification(
          diseaseName: detection.label,
          recommendation: finalSolution,
        );
      }

      // 4️⃣ Cache locally
      await LocalCacheService.cacheDetection(
        label: detection.label,
        confidence: detection.confidence,
        solution: finalSolution,
        timestamp: detection.time ?? DateTime.now().toIso8601String(),
      );

      // 5️⃣ Sync to cloud if online, otherwise queue for later
      if (_sync.isOnline) {
        final success = await _supabase.saveDetection(
          label: detection.label,
          confidence: detection.confidence,
          solution: finalSolution,
          timestamp: detection.time,
        );
        print('Detection ${success ? 'saved to cloud' : 'save failed'}');
      } else {
        print('📴 Offline - detection cached locally');
        // Add to sync queue for later
        await LocalCacheService.addToSyncQueue(
          label: detection.label,
          confidence: detection.confidence,
          solution: finalSolution,
        );
      }

      print('✅ Detection processed: ${detection.label}');
    } catch (e) {
      print('DetectionManager error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
