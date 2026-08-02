import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/utils/extensions.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/compression_level.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/theme_mode.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/screens/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
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

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    const releaseUrl =
        'https://github.com/prateek54353/PaperWise/releases/latest';

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Checking for updates...'),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await ref.read(settingsFacadeProvider).checkForUpdates();
    if (!context.mounted) return;

    result.fold(
      (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to check for updates'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (latestVersion) {
        if (latestVersion == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('You are running the latest version')),
          );
          return;
        }
        _showUpdateDialog(context, latestVersion, releaseUrl);
      },
    );
  }

  void _showUpdateDialog(
      BuildContext context, String latestVersion, String releaseUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
            'A new version ($latestVersion) is available. Would you like to update?'),
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

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(settingsProvider).settings.themeMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(mode.displayName),
                value: mode,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(value);
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

  void _showCompressionDialog(BuildContext context, WidgetRef ref) {
    final currentLevel = ref.read(settingsProvider).settings.compressionLevel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Compression'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: CompressionLevel.values.map((level) {
              return RadioListTile<CompressionLevel>(
                title: Text(level.displayName),
                subtitle: Text(level.getDescription()),
                value: level,
                groupValue: currentLevel,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateCompressionLevel(value);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;

    if (settingsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(settings.themeMode.displayName),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (_) => _showThemeDialog(context, ref),
          ),
          SwitchListTile(
            title: const Text('AMOLED Dark Mode'),
            subtitle: const Text('Pure black background'),
            value: settings.useAmoledTheme,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAmoledTheme(value);
            },
          ),
          _buildSectionHeader(context, 'Image Quality'),
          ListTile(
            title: const Text('Compression Level'),
            subtitle: Text(settings.compressionLevel.getDescription()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCompressionDialog(context, ref),
          ),
          _buildSectionHeader(context, 'Storage'),
          SwitchListTile(
            title: const Text('Auto Cleanup Temp Files'),
            subtitle: const Text('Automatically clean temporary files'),
            value: settings.enableTempCleanup,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateTempCleanupSettings(
                    enabled: value,
                    period: settings.tempCleanupPeriod,
                  );
            },
          ),
          if (settings.enableTempCleanup)
            ListTile(
              title: const Text('Cleanup Period'),
              subtitle: Text(settings.tempCleanupPeriod.toReadableString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCleanupPeriodDialog(context, ref),
            ),
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Check for Updates'),
            trailing: const Icon(Icons.system_update),
            onTap: () => _checkForUpdates(context, ref),
          ),
          ListTile(
            title: const Text('About'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
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

  void _showCleanupPeriodDialog(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.read(settingsProvider).settings.tempCleanupPeriod;
    final periods = [
      const Duration(days: 30),
      const Duration(days: 90),
      const Duration(days: 270),
      const Duration(days: 365),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Cleanup Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((period) {
              return RadioListTile<Duration>(
                title: Text(period.toReadableString()),
                value: period,
                groupValue: currentPeriod,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateTempCleanupSettings(
                          enabled: true,
                          period: value,
                        );
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
