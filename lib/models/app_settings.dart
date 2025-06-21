import 'package:flutter/material.dart';

enum PdfQuality { low, medium, high }

class AppSettings {
  final ThemeMode themeMode;
  final PdfQuality pdfQuality;
  final bool useAmoledTheme;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.pdfQuality = PdfQuality.high, // Default quality is now High
    this.useAmoledTheme = false,
  });

  int get compressionQuality {
    switch (pdfQuality) {
      case PdfQuality.low:
        return 50;
      case PdfQuality.medium:
        return 80;
      case PdfQuality.high:
        return 95;
    }
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    PdfQuality? pdfQuality,
    bool? useAmoledTheme,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      pdfQuality: pdfQuality ?? this.pdfQuality,
      useAmoledTheme: useAmoledTheme ?? this.useAmoledTheme,
    );
  }
}