/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Paperwise';
  static const String appVersion = '2.4.1';

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
}
