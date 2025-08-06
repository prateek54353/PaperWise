import 'package:flutter/material.dart';

enum CompressionLevel {
  none,     // Original quality
  high,     // 90% quality
  medium,   // 80% quality
  low,      // 65% quality
  minimal   // 50% quality
}

extension CompressionLevelExtension on CompressionLevel {
  int get quality {
    switch (this) {
      case CompressionLevel.none: return 100;
      case CompressionLevel.high: return 90;
      case CompressionLevel.medium: return 80;
      case CompressionLevel.low: return 65;
      case CompressionLevel.minimal: return 50;
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
}

class AppSettings {
  final ThemeMode themeMode;
  final CompressionLevel compressionLevel;
  final bool useAmoledTheme;
  final bool enableTempCleanup;
  final Duration tempCleanupPeriod;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.compressionLevel = CompressionLevel.medium,
    this.useAmoledTheme = false,
    this.enableTempCleanup = false, // Changed default to false
    this.tempCleanupPeriod = const Duration(days: 30),
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    CompressionLevel? compressionLevel,
    bool? useAmoledTheme,
    bool? enableTempCleanup,
    Duration? tempCleanupPeriod,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      useAmoledTheme: useAmoledTheme ?? this.useAmoledTheme,
      enableTempCleanup: enableTempCleanup ?? this.enableTempCleanup,
      tempCleanupPeriod: tempCleanupPeriod ?? this.tempCleanupPeriod,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          compressionLevel == other.compressionLevel &&
          useAmoledTheme == other.useAmoledTheme &&
          enableTempCleanup == other.enableTempCleanup &&
          tempCleanupPeriod == other.tempCleanupPeriod;

  @override
  int get hashCode => Object.hash(themeMode, compressionLevel, useAmoledTheme, enableTempCleanup, tempCleanupPeriod);
}