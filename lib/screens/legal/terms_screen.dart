import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/utils/constants.dart';

/// Displays the application's Terms & Conditions.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(kTermsAndConditionsText),
      ),
    );
  }
}