import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/providers/pdf_provider.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/screens/home_screen.dart';
import 'package:paperwise_pdf_maker/services/settings_service.dart';
import 'package:paperwise_pdf_maker/utils/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final settings = await settingsService.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(settings, settingsService)),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
      ],
      child: const PaperwisePDFMaker(),
    ),
  );
}

class PaperwisePDFMaker extends StatelessWidget {
  const PaperwisePDFMaker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: 'Paperwise PDF Maker',
          debugShowCheckedModeBanner: false,
          themeMode: settingsProvider.settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: settingsProvider.settings.useAmoledTheme
              ? AppTheme.amoledTheme
              : AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}