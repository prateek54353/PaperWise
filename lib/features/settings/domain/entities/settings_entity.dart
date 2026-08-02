import 'package:flutter/material.dart';
import '../value_objects/compression_level.dart';

class SettingsEntity {
  final ThemeMode themeMode;
  final CompressionLevel compressionLevel;
  final bool useAmoledTheme;
  final bool enableTempCleanup;
  final Duration tempCleanupPeriod;

  const SettingsEntity({
    this.themeMode = ThemeMode.system,
    this.compressionLevel = CompressionLevel.medium,
    this.useAmoledTheme = false,
    this.enableTempCleanup = false,
    this.tempCleanupPeriod = const Duration(days: 30),
  });

  SettingsEntity copyWith({
    ThemeMode? themeMode,
    CompressionLevel? compressionLevel,
    bool? useAmoledTheme,
    bool? enableTempCleanup,
    Duration? tempCleanupPeriod,
  }) {
    return SettingsEntity(
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
      other is SettingsEntity &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          compressionLevel == other.compressionLevel &&
          useAmoledTheme == other.useAmoledTheme &&
          enableTempCleanup == other.enableTempCleanup &&
          tempCleanupPeriod == other.tempCleanupPeriod;

  @override
  int get hashCode =>
      Object.hash(themeMode, compressionLevel, useAmoledTheme,
          enableTempCleanup, tempCleanupPeriod);
}
