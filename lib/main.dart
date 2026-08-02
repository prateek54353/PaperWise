import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/theme/app_theme.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/home_screen.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    if (settingsState.isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final settings = settingsState.settings;

    return MaterialApp(
      title: 'Paperwise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(settings.useAmoledTheme),
      darkTheme: AppTheme.darkTheme(settings.useAmoledTheme),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
