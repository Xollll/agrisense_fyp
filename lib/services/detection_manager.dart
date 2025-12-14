// detection_manager.dart
// 
// Background polling for disease detection
// =============================================
// Polls camera for new detections and sends notifications
// Does NOT make API calls or save recommendations (user-triggered only)
//
import 'dart:async';
import '../detection_service.dart';
import 'notification_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/notification_provider.dart';

class DetectionManager {
  Timer? _timer;
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

      // 3️⃣ Notify on new disease detection or confidence change
      // Simple notification - just alert of disease, no recommendation
      final notificationService = NotificationService();
      await notificationService.showDiseaseDetectionNotification(
        diseaseName: detection.label,
        confidence: detection.confidence,
        solution: '', // ✅ No recommendation in notification
      );

      // Add to notification provider for in-app display
      if (_notificationProvider != null) {
        await _notificationProvider!.addNotification(
          disease: detection.label,
          confidence: detection.confidence,
          solution: '', // ✅ No recommendation
        );
      }

      print('✅ Disease detected: ${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)');
    } catch (e) {
      print('DetectionManager error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
