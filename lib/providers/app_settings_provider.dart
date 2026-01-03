// lib/providers/app_settings_provider.dart
import 'package:flutter/material.dart';

/// Provider for managing app settings and preferences
class AppSettingsProvider extends ChangeNotifier {
  // Initialize from storage
  Future<void> initialize() async {
    // No user-facing settings currently stored.
    notifyListeners();
  }
}
