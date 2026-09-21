/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Paperwise';
  static const String appVersion = '2.6.1';

  // Storage
  static const String pdfDirectoryName = 'Paperwise';
  static const String pdfSubdirectory = 'PDF';
  static const String imagesSubdirectory = 'Images';
  static const String downloadsSubdirectory = 'PaperWise-PDF';

  // File Naming
  static const String defaultScanName = 'New Scan';
  static const String pdfExtension = '.pdf';
  static const String jpegExtension = '.jpg';
  static const String pngExtension = '.png';

  // Default Values
  static const int defaultCompressionQuality = 80;
  static const Duration defaultTempCleanupPeriod = Duration(days: 30);

  // OCR
  static const double defaultConfidenceThreshold = 0.5;
  static const String defaultOcrLanguage = 'en';

  // UI
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Legal text
  static const String privacyPolicyText = '''
Last updated: June 21, 2025

This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.

We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.

Information Collection and Use
==============================

This application, Paperwise PDF Maker, is designed with your privacy at its core. It is fully functional offline and does not collect, store, or transmit any personal data.

- **No Data Collection**: We do not collect any personal information, such as your name, email address, or location.
- **Local Storage**: All files you create (PDFs) and images you select are stored locally on your device in the application's private directory. We do not have access to these files. These files are deleted when you uninstall the application.
- **No Internet Required**: The core functionality of this app does not require an internet connection. An internet connection is only used if you choose to use the "Share" feature, which uses the device's native sharing capabilities.

Contact Us
----------
If you have any questions about this Privacy Policy, You can contact us via GitHub issues.
''';

  static const String termsAndConditionsText = '''
Last updated: June 21, 2025

Please read these terms and conditions carefully before using Our Service.

Interpretation and Definitions
==============================
The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.

Acknowledgment
==================
These are the Terms and Conditions governing the use of this Service and the agreement that operates between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service.

Your access to and use of the Service is conditioned on Your acceptance of and compliance with these Terms and Conditions. These Terms and Conditions apply to all visitors, users and others who access or use the Service.

By accessing or using the Service You agree to be bound by these Terms and Conditions. If You disagree with any part of these Terms and Conditions then You may not access the Service.

Limitation of Liability
=======================
To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever (including, but not limited to, damages for loss of profits, loss of data or other information, for business interruption, for personal injury, loss of privacy arising out of or in any way related to the use of or inability to use the Service, third-party software and/or third-party hardware used with the Service, or otherwise in connection with any provision of this Terms), even if the Company or any supplier has been advised of the possibility of such damages and even if the remedy fails of its essential purpose.

"AS IS" and "AS AVAILABLE" Disclaimer
=====================================
The Service is provided to You "AS IS" and "AS AVAILABLE" and with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the Company, on its own behalf and on behalf of its Affiliates and its and their respective licensors and service providers, expressly disclaims all warranties, whether express, implied, statutory or otherwise, with respect to the Service, including all implied warranties of merchantability, fitness for a particular purpose, title and non-infringement, and warranties that may arise out of course of dealing, course of performance, usage or trade practice.

Contact Us
----------
If you have any questions about these Terms and Conditions, You can contact us via GitHub issues.
''';
}
