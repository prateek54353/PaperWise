import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ColorScheme lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: paperWiseBrandSeed,
      brightness: Brightness.light,
      surface: AppTokens.lightSurface,
    );
  }

  static ColorScheme darkColorScheme({required bool useAmoledTheme}) {
    return ColorScheme.fromSeed(
      seedColor: paperWiseBrandSeed,
      brightness: Brightness.dark,
      surface: useAmoledTheme ? Colors.black : null,
    );
  }

  static ThemeData lightTheme(bool useAmoledTheme) {
    return _build(lightColorScheme(), useAmoled: false);
  }

  static ThemeData darkTheme(bool useAmoledTheme) {
    return _build(
      darkColorScheme(useAmoledTheme: useAmoledTheme),
      useAmoled: useAmoledTheme,
    );
  }

  static ThemeData _build(ColorScheme colorScheme, {required bool useAmoled}) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final textTheme = ThemeData(brightness: colorScheme.brightness).textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: AppTokens.elevationNone,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTokens.elevationCard,
        color: isDark
            ? colorScheme.surfaceContainerLow
            : AppTokens.lightCard,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusMd,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusMd,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusMd,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLg,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
      ),
    );
  }
}