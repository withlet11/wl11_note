// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextSize { small, medium, large }

extension AppTextSizeExtension on AppTextSize {
  double get scaleFactor => switch (this) {
    AppTextSize.small => 0.9,
    AppTextSize.medium => 1.0,
    AppTextSize.large => 1.15,
  };
}

class ThemeProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _textSizeKey = 'text_size';

  ThemeMode _themeMode = ThemeMode.system;
  AppTextSize _textSize = AppTextSize.medium;

  ThemeMode get themeMode => _themeMode;

  AppTextSize get textSize => _textSize;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_themeModeKey);
    final savedTextSize = prefs.getString(_textSizeKey);

    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );

    _textSize = AppTextSize.values.firstWhere(
      (size) => size.name == savedTextSize,
      orElse: () => AppTextSize.medium,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setTextSize(AppTextSize size) async {
    if (_textSize == size) return;

    _textSize = size;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size.name);
  }
}
