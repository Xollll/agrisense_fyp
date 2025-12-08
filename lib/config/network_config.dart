// lib/config/network_config.dart

/// Network timeout configuration for all HTTP requests
/// Prevents app from hanging indefinitely on network issues
class NetworkConfig {
  // Detection server timeouts
  static const Duration detectionFetchTimeout = Duration(seconds: 10);
  static const Duration detectionStreamTimeout = Duration(seconds: 15);

  // AI API timeouts
  static const Duration geminiRequestTimeout = Duration(seconds: 30);
  static const Duration geminiStreamTimeout = Duration(seconds: 45);

  // Supabase timeouts
  static const Duration supabaseQueryTimeout = Duration(seconds: 15);
  static const Duration supabaseMutationTimeout = Duration(seconds: 20);

  // General timeouts
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration longOperationTimeout = Duration(seconds: 60);

  // Retry configuration
  static const int maxRetries = 3;
  static const int initialBackoffMs = 500;
  static const double backoffMultiplier = 2.0;
}
