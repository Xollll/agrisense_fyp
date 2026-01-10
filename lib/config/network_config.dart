// lib/config/network_config.dart

/// Network timeout configuration for all HTTP requests
/// Prevents app from hanging indefinitely on network issues
class NetworkConfig {
  // Detection server timeouts (should be very fast even over internet)
  static const Duration detectionFetchTimeout = Duration(seconds: 3); // Reduced from 5s
  static const Duration detectionStreamTimeout = Duration(seconds: 3); // Reduced from 5s

  // AI API timeouts
  static const Duration geminiRequestTimeout = Duration(seconds: 30);
  static const Duration geminiStreamTimeout = Duration(seconds: 45);

  // Supabase timeouts
  static const Duration supabaseQueryTimeout = Duration(seconds: 15);
  static const Duration supabaseMutationTimeout = Duration(seconds: 20);

  // General timeouts
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration longOperationTimeout = Duration(seconds: 60);

  // Retry configuration - fail fast
  static const int maxRetries = 1; // Reduced from 2 - retry only once
  static const int initialBackoffMs = 200; // Reduced from 300ms - faster retry
  static const double backoffMultiplier = 1.5; // Reduced from 2.0 - less exponential backoff
}
