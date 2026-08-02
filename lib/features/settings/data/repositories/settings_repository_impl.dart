import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/shared_prefs_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _latestReleaseUrl =
      'https://api.github.com/repos/prateek54353/PaperWise/releases/latest';

  final SettingsDataSource dataSource;

  SettingsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    try {
      final model = await dataSource.loadSettings();
      return Right(model.toEntity());
    } catch (e) {
      return Left(SettingsFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(SettingsEntity settings) async {
    try {
      final model = SettingsModel.fromEntity(settings);
      await dataSource.saveSettings(model);
      return const Right(null);
    } catch (e) {
      return Left(SettingsFailure('Failed to save settings: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse(_latestReleaseUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 404) {
        return const Right(null);
      }
      if (response.statusCode != 200) {
        throw Exception('GitHub returned HTTP ${response.statusCode}');
      }

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = (release['tag_name'] as String?)
          ?.replaceFirst(RegExp(r'^[vV]'), '')
          .trim();

      if (latestVersion == null || latestVersion.isEmpty) {
        throw const FormatException('The latest release has no version tag');
      }

      return Right(
        _isNewerVersion(latestVersion, packageInfo.version)
            ? latestVersion
            : null,
      );
    } catch (e) {
      return Left(NetworkFailure('Failed to check for updates: $e'));
    }
  }

  bool _isNewerVersion(String candidate, String current) {
    final candidateParts = _versionParts(candidate);
    final currentParts = _versionParts(current);
    final length = candidateParts.length > currentParts.length
        ? candidateParts.length
        : currentParts.length;

    for (var index = 0; index < length; index++) {
      final candidatePart =
          index < candidateParts.length ? candidateParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      if (candidatePart != currentPart) {
        return candidatePart > currentPart;
      }
    }
    return false;
  }

  List<int> _versionParts(String version) {
    final normalized = version
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('+')
        .first
        .split('-')
        .first;
    return normalized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
