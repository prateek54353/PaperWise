import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/screens/about_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist and load app settings.
class SettingsService {
  static const _themeModeKey = 'themeMode';
  static const _pdfQualityKey = 'pdfQuality';
  static const _useAmoledThemeKey = 'useAmoledTheme';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final pdfQualityIndex = prefs.getInt(_pdfQualityKey) ?? PdfQuality.high.index;
    final useAmoledTheme = prefs.getBool(_useAmoledThemeKey) ?? false;

    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      pdfQuality: PdfQuality.values[pdfQualityIndex],
      useAmoledTheme: useAmoledTheme,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setInt(_pdfQualityKey, settings.pdfQuality.index);
    await prefs.setBool(_useAmoledThemeKey, settings.useAmoledTheme);
  }
}

/// A screen that allows the user to configure app settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        bool isDarkModeActive = MediaQuery.of(context).platformBrightness == Brightness.dark;
        bool isAmoledSwitchEnabled = settingsProvider.settings.themeMode == ThemeMode.dark ||
            (settingsProvider.settings.themeMode == ThemeMode.system && isDarkModeActive);

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              _buildSectionHeader(context, 'Appearance'),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeModeToString(settingsProvider.settings.themeMode)),
                onTap: () => _showThemeDialog(context, settingsProvider),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Use AMOLED Black Theme'),
                subtitle: const Text('Uses a pure black background for dark mode'),
                value: settingsProvider.settings.useAmoledTheme,
                onChanged: isAmoledSwitchEnabled
                    ? (value) => settingsProvider.updateAmoledTheme(value)
                    : null,
              ),
              const Divider(),
              _buildSectionHeader(context, 'PDF Settings'),
              ListTile(
                leading: const Icon(Icons.high_quality_outlined),
                title: const Text('PDF Quality'),
                subtitle: const Text('Sets the compression level for images.'),
                trailing: DropdownButton<PdfQuality>(
                  value: settingsProvider.settings.pdfQuality,
                  onChanged: (quality) {
                    if (quality != null) {
                      settingsProvider.updatePdfQuality(quality);
                    }
                  },
                  items: PdfQuality.values.map((quality) {
                    return DropdownMenuItem(
                      value: quality,
                      child: Text(_qualityToString(quality)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              // New ListTile to navigate to the About screen
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Paperwise'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods remain the same
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }
  
  String _qualityToString(PdfQuality quality) {
      switch (quality) {
      case PdfQuality.low: return 'Low';
      case PdfQuality.medium: return 'Medium';
      case PdfQuality.high: return 'High';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_themeModeToString(mode)),
                value: mode,
                groupValue: provider.settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}