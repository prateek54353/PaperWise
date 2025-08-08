import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/screens/legal/privacy_policy_screen.dart';
import 'package:paperwise_pdf_maker/screens/legal/terms_screen.dart';
import 'package:paperwise_pdf_maker/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// A redesigned screen that displays information about the app and developer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _sponsorUrl = 'https://coff.ee/prateek.aish';

  /// Launches a URL and shows an error if it fails.
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  /// contact email 
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: kContactEmail,
      query: 'subject=Paperwise App Feedback (v$kAppVersion)', // Pre-fills the subject
    );
    _launchUrl(context, emailUri.toString());
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 60),
                  const SizedBox(height: 8.0),
                  Text(kAppTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Version $kAppVersion', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16.0),
                  Text('Prateek', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  const Text(
                    'A passionate developer , dedicated to creating simple and useful open-source tools like Paperwise.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(context, _sponsorUrl),
                        icon: const Icon(Icons.coffee_outlined),
                        label: const Text('Sponsor'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => _launchUrl(context, 'https://github.com/prateek54353'),
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Lower Section: App Version, Legal, and Licenses
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('More Info & Support', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          // NEW: "Contact Us" button
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact & Support'),
            subtitle: const Text('Report a bug or give feedback'),
            onTap: () => _launchEmail(context),
          ),
          const Divider(indent: 16, endIndent: 16),
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
            child: Text('Made with ❤️ ', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            )),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}