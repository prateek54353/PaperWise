enum CompressionLevel {
  none, // Original quality
  high, // 90% quality
  medium, // 80% quality
  low, // 65% quality
  minimal // 50% quality
}

extension CompressionLevelExtension on CompressionLevel {
  int get quality {
    switch (this) {
      case CompressionLevel.none:
        return 100;
      case CompressionLevel.high:
        return 90;
      case CompressionLevel.medium:
        return 80;
      case CompressionLevel.low:
        return 65;
      case CompressionLevel.minimal:
        return 50;
    }
  }

  String getDescription() {
    switch (this) {
      case CompressionLevel.none:
        return 'No compression (100%)';
      case CompressionLevel.high:
        return 'High quality (90%), good compression';
      case CompressionLevel.medium:
        return 'Medium quality (80%), better compression';
      case CompressionLevel.low:
        return 'Low quality (65%), strong compression';
      case CompressionLevel.minimal:
        return 'Minimal quality (50%), maximum compression';
    }
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}
