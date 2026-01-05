// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agrisense/utils/app_log.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Check if Supabase is properly initialized
  bool get isInitialized {
    try {
      return _client.auth.currentUser != null || true; // True if client exists
    } catch (e) {
      appLog('Supabase not initialized: $e');
      return false;
    }
  }

  // Save detection (returns true on success)
  Future<bool> saveDetection({
    required String label,
    required double confidence,
    required String solution,
    String? timestamp,
  }) async {
    try {
      final ts = timestamp ?? DateTime.now().toIso8601String();

      appLog('Saving detection: $label (confidence: $confidence)');

      final res = await _client.from('detections').insert({
        'label': label,
        'confidence': confidence,
        'solution': solution,
        'timestamp': ts,
      }).select();

      // Supabase .select() returns a List (empty if no data)
      final data = res as List<dynamic>;
      if (data.isEmpty) {
        appLog('Supabase insert error: No data returned');
        return false;
      }
      appLog('Detection saved successfully');
      return true;
    } catch (e) {
      appLog('SupabaseService.saveDetection error: $e');
      return false;
    }
  }

  // Return list of maps for UI
  Future<List<Map<String, dynamic>>> getDetectionHistory() async {
    try {
      appLog('Fetching detection history from Supabase...');
      appLog('Client initialized: $isInitialized');

      final res = await _client
          .from('detections')
          .select()
          .order('timestamp', ascending: false)
          .timeout(const Duration(seconds: 8));

      // res is typically a List<dynamic>
      final data = res as List<dynamic>? ?? [];
      appLog('Fetched ${data.length} detections');

      if (data.isNotEmpty) {
        appLog('Sample detection: ${data.first}');
      }

      // Map field names for compatibility with StatisticsService
      return data.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Map 'label' to 'disease_label' if it exists
        if (map.containsKey('label') && !map.containsKey('disease_label')) {
          map['disease_label'] = map['label'];
        }
        // Map 'solution' to 'recommendation' if it exists
        if (map.containsKey('solution') && !map.containsKey('recommendation')) {
          map['recommendation'] = map['solution'];
        }
        return map;
      }).toList();
    } catch (e) {
      appLog('SupabaseService.getDetectionHistory error: $e');
      return [];
    }
  }

  /// Delete ALL detection history from the `detections` table.
  ///
  /// WARNING: This is a destructive operation. In a multi-user setup, this would
  /// delete history for everyone unless scoped (e.g., by user_id/device_id).
  Future<void> deleteAllDetections() async {
    try {
      // ⚠️ WARNING: This deletes ALL rows in the table for the current project.
      // This is intended for anon/no-auth setups with permissive RLS policies.
      // PostgREST requires at least one filter for delete operations.
      await _client.from('detections').delete().neq('id', -1);
    } catch (e) {
      throw Exception(
        'Failed to delete cloud history.\n'
        'Details: $e',
      );
    }
  }

  /// Delete selected detections by their numeric ids.
  Future<bool> deleteDetectionsByIds(List<int> ids) async {
    if (ids.isEmpty) return true;

    try {
      appLog('Deleting ${ids.length} detections from Supabase...');
      await _client.from('detections').delete().inFilter('id', ids);
      appLog('Selected detections deleted successfully');
      return true;
    } catch (e) {
      appLog('SupabaseService.deleteDetectionsByIds error: $e');
      return false;
    }
  }
}
