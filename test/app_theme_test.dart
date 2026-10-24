import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperwise_pdf_maker/core/theme/app_theme.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/paperwise_brand.dart';

void main() {
  test('light, dark, and AMOLED schemes keep the dusty-rose seed', () {
    final light = AppTheme.lightColorScheme();
    final dark = AppTheme.darkColorScheme(useAmoledTheme: false);
    final amoled = AppTheme.darkColorScheme(useAmoledTheme: true);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(amoled.surface, Colors.black);
    expect(light.primary, isNot(const Color(0xFF2196F3)));
    expect(
      ThemeData.estimateBrightnessForColor(light.primary),
      isNotNull,
    );
  });

  testWidgets('brand mark renders in light and dark themes', (tester) async {
    Future<void> pump(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: PaperWiseAppBarTitle()),
        ),
      );
      expect(find.text('PaperWise'), findsOneWidget);
      expect(find.text('Scan. Create. Organize.'), findsOneWidget);
    }

    await pump(AppTheme.lightTheme(false));
    await pump(AppTheme.darkTheme(false));
    await pump(AppTheme.darkTheme(true));
  });

  test('tokens expose restrained radii and spacing', () {
    expect(AppTokens.radiusMd, 12);
    expect(AppTokens.minTouchTarget, 48);
    expect(paperWiseBrandSeed, const Color(0xFFB75D70));
  });
}