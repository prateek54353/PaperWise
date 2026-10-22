import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/presentation/onboarding_screen.dart';
import 'package:paperwise_pdf_maker/core/presentation/update_screen.dart';
import 'package:paperwise_pdf_maker/core/services/crashlytics_service.dart';
import 'package:paperwise_pdf_maker/core/services/trash_service.dart';
import 'package:paperwise_pdf_maker/core/services/update_service.dart';
import 'package:paperwise_pdf_maker/core/theme/app_theme.dart';
import 'package:paperwise_pdf_maker/core/widgets/common_widgets.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/pdf_thumbnail_service.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/home_screen.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/providers/settings_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Crashlytics before running the app
  await CrashlyticsService.initialize();
  
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
  bool _shouldShowOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Clean up trash on app startup
    await TrashService.emptyTrash();
    
    // Clean up stale trash entries to prevent memory leaks
    await TrashService.cleanupStaleEntries();
    
    // Clean up thumbnail cache
    await PdfThumbnailService().cleanupCache();
    
    // Check for update screen and onboarding
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    final shouldShowUpdate = await _updateService.shouldShowUpdateScreen();
    final showOnboarding = await shouldShowOnboarding();
    
    if (mounted) {
      setState(() {
        _shouldShowUpdate = shouldShowUpdate;
        _shouldShowOnboarding = showOnboarding;
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
          body: AppLoadingIndicator(message: 'Loading...'),
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
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    if (_shouldShowOnboarding) {
      return const OnboardingScreen();
    }
    if (_shouldShowUpdate) {
      return const UpdateScreen();
    }
    return const HomeScreen();
  }
}
