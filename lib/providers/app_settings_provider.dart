// lib/providers/app_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_log.dart';

/// Provider for managing app settings and preferences
/// Handles live updates toggle and notifications
class AppSettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Settings state
  bool _liveUpdatesEnabled = true;
  bool _notificationsEnabled = true;

  // Getters
  bool get liveUpdatesEnabled => _liveUpdatesEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  // Initialize from storage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    _liveUpdatesEnabled = _prefs.getBool('liveUpdatesEnabled') ?? true;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  // Toggle live updates
  Future<void> toggleLiveUpdates(bool value) async {
    _liveUpdatesEnabled = value;
    await _prefs.setBool('liveUpdatesEnabled', value);

    notifyListeners();
    appLog('📡 Live Updates: ${value ? 'ON' : 'OFF'}');
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notificationsEnabled', value);

    notifyListeners();
    appLog('🔔 Notifications: ${value ? 'ON' : 'OFF'}');
  }
}
