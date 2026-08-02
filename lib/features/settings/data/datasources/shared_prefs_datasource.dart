import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

abstract class SettingsDataSource {
  Future<SettingsModel> loadSettings();
  Future<void> saveSettings(SettingsModel settings);
}

class SharedPrefsDataSource implements SettingsDataSource {
  static const _themeModeKey = 'themeMode';
  static const _compressionLevelKey = 'compressionLevel';
  static const _useAmoledThemeKey = 'useAmoledTheme';
  static const _enableTempCleanupKey = 'enableTempCleanup';
  static const _tempCleanupPeriodKey = 'tempCleanupPeriodDays';

  @override
  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final compressionLevelIndex = prefs.getInt(_compressionLevelKey) ?? 1; // medium
    final useAmoledTheme = prefs.getBool(_useAmoledThemeKey) ?? false;
    final enableTempCleanup = prefs.getBool(_enableTempCleanupKey) ?? false;
    final tempCleanupPeriodDays = prefs.getInt(_tempCleanupPeriodKey) ?? 30;

    return SettingsModel(
      themeModeIndex: themeModeIndex,
      compressionLevelIndex: compressionLevelIndex,
      useAmoledTheme: useAmoledTheme,
      enableTempCleanup: enableTempCleanup,
      tempCleanupPeriodDays: tempCleanupPeriodDays,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeModeIndex);
    await prefs.setInt(_compressionLevelKey, settings.compressionLevelIndex);
    await prefs.setBool(_useAmoledThemeKey, settings.useAmoledTheme);
    await prefs.setBool(_enableTempCleanupKey, settings.enableTempCleanup);
    await prefs.setInt(_tempCleanupPeriodKey, settings.tempCleanupPeriodDays);
  }
}
