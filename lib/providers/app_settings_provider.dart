// lib/providers/app_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app settings and preferences
/// Handles live updates toggle, notifications, offline mode, and update intervals
class AppSettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Settings state
  bool _liveUpdatesEnabled = true;
  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = false;
  int _updateIntervalSeconds = 10;

  // Getters
  bool get liveUpdatesEnabled => _liveUpdatesEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  int get updateIntervalSeconds => _updateIntervalSeconds;

  // Initialize from storage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    _liveUpdatesEnabled = _prefs.getBool('liveUpdatesEnabled') ?? true;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _offlineModeEnabled = _prefs.getBool('offlineModeEnabled') ?? false;
    _updateIntervalSeconds = _prefs.getInt('updateIntervalSeconds') ?? 10;
    notifyListeners();
  }

  // Toggle live updates
  Future<void> toggleLiveUpdates(bool value) async {
    _liveUpdatesEnabled = value;
    await _prefs.setBool('liveUpdatesEnabled', value);

    notifyListeners();
    print('📡 Live Updates: ${value ? 'ON' : 'OFF'}');
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notificationsEnabled', value);

    notifyListeners();
    print('🔔 Notifications: ${value ? 'ON' : 'OFF'}');
  }

  // Toggle offline mode
  Future<void> toggleOfflineMode(bool value) async {
    _offlineModeEnabled = value;
    await _prefs.setBool('offlineModeEnabled', value);

    if (value) {
      print('📴 Offline Mode: ENABLED - Using local cache');
    } else {
      print('📡 Offline Mode: DISABLED - Using live data');
    }

    notifyListeners();
  }

  // Set update interval
  Future<void> setUpdateInterval(int seconds) async {
    _updateIntervalSeconds = seconds;
    await _prefs.setInt('updateIntervalSeconds', seconds);

    notifyListeners();
    print('⏱️ Update Interval: ${seconds}s');
  }
}
