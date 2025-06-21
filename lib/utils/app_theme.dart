import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
    ),
  );

  // New AMOLED Theme
  static final amoledTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black, // Pure black background
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: Colors.black, // Make card surfaces and dialogs black
      // ignore: deprecated_member_use
      background: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.black,
    ),
    cardTheme: const CardThemeData(
      color: Color.fromARGB(255, 20, 20, 20) // Slightly off-black for contrast
    )
  );
}