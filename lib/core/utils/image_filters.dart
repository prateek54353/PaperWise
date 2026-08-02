/// Image filter utilities
/// Note: Actual filter implementations are in the scanner feature
/// This file provides common filter-related utilities
class ImageFilterUtils {
  ImageFilterUtils._();

  /// Validates if a filter can be applied to an image
  static bool canApplyFilter(int width, int height) {
    return width > 0 && height > 0;
  }

  /// Returns suggested filter based on image characteristics
  static String suggestFilter(bool isLowLight, bool isBlurred) {
    if (isLowLight) return 'auto';
    if (isBlurred) return 'sharpen';
    return 'grayscale';
  }
}
