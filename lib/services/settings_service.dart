import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist and load app settings.
class SettingsService {
  static const _themeModeKey = 'themeMode';
  static const _compressionLevelKey = 'compressionLevel';
  static const _useAmoledThemeKey = 'useAmoledTheme';
  static const _enableTempCleanupKey = 'enableTempCleanup';
  static const _tempCleanupPeriodKey = 'tempCleanupPeriodDays';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final compressionLevelIndex = prefs.getInt(_compressionLevelKey) ?? CompressionLevel.medium.index;
    final useAmoledTheme = prefs.getBool(_useAmoledThemeKey) ?? false;
    final enableTempCleanup = prefs.getBool(_enableTempCleanupKey) ?? false; // Changed default to false
    final tempCleanupPeriodDays = prefs.getInt(_tempCleanupPeriodKey) ?? 30; // Changed default to 30 days

    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      compressionLevel: CompressionLevel.values[compressionLevelIndex],
      useAmoledTheme: useAmoledTheme,
      enableTempCleanup: enableTempCleanup,
      tempCleanupPeriod: Duration(days: tempCleanupPeriodDays),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setInt(_compressionLevelKey, settings.compressionLevel.index);
    await prefs.setBool(_useAmoledThemeKey, settings.useAmoledTheme);
    await prefs.setBool(_enableTempCleanupKey, settings.enableTempCleanup);
    await prefs.setInt(_tempCleanupPeriodKey, settings.tempCleanupPeriod.inDays);
  }

  /// Checks for updates by comparing current version with latest release
  Future<String?> checkForUpdates() async {
    try {
      
      // Here you would typically make an API call to your update server
      // For now, we'll just return null to indicate no updates
      // In a real implementation, you would:
      // 1. Call your update API
      // 2. Compare versions
      // 3. Return new version if available, null if not
      
      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }
}