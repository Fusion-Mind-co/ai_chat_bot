// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'database/postgreSQL_logic.dart';
import 'globals.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    if (globalEmail != null) {
      await updateUserData(
        'darkmode',
        {'email': globalEmail, 'isDarkMode': _isDarkMode},
      );
    }
  }
}
