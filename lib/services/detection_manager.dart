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

  // Start polling using the provided interval (fixed)
  void startPolling(Duration interval, [AppSettingsProvider? settings]) {
    _settings = settings;
    if (_timer != null) return;

    _timer = Timer.periodic(interval, (_) => _pollOnce());
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
      return;
    }

    _isProcessing = true;

    try {
      // 1️⃣ Fetch detection
      final detections = await DetectionService.fetchDetections();
      if (detections.isEmpty) {
        return;
      }
      final detection = detections.first;

      // 2️⃣ Skip low confidence
      if (detection.confidence <= 0.01) {
        return;
      }

      // ✅ Respect notification setting
      final notificationsAllowed =
          _settings == null ? true : _settings!.notificationsEnabled;

      if (!notificationsAllowed) {
        return;
      }

      // 3️⃣ Notify on detection
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
    } catch (e) {
      // Intentionally swallow errors to keep background loop resilient.
      // Consider forwarding to a crash/analytics service in production.
    } finally {
      _isProcessing = false;
    }
  }
}
