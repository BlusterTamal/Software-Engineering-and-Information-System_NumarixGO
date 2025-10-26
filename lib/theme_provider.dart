/*
 * File: lib/theme_provider.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/theme_provider.dart
 * Description: Theme management provider for light/dark mode switching
 */

import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return false;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}