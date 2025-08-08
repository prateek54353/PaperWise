import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/screens/about_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    const repoUrl = 'https://api.github.com/repos/prateek54353/paperwise/releases/latest';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Current version: $currentVersion\nChecking for updates...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final response = await http.get(Uri.parse(repoUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latestVersion = (json['tag_name'] as String).replaceAll('v', '');
        final releaseUrl = json['html_url'] as String;

        if (latestVersion.compareTo(currentVersion) > 0) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Update Available'),
                content: Text('A new version ($latestVersion) is available. Would you like to update?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: () {
                      _launchUrl(context, releaseUrl);
                      Navigator.pop(context);
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            );
          }
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('You are running the latest version')),
          );
        }
      } else {
        throw Exception('Failed to load release info');
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to check for updates'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            children: [
              RadioListTile<ThemeMode>(
                title: Text(_themeModeToString(ThemeMode.light)),
                value: ThemeMode.light,
                groupValue: provider.settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(_themeModeToString(ThemeMode.dark)),
                value: ThemeMode.dark,
                groupValue: provider.settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(_themeModeToString(ThemeMode.system)),
                value: ThemeMode.system,
                groupValue: provider.settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompressionDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Compression'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<CompressionLevel>(
                title: Text(CompressionLevel.low.name[0].toUpperCase() + CompressionLevel.low.name.substring(1)),
                subtitle: Text(CompressionLevel.low.getDescription()),
                value: CompressionLevel.low,
                groupValue: provider.settings.compressionLevel,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateCompressionLevel(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<CompressionLevel>(
                title: Text(CompressionLevel.medium.name[0].toUpperCase() + CompressionLevel.medium.name.substring(1)),
                subtitle: Text(CompressionLevel.medium.getDescription()),
                value: CompressionLevel.medium,
                groupValue: provider.settings.compressionLevel,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateCompressionLevel(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<CompressionLevel>(
                title: Text(CompressionLevel.high.name[0].toUpperCase() + CompressionLevel.high.name.substring(1)),
                subtitle: Text(CompressionLevel.high.getDescription()),
                value: CompressionLevel.high,
                groupValue: provider.settings.compressionLevel,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateCompressionLevel(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }

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

  String _cleanupPeriodToString(Duration period) {
    if (period.inDays == 30) {
      return 'Every month';
    } else if (period.inDays == 90) {
      return 'Every 3 months';
    } else if (period.inDays == 270) {
      return 'Every 9 months';
    } else if (period.inDays == 365) {
      return 'Every year';
    } else {
      return 'Every ${period.inDays} days';
    }
  }

  void _showCleanupPeriodDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Cleanup Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Duration>(
                title: Text(_cleanupPeriodToString(const Duration(days: 30))),
                value: const Duration(days: 30),
                groupValue: provider.settings.tempCleanupPeriod,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateTempCleanupPeriod(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<Duration>(
                title: Text(_cleanupPeriodToString(const Duration(days: 90))),
                value: const Duration(days: 90),
                groupValue: provider.settings.tempCleanupPeriod,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateTempCleanupPeriod(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<Duration>(
                title: Text(_cleanupPeriodToString(const Duration(days: 270))),
                value: const Duration(days: 270),
                groupValue: provider.settings.tempCleanupPeriod,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateTempCleanupPeriod(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<Duration>(
                title: Text(_cleanupPeriodToString(const Duration(days: 365))),
                value: const Duration(days: 365),
                groupValue: provider.settings.tempCleanupPeriod,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateTempCleanupPeriod(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

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
              _buildSectionHeader(context, 'Image Quality'),
              ListTile(
                leading: const Icon(Icons.compress_outlined),
                title: const Text('Image Compression'),
                subtitle: Text(settingsProvider.settings.compressionLevel.getDescription()),
                onTap: () => _showCompressionDialog(context, settingsProvider),
              ),
              const Divider(),
              _buildSectionHeader(context, 'Temp File Cleanup'),
              SwitchListTile(
                secondary: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Enable Temp File Cleanup'),
                subtitle: const Text('Automatically delete old temporary files'),
                value: settingsProvider.settings.enableTempCleanup,
                onChanged: (value) => settingsProvider.updateEnableTempCleanup(value),
              ),
              if (settingsProvider.settings.enableTempCleanup)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Cleanup Period'),
                  subtitle: Text(_cleanupPeriodToString(settingsProvider.settings.tempCleanupPeriod)),
                  onTap: () => _showCleanupPeriodDialog(context, settingsProvider),
                ),
              const Divider(),
              _buildSectionHeader(context, 'Updates'),
              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: const Text('Check for Updates'),
                subtitle: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Loading...');
                    return Text('Current version: ${snapshot.data!.version}');
                  },
                ),
                onTap: () => _checkForUpdates(context),
              ),
              const Divider(),
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
}