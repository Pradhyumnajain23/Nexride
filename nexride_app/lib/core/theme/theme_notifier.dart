import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted theme toggle — provides ThemeMode to the whole app.
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'nexride_theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark ||
      (_mode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  ThemeNotifier() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val   = prefs.getString(_key);
    if (val == 'dark')   _mode = ThemeMode.dark;
    else if (val == 'light') _mode = ThemeMode.light;
    else                 _mode = ThemeMode.system;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = (_mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setSystem() async {
    _mode = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'system');
    notifyListeners();
  }
}
