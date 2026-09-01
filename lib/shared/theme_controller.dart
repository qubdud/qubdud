import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

const _kThemeKey = 'dark_mode';

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value =
      (prefs.getBool(_kThemeKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleTheme() async {
  final dark = themeNotifier.value != ThemeMode.dark;
  themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kThemeKey, dark);
}
