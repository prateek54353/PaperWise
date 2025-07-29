import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service to persist and load app settings.
class SettingsService {
  static const _themeModeKey = 'themeMode';
  static const _compressionLevelKey = 'compressionLevel';
  static const _useAmoledThemeKey = 'useAmoledTheme';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final compressionLevelIndex = prefs.getInt(_compressionLevelKey) ?? CompressionLevel.medium.index;
    final useAmoledTheme = prefs.getBool(_useAmoledThemeKey) ?? false;

    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      compressionLevel: CompressionLevel.values[compressionLevelIndex],
      useAmoledTheme: useAmoledTheme,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setInt(_compressionLevelKey, settings.compressionLevel.index);
    await prefs.setBool(_useAmoledThemeKey, settings.useAmoledTheme);
  }

  /// Checks for updates by comparing current version with latest release
  Future<String?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
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