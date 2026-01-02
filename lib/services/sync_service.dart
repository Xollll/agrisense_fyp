// lib/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';
import 'package:agrisense/utils/app_log.dart';

/// Service for managing online/offline sync and connectivity
class SyncService {
  static final SyncService _instance = SyncService._internal();
  Timer? _syncTimer;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _connectionSubscription;

  bool _isOnline = true;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  /// Initialize sync service and monitor connectivity
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      appLog('Initial connection: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');

      // Listen for connectivity changes
      _connectionSubscription =
          _connectivity.onConnectivityChanged.listen(
        (result) {
          final wasOnline = _isOnline;
          _isOnline = result != ConnectivityResult.none;

          if (wasOnline && !_isOnline) {
            appLog('Went OFFLINE - using local cache');
          } else if (!wasOnline && _isOnline) {
            appLog('Back ONLINE - syncing cache...');
            syncPendingData();
          }
        },
      );

      // Start periodic sync timer (every 30 seconds)
      _syncTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => syncPendingData(),
      );
    } catch (e) {
      appLog('Sync service init error: $e');
    }
  }

  /// Sync pending detections to cloud
  Future<void> syncPendingData() async {
    if (!_isOnline) {
      appLog('Offline - skipping sync');
      return;
    }

    try {
      appLog('Starting data sync...');

      final unsynced = await LocalCacheService.getUnsyncedDetections();
      if (unsynced.isEmpty) {
        appLog('No data to sync');
        return;
      }

      final supabase = SupabaseService();
      int syncedCount = 0;

      for (var detection in unsynced) {
        try {
          final success = await supabase.saveDetection(
            label: detection['label'],
            confidence: detection['confidence'],
            solution: detection['solution'],
            timestamp: detection['timestamp'],
          );

          if (success) {
            await LocalCacheService.markAsSynced(detection['id']);
            syncedCount++;
          }
        } catch (e) {
          appLog('Sync failed for ${detection['label']}: $e');
        }
      }

      await LocalCacheService.updateLastSyncTime();
      appLog('Synced $syncedCount/${unsynced.length} detections');
    } catch (e) {
      appLog('Sync error: $e');
    }
  }

  /// Cleanup
  void dispose() {
    _syncTimer?.cancel();
    _connectionSubscription.cancel();
  }
}
