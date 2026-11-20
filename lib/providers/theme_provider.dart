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

enum AppLanguage {
  system,
  english,
  japanese,
  hungarian,
  french,
  chineseSimplified,
}

extension AppLanguageExtension on AppLanguage {
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.hungarian => const Locale('hu'),
    AppLanguage.french => const Locale('fr'),
    AppLanguage.chineseSimplified => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    ),
  };

  String get displayName => switch (this) {
    AppLanguage.system => 'System default',
    AppLanguage.english => 'English',
    AppLanguage.japanese => '日本語',
    AppLanguage.hungarian => 'Magyar',
    AppLanguage.french => 'Français',
    AppLanguage.chineseSimplified => '简体中文',
  };
}

class ThemeProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _textSizeKey = 'text_size';
  static const _appLanguageKey = 'app_language';

  ThemeMode _themeMode = ThemeMode.system;
  AppTextSize _textSize = AppTextSize.medium;
  AppLanguage _appLanguage = AppLanguage.system;

  ThemeMode get themeMode => _themeMode;

  AppTextSize get textSize => _textSize;

  AppLanguage get appLanguage => _appLanguage;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_themeModeKey);
    final savedTextSize = prefs.getString(_textSizeKey);
    final savedLanguage = prefs.getString(_appLanguageKey);

    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );

    _textSize = AppTextSize.values.firstWhere(
      (size) => size.name == savedTextSize,
      orElse: () => AppTextSize.medium,
    );

    _appLanguage = AppLanguage.values.firstWhere(
      (language) => language.name == savedLanguage,
      orElse: () => AppLanguage.system,
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

  Future<void> setAppLanguage(AppLanguage language) async {
    if (_appLanguage == language) return;

    _appLanguage = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, language.name);
  }
}
