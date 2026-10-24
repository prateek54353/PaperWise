import 'package:flutter/material.dart';

/// Sampled from the PaperWise wordmark: dusty rose, not a generic Material purple.
const Color paperWiseBrandSeed = Color(0xFFB75D70);

/// Layout, type, and elevation tokens shared across PaperWise 3.0.
abstract final class AppTokens {
  AppTokens._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  static const double elevationNone = 0;
  static const double elevationLow = 0.5;
  static const double elevationCard = 1;

  static const double minTouchTarget = 48;
  static const double folderCardWidth = 132;
  static const double folderCardHeight = 108;
  static const double navScanSize = 56;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: space16);

  static const Color lightSurface = Color(0xFFFBF8F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1C1416);
}