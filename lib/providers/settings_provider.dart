import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/services/settings_service.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;
  late AppSettings _settings;
  bool _isLoading = true;

  SettingsProvider(this._settingsService) {
    _loadSettings();
  }

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> _loadSettings() async {
    _settings = await _settingsService.loadSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateCompressionLevel(CompressionLevel compressionLevel) async {
    _settings = _settings.copyWith(compressionLevel: compressionLevel);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateAmoledTheme(bool useAmoledTheme) async {
    _settings = _settings.copyWith(useAmoledTheme: useAmoledTheme);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateEnableTempCleanup(bool value) async {
    _settings = _settings.copyWith(enableTempCleanup: value);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateTempCleanupPeriod(Duration period) async {
    _settings = _settings.copyWith(tempCleanupPeriod: period);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }
}