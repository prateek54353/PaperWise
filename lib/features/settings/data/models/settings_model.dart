import 'package:flutter/material.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/value_objects/compression_level.dart';

class SettingsModel {
  final int themeModeIndex;
  final int compressionLevelIndex;
  final bool useAmoledTheme;
  final bool enableTempCleanup;
  final int tempCleanupPeriodDays;

  const SettingsModel({
    required this.themeModeIndex,
    required this.compressionLevelIndex,
    required this.useAmoledTheme,
    required this.enableTempCleanup,
    required this.tempCleanupPeriodDays,
  });

  // Convert from entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      themeModeIndex: entity.themeMode.index,
      compressionLevelIndex: entity.compressionLevel.index,
      useAmoledTheme: entity.useAmoledTheme,
      enableTempCleanup: entity.enableTempCleanup,
      tempCleanupPeriodDays: entity.tempCleanupPeriod.inDays,
    );
  }

  // Convert to entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      themeMode: ThemeMode.values[themeModeIndex],
      compressionLevel: CompressionLevel.values[compressionLevelIndex],
      useAmoledTheme: useAmoledTheme,
      enableTempCleanup: enableTempCleanup,
      tempCleanupPeriod: Duration(days: tempCleanupPeriodDays),
    );
  }

  SettingsModel copyWith({
    int? themeModeIndex,
    int? compressionLevelIndex,
    bool? useAmoledTheme,
    bool? enableTempCleanup,
    int? tempCleanupPeriodDays,
  }) {
    return SettingsModel(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      compressionLevelIndex: compressionLevelIndex ?? this.compressionLevelIndex,
      useAmoledTheme: useAmoledTheme ?? this.useAmoledTheme,
      enableTempCleanup: enableTempCleanup ?? this.enableTempCleanup,
      tempCleanupPeriodDays: tempCleanupPeriodDays ?? this.tempCleanupPeriodDays,
    );
  }
}
