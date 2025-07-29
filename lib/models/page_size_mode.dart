/// Defines the available page size modes for PDF generation
enum PageSizeMode {
  a4,
  letter,
  legal,
  fit,
}

extension PageSizeModeExtension on PageSizeMode {
  String get displayName {
    switch (this) {
      case PageSizeMode.a4: return 'A4';
      case PageSizeMode.letter: return 'Letter';
      case PageSizeMode.legal: return 'Legal';
      case PageSizeMode.fit: return 'Fit';
    }
  }
} 