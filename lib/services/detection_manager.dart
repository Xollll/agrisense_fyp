// detection_manager.dart
import 'dart:async';
import '../detection_service.dart';
import '../gemini_service.dart';
import 'supabase_service.dart';

class DetectionManager {
  Timer? _timer;
  final SupabaseService _supabase = SupabaseService();

  bool _isProcessing = false;

  // Start polling every 10s (or any interval you choose)
  void startPolling(Duration interval) {
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

      // 3️⃣ Generate AI recommendation
      final solution =
          await GeminiService.generateGeminiRecommendation(detection);

      // 4️⃣ Save to Supabase
      final success = await _supabase.saveDetection(
        label: detection.label,
        confidence: detection.confidence,
        solution: solution,
        timestamp: detection.time, // will use detection time if available
      );

      print('Detection processed: ${detection.label}, saved: $success');
    } catch (e) {
      print('DetectionManager error: $e');
    } finally {
      _isProcessing = false;
    }
  }
}
