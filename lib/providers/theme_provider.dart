import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';

  AppTheme _themeMode = AppTheme.system;

  ThemeProvider() {
    _loadTheme();
  }

  AppTheme get themeMode => _themeMode;

  ThemeMode get themeModeValue {
    switch (_themeMode) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2;
    _themeMode = AppTheme.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _themeMode = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case AppTheme.light:
        await setTheme(AppTheme.dark);
        break;
      case AppTheme.dark:
        await setTheme(AppTheme.system);
        break;
      case AppTheme.system:
        await setTheme(AppTheme.light);
        break;
    }
  }

  bool isDarkMode(BuildContext context) {
    if (_themeMode == AppTheme.system) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      return brightness == Brightness.dark;
    }
    return _themeMode == AppTheme.dark;
  }
}
