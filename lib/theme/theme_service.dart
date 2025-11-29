import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'isDark';

  /// Save the theme mode
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);
  }

  /// Load the saved theme mode
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.get(_themeKey); // dynamic

    if (storedValue is bool) {
      return storedValue ? ThemeMode.dark : ThemeMode.light;
    } else if (storedValue is int) {
      // Handle old int values (1 = dark, 0 = light)
      return storedValue == 1 ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Default
      return ThemeMode.light;
    }
  }
}
