import 'package:flutter/foundation.dart';

/// Minimal logger that only prints in debug builds.
/// Use instead of `print()` to satisfy `avoid_print` and reduce production noise.
void appLog(String message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}
