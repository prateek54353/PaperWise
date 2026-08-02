import 'dart:io';
import 'package:path/path.dart' as path;

/// Extension methods for File
extension FileExtensions on File {
  /// Returns the file size in bytes
  Future<int> get size async => await length();

  /// Returns the file size in a human-readable format
  Future<String> get sizeFormatted async {
    final bytes = await size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns the file name without extension
  String get nameWithoutExtension {
    return path.split(path.split(this.path).last).first;
  }

  /// Returns the file extension
  String get extension {
    return path.split(this.path).last.split('.').last;
  }
}

/// Extension methods for Duration
extension DurationExtensions on Duration {
  /// Returns a human-readable string representation
  String toReadableString() {
    if (inDays >= 365) {
      final years = (inDays / 365).floor();
      return years == 1 ? 'Every year' : 'Every $years years';
    }
    if (inDays >= 30) {
      final months = (inDays / 30).floor();
      return months == 1 ? 'Every month' : 'Every $months months';
    }
    if (inDays > 0) {
      return inDays == 1 ? 'Every day' : 'Every $inDays days';
    }
    if (inHours > 0) {
      return inHours == 1 ? 'Every hour' : 'Every $inHours hours';
    }
    if (inMinutes > 0) {
      return inMinutes == 1 ? 'Every minute' : 'Every $inMinutes minutes';
    }
    return 'Every second';
  }
}
