// lib/services/local_cache_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local cache service for offline support and data persistence
/// Stores detection history locally and manages sync queue
class LocalCacheService {
  static late SharedPreferences _prefs;

  static const String _detectionsCacheKey = 'cached_detections';
  static const String _settingsCacheKey = 'cached_settings';
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncTimeKey = 'last_sync_time';

  /// Initialize cache service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ Local cache service initialized');
  }

  // ============= DETECTION CACHING =============

  /// Cache detection locally
  static Future<bool> cacheDetection({
    required String label,
    required double confidence,
    required String solution,
    required String timestamp,
  }) async {
    try {
      final detections = await getCachedDetections();

      // Add new detection
      detections.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'label': label,
        'confidence': confidence,
        'solution': solution,
        'timestamp': timestamp,
        'synced': false, // Mark as not yet synced to cloud
      });

      // Keep only last 100 detections to save space
      if (detections.length > 100) {
        detections.removeRange(0, detections.length - 100);
      }

      await _prefs.setString(
        _detectionsCacheKey,
        jsonEncode(detections),
      );

      print('✅ Detection cached locally: $label');
      return true;
    } catch (e) {
      print('❌ Cache detection error: $e');
      return false;
    }
  }

  /// Get all cached detections
  static Future<List<Map<String, dynamic>>> getCachedDetections() async {
    try {
      final cached = _prefs.getString(_detectionsCacheKey);
      if (cached == null) return [];

      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Get cached detections error: $e');
      return [];
    }
  }

  /// Get unsynced detections (for offline-first sync)
  static Future<List<Map<String, dynamic>>> getUnsyncedDetections() async {
    final all = await getCachedDetections();
    return all.where((d) => d['synced'] != true).toList();
  }

  /// Mark detection as synced
  static Future<bool> markAsSynced(String detectionId) async {
    try {
      final detections = await getCachedDetections();

      // Find and update
      final index = detections.indexWhere((d) => d['id'] == detectionId);
      if (index >= 0) {
        detections[index]['synced'] = true;
        await _prefs.setString(_detectionsCacheKey, jsonEncode(detections));
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Mark as synced error: $e');
      return false;
    }
  }

  // ============= SYNC MANAGEMENT =============

  /// Add detection to sync queue
  static Future<bool> addToSyncQueue({
    required String label,
    required double confidence,
    required String solution,
  }) async {
    try {
      final queue = await _getSyncQueue();

      queue.add({
        'action': 'sync_detection',
        'label': label,
        'confidence': confidence,
        'solution': solution,
        'timestamp': DateTime.now().toIso8601String(),
        'retries': 0,
      });

      await _prefs.setString(_syncQueueKey, jsonEncode(queue));
      print('📤 Added to sync queue: $label');
      return true;
    } catch (e) {
      print('❌ Sync queue error: $e');
      return false;
    }
  }

  /// Get pending sync operations
  static Future<List<Map<String, dynamic>>> _getSyncQueue() async {
    try {
      final queue = _prefs.getString(_syncQueueKey);
      if (queue == null) return [];

      final List<dynamic> decoded = jsonDecode(queue);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Get sync queue error: $e');
      return [];
    }
  }

  /// Clear sync queue
  static Future<bool> clearSyncQueue() async {
    try {
      await _prefs.remove(_syncQueueKey);
      print('✅ Sync queue cleared');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update last sync time
  static Future<bool> updateLastSyncTime() async {
    try {
      await _prefs.setString(
        _lastSyncTimeKey,
        DateTime.now().toIso8601String(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final time = _prefs.getString(_lastSyncTimeKey);
      if (time == null) return null;
      return DateTime.parse(time);
    } catch (e) {
      return null;
    }
  }

  // ============= CACHE STATS =============

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    final detections = await getCachedDetections();
    final unsynced = await getUnsyncedDetections();
    final lastSync = await getLastSyncTime();

    return {
      'totalDetections': detections.length,
      'unsyncedDetections': unsynced.length,
      'lastSyncTime': lastSync,
      'cacheSize': '${(_prefs.toString().length / 1024).toStringAsFixed(2)} KB',
    };
  }

  /// Clear all cache
  static Future<bool> clearAllCache() async {
    try {
      await _prefs.remove(_detectionsCacheKey);
      await _prefs.remove(_syncQueueKey);
      await _prefs.remove(_lastSyncTimeKey);
      print('🗑️ All cache cleared');
      return true;
    } catch (e) {
      print('❌ Clear cache error: $e');
      return false;
    }
  }
}
