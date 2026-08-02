import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/repositories/settings_repository.dart';

class CheckUpdatesUseCase {
  final SettingsRepository repository;

  CheckUpdatesUseCase(this.repository);

  Future<Either<Failure, String?>> call() async {
    return await repository.checkForUpdates();
  }
}
