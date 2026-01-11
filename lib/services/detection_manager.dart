// detection_manager.dart
// 
// Background polling for disease detection
// =============================================
// Polls camera for new detections and sends notifications
// Only notifies when confidence varies by 10% or more for the same disease
// Does NOT make API calls or save recommendations (user-triggered only)
//
import 'dart:async';
import '../detection_service.dart';
import 'notification_service.dart';
import '../providers/notification_provider.dart';

class DetectionManager {
  Timer? _timer;
  NotificationProvider? _notificationProvider;

  bool _isProcessing = false;

  // Track last notified confidence for each disease to avoid spam
  // Key: disease label, Value: last notified confidence
  final Map<String, double> _lastNotifiedConfidence = {};

  // Confidence threshold for notification (10% variation)
  static const double _confidenceThreshold = 0.10;

  // Set notification provider for in-app notifications
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  // Start polling using the provided interval (fixed)
  void startPolling(Duration interval) {
    if (_timer != null) return;

    _timer = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce(); // optional immediate first run
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if confidence change warrants a notification
  /// Returns true if:
  /// 1. First detection of this disease, OR
  /// 2. Confidence changed by 10% or more
  bool _shouldNotify(String diseaseName, double newConfidence) {
    final lastConfidence = _lastNotifiedConfidence[diseaseName];

    // First detection of this disease
    if (lastConfidence == null) {
      return true;
    }

    // Check if confidence changed by threshold (10%)
    final confidenceDifference = (newConfidence - lastConfidence).abs();
    return confidenceDifference >= _confidenceThreshold;
  }

  Future<void> _pollOnce() async {
    if (_isProcessing) return;

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

      // 3️⃣ Check if we should send notification based on confidence change
      if (!_shouldNotify(detection.label, detection.confidence)) {
        return; // Skip notification if confidence hasn't changed enough
      }

      // Update last notified confidence for this disease
      _lastNotifiedConfidence[detection.label] = detection.confidence;

      // 4️⃣ Notify on detection
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
