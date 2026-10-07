import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервиз за управление на темата (System / Light / Dark).
class ThemeService {
  static const String _key = 'theme_mode';

  /// Текуща тема (може да се слуша от widget-и).
  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier(ThemeMode.system);

  /// Зарежда запазената тема от SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        themeMode.value = ThemeMode.values.byName(saved);
      } catch (_) {
        themeMode.value = ThemeMode.system;
      }
    }
  }

  /// Задава нова тема и я запазва.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}