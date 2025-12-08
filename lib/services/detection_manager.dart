// detection_manager.dart
import 'dart:async';
import '../detection_service.dart';
import '../gemini_service.dart';
import 'supabase_service.dart';
import 'local_cache_service.dart';
import 'sync_service.dart';
import '../providers/app_settings_provider.dart';

class DetectionManager {
  Timer? _timer;
  final SupabaseService _supabase = SupabaseService();
  final SyncService _sync = SyncService();

  bool _isProcessing = false;
  AppSettingsProvider? _settings;

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

      // 3️⃣ Generate AI recommendation
      final solution = await GeminiService.generateGeminiRecommendation(detection);

      // 4️⃣ Cache locally
      await LocalCacheService.cacheDetection(
        label: detection.label,
        confidence: detection.confidence,
        solution: solution,
        timestamp: detection.time ?? DateTime.now().toIso8601String(),
      );

      // 5️⃣ Sync to cloud if online, otherwise queue for later
      if (_sync.isOnline) {
        final success = await _supabase.saveDetection(
          label: detection.label,
          confidence: detection.confidence,
          solution: solution,
          timestamp: detection.time,
        );
        print('Detection ${success ? 'saved to cloud' : 'save failed'}');
      } else {
        print('📴 Offline - detection cached locally');
        // Add to sync queue for later
        await LocalCacheService.addToSyncQueue(
          label: detection.label,
          confidence: detection.confidence,
          solution: solution,
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
