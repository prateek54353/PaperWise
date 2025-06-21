import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/utils/constants.dart';

/// Displays the application's Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(kPrivacyPolicyText),
      ),
    );
  }
}