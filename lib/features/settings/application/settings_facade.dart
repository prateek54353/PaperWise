import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/settings/application/usecases/check_updates_usecase.dart';
import 'package:paperwise_pdf_maker/features/settings/application/usecases/update_settings_usecase.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/entities/settings_entity.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/repositories/settings_repository.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/compression_level.dart';

/// Facade for settings operations - orchestrates use cases
class SettingsFacade {
  final SettingsRepository repository;
  late final UpdateSettingsUseCase updateSettings;
  late final CheckUpdatesUseCase checkUpdates;

  SettingsFacade(this.repository) {
    updateSettings = UpdateSettingsUseCase(repository);
    checkUpdates = CheckUpdatesUseCase(repository);
  }

  /// Get current settings
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    return await repository.getSettings();
  }

  /// Update theme mode
  Future<Either<Failure, SettingsEntity>> updateThemeMode(ThemeMode themeMode) async {
    return await updateSettings(themeMode: themeMode);
  }

  /// Update compression level
  Future<Either<Failure, SettingsEntity>> updateCompressionLevel(CompressionLevel level) async {
    return await updateSettings(compressionLevel: level);
  }

  /// Update AMOLED theme preference
  Future<Either<Failure, SettingsEntity>> updateAmoledTheme(bool useAmoled) async {
    return await updateSettings(useAmoledTheme: useAmoled);
  }

  /// Update temp cleanup settings
  Future<Either<Failure, SettingsEntity>> updateTempCleanupSettings({
    required bool enabled,
    Duration? period,
  }) async {
    return await updateSettings(
      enableTempCleanup: enabled,
      tempCleanupPeriod: period,
    );
  }

  /// Check for app updates
  Future<Either<Failure, String?>> checkForUpdates() async {
    return await checkUpdates();
  }
}
