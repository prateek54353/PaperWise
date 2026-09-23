enum PageSizeMode {
  fit,
  a4,
  letter,
  legal,
}

extension PageSizeModeExtension on PageSizeMode {
  String get displayName {
    switch (this) {
      case PageSizeMode.fit:
        return 'Fit to Image';
      case PageSizeMode.a4:
        return 'A4';
      case PageSizeMode.letter:
        return 'Letter';
      case PageSizeMode.legal:
        return 'Legal';
    }
  }
}