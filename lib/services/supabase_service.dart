// lib/services/supabase_service.dart
import 'dart:math';
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

  /// Get the most recent detection ID for a given disease label
  /// Returns the ID of the latest detection matching the label, or null if not found
  Future<int?> getLatestDetectionId(String label) async {
    try {
      final normalizedLabel = label.trim();
      appLog('🔍 Looking for latest detection ID for "$normalizedLabel"');

      final res = await _client
          .from('detections')
          .select('id')
          .eq('label', normalizedLabel)
          .order('timestamp', ascending: false)
          .limit(1);

      final data = res as List<dynamic>;
      if (data.isEmpty) {
        appLog('⚠️ No detection found for label "$normalizedLabel"');
        return null;
      }

      final detectionId = data.first['id'] as int;
      appLog('✅ Found latest detection ID: $detectionId for "$normalizedLabel"');
      return detectionId;
    } catch (e) {
      appLog('❌ SupabaseService.getLatestDetectionId error: $e');
      return null;
    }
  }

  /// Update the solution column of an existing detection record
  /// Used when user clicks "Get Recommendation" to update the most recent detection
  Future<bool> updateDetectionSolution({
    required int detectionId,
    required String solution,
  }) async {
    try {
      appLog('📝 Updating solution for detection ID: $detectionId');
      appLog('💡 Solution: "${solution.substring(0, min(100, solution.length))}"');

      // Update the detection record with the solution
      final res = await _client
          .from('detections')
          .update({'solution': solution})
          .eq('id', detectionId)
          .select();

      final data = res as List<dynamic>;
      if (data.isEmpty) {
        appLog('❌ Failed to update solution - no data returned');
        return false;
      }

      appLog('✅ Successfully updated solution for detection ID: $detectionId');
      return true;
    } catch (e) {
      appLog('❌ SupabaseService.updateDetectionSolution error: $e');
      return false;
    }
  }

  /// Test method to verify database connectivity and show all detections
  Future<void> testDatabaseConnection() async {
    try {
      appLog('🧪 Testing database connection...');
      
      final res = await _client
          .from('detections')
          .select('id, label, confidence, solution, timestamp, updated_at')
          .order('timestamp', ascending: false)
          .limit(20);

      appLog('✅ Database connection successful!');
      appLog('📊 Total detections fetched: ${(res as List).length}');
      
      if ((res as List).isNotEmpty) {
        appLog('\n📋 Recent Detections:');
        for (var i = 0; i < (res as List).length; i++) {
          final detection = res[i];
          final solution = detection['solution'] ?? '(empty)';
          appLog('  [$i] ID: ${detection['id']}, Label: "${detection['label']}", Confidence: ${detection['confidence']}, Solution: "$solution"');
        }
      } else {
        appLog('⚠️ No detections in database');
      }
    } catch (e) {
      appLog('❌ Database connection test failed: $e');
    }
  }
}
