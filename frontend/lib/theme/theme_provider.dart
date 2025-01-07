// lib/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'button_styles.dart';
import '../database/postgreSQL_logic.dart';
import '../globals.dart';

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

  ThemeData getTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark 
          ? AppColors.darkBackground 
          : AppColors.lightBackground,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.elevated,
      ),
    );
  }
}
