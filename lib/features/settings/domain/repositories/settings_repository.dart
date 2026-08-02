import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<Either<Failure, SettingsEntity>> getSettings();
  Future<Either<Failure, void>> saveSettings(SettingsEntity settings);
  Future<Either<Failure, String?>> checkForUpdates();
}
