import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/settings/application/settings_facade.dart';
import 'package:paperwise_pdf_maker/features/settings/data/datasources/shared_prefs_datasource.dart';
import 'package:paperwise_pdf_maker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/entities/settings_entity.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/repositories/settings_repository.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/compression_level.dart';

// State
class SettingsState {
  final SettingsEntity settings;
  final bool isLoading;
  final Failure? error;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    SettingsEntity? settings,
    bool? isLoading,
    Failure? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsFacade facade;

  SettingsNotifier(this.facade) : super(const SettingsState(settings: SettingsEntity())) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final result = await facade.getSettings();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (settings) => state = state.copyWith(isLoading: false, settings: settings),
    );
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final result = await facade.updateThemeMode(themeMode);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (settings) => state = state.copyWith(settings: settings),
    );
  }

  Future<void> updateCompressionLevel(CompressionLevel level) async {
    final result = await facade.updateCompressionLevel(level);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (settings) => state = state.copyWith(settings: settings),
    );
  }

  Future<void> updateAmoledTheme(bool useAmoled) async {
    final result = await facade.updateAmoledTheme(useAmoled);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (settings) => state = state.copyWith(settings: settings),
    );
  }

  Future<void> updateTempCleanupSettings({
    required bool enabled,
    Duration? period,
  }) async {
    final result = await facade.updateTempCleanupSettings(
      enabled: enabled,
      period: period,
    );
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (settings) => state = state.copyWith(settings: settings),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final settingsDataSourceProvider = Provider<SettingsDataSource>((ref) {
  return SharedPrefsDataSource();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dataSource = ref.watch(settingsDataSourceProvider);
  return SettingsRepositoryImpl(dataSource);
});

final settingsFacadeProvider = Provider<SettingsFacade>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsFacade(repository);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final facade = ref.watch(settingsFacadeProvider);
  return SettingsNotifier(facade);
});
