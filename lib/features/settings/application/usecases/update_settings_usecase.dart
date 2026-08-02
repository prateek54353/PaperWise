import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/entities/settings_entity.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/repositories/settings_repository.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/compression_level.dart';

class UpdateSettingsUseCase {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  Future<Either<Failure, SettingsEntity>> call({
    ThemeMode? themeMode,
    CompressionLevel? compressionLevel,
    bool? useAmoledTheme,
    bool? enableTempCleanup,
    Duration? tempCleanupPeriod,
  }) async {
    // First get current settings
    final currentResult = await repository.getSettings();
    
    return currentResult.fold(
      (failure) => Left(failure),
      (currentSettings) async {
        // Update with new values
        final updatedSettings = currentSettings.copyWith(
          themeMode: themeMode,
          compressionLevel: compressionLevel,
          useAmoledTheme: useAmoledTheme,
          enableTempCleanup: enableTempCleanup,
          tempCleanupPeriod: tempCleanupPeriod,
        );
        
        // Save updated settings
        final saveResult = await repository.saveSettings(updatedSettings);
        
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(updatedSettings),
        );
      },
    );
  }
}
