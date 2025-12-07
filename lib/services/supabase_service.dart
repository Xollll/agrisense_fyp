// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Save detection (returns true on success)
  Future<bool> saveDetection({
    required String label,
    required double confidence,
    required String solution,
    String? timestamp,
  }) async {
    try {
      final ts = timestamp ?? DateTime.now().toIso8601String();

      final res = await _client.from('detections').insert({
        'label': label,
        'confidence': confidence,
        'solution': solution,
        'timestamp': ts,
      }).select();

      // Supabase .select() returns a List (empty if no data)
      final data = res as List<dynamic>;
      if (data.isEmpty) {
        print('Supabase insert error: No data returned');
        return false;
      }
      return true;
    } catch (e) {
      print('SupabaseService saveDetection exception: $e');
      return false;
    }
  }

  // Return list of maps for UI
  Future<List<Map<String, dynamic>>> getDetectionHistory() async {
    try {
      final res = await _client
          .from('detections')
          .select()
          .order('timestamp', ascending: false);

      // res is typically a List<dynamic>
      final data = res as List<dynamic>? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('SupabaseService getDetectionHistory exception: $e');
      return [];
    }
  }
}
