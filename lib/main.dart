import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/services/settings_service.dart';
import 'package:paperwise_pdf_maker/providers/pdf_provider.dart';
import 'package:paperwise_pdf_maker/screens/home_screen.dart';
import 'package:paperwise_pdf_maker/utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(SettingsService()),
        ),
        ChangeNotifierProvider(
          create: (_) => PdfProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Paperwise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settingsProvider.settings.useAmoledTheme),
            darkTheme: AppTheme.darkTheme(settingsProvider.settings.useAmoledTheme),
            themeMode: settingsProvider.settings.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}