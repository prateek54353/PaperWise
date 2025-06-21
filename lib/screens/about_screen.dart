import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/screens/legal/privacy_policy_screen.dart';
import 'package:paperwise_pdf_maker/screens/legal/terms_screen.dart';
import 'package:paperwise_pdf_maker/utils/constants.dart';

import 'package:url_launcher/url_launcher.dart';

/// A redesigned screen that displays information about the app and developer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Replace with your actual sponsor link
  static const String _sponsorUrl = 'YOUR_SPONSOR_LINK_HERE';
  static const String _developerName = 'Prateek';
  static const String _developerBio =
      'A passionate developer from  India, dedicated to creating simple and useful open-source tools like Paperwise.';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        children: [
          // Upper Section: Developer Info and Sponsor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Replace with your app icon
                  Icon(Icons.document_scanner_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8.0),
                  Text(kAppTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text(kAppVersion, style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  )), // withOpacity is still supported for Color

                  const SizedBox(height: 16.0),
                  Text(_developerName, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8.0),
                  Text(_developerBio, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    onPressed: _sponsorUrl.startsWith('YOUR') ? null : () => _launchUrl(context, _sponsorUrl),
                    icon: const Icon(Icons.coffee_outlined),
                    label: const Text('Sponsor'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Lower Section: App Version, Legal, and Licenses
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('More Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(kAppVersion),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms & Conditions'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: kAppTitle,
              applicationVersion: kAppVersion,
            ),
          ),
          const SizedBox(height: 24.0),
          Center(
            child: Text('Made with ❤️ in India', style: theme.textTheme.bodySmall != null && theme.textTheme.bodySmall!.color != null
                ? theme.textTheme.bodySmall!.copyWith(color: theme.textTheme.bodySmall!.color!.withOpacity(0.6))
                : theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}