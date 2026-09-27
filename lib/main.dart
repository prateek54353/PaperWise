import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/presentation/update_screen.dart';
import 'package:paperwise_pdf_maker/core/services/trash_service.dart';
import 'package:paperwise_pdf_maker/core/services/update_service.dart';
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
    return const _AppContent();
  }
}

class _AppContent extends ConsumerStatefulWidget {
  const _AppContent();

  @override
  ConsumerState<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends ConsumerState<_AppContent> {
  final UpdateService _updateService = UpdateService();
  bool _shouldShowUpdate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Clean up trash on app startup
    await TrashService.emptyTrash();
    
    // Check for update screen
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    final shouldShowUpdate = await _updateService.shouldShowUpdateScreen();
    
    if (mounted) {
      setState(() {
        _shouldShowUpdate = shouldShowUpdate;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    if (settingsState.isLoading || _isLoading) {
      return const MaterialApp(
        title: 'Paperwise',
        debugShowCheckedModeBanner: false,
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
      home: _shouldShowUpdate 
          ? const UpdateScreen() 
          : const HomeScreen(),
    );
  }
}
