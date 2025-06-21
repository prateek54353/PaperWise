import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:paperwise_pdf_maker/services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings;
  final SettingsService _settingsService;

  SettingsProvider(this._settings, this._settingsService);

  AppSettings get settings => _settings;

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updatePdfQuality(PdfQuality quality) async {
    _settings = _settings.copyWith(pdfQuality: quality);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateAmoledTheme(bool value) async {
    _settings = _settings.copyWith(useAmoledTheme: value);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }
}