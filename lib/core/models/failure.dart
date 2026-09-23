import 'package:dartz/dartz.dart';

/// Base class for all failures
abstract class Failure {
  final String message;
  final int? code;
  final String? userFriendlyMessage;
  final String? recoverySuggestion;

  const Failure(
    this.message, {
    this.code,
    this.userFriendlyMessage,
    this.recoverySuggestion,
  });

  @override
  String toString() => 'Failure: $message';

  /// Get the user-friendly message, falling back to the technical message
  String get displayMessage => userFriendlyMessage ?? message;
}

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'An unexpected error occurred',
    super.recoverySuggestion = 'Please try again. If the problem persists, restart the app.',
  });
}

/// Failure for network-related errors
class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Network error occurred',
    super.recoverySuggestion = 'Check your internet connection and try again',
  });
}

/// Failure for file system operations
class FileSystemFailure extends Failure {
  const FileSystemFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'File operation failed',
    super.recoverySuggestion = 'Check if you have sufficient storage space and permissions',
  });
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Invalid input',
    super.recoverySuggestion = 'Please check your input and try again',
  });
}

/// Failure for camera operations
class CameraFailure extends Failure {
  const CameraFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Camera error occurred',
    super.recoverySuggestion = 'Check camera permissions and try again',
  });
}

/// Failure for OCR operations
class OcrFailure extends Failure {
  const OcrFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Text recognition failed',
    super.recoverySuggestion = 'Ensure the image is clear and has good lighting',
  });
}

/// Failure for image processing
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Image processing failed',
    super.recoverySuggestion = 'Try a different image or format',
  });
}

/// Failure for PDF operations
class PdfFailure extends Failure {
  const PdfFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'PDF operation failed',
    super.recoverySuggestion = 'The PDF file may be corrupted or in an unsupported format',
  });
}

/// Failure for settings operations
class SettingsFailure extends Failure {
  const SettingsFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Settings error occurred',
    super.recoverySuggestion = 'Try resetting your settings or restart the app',
  });
}

/// Failure for cache operations
class CacheFailure extends Failure {
  const CacheFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Cache error occurred',
    super.recoverySuggestion = 'Clear the app cache and try again',
  });
}

/// Failure for permission issues
class PermissionFailure extends Failure {
  const PermissionFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Permission denied',
    super.recoverySuggestion = 'Grant the required permissions in app settings',
  });
}

/// Failure for storage issues
class StorageFailure extends Failure {
  const StorageFailure(
    super.message, {
    super.code,
    super.userFriendlyMessage = 'Storage error occurred',
    super.recoverySuggestion = 'Check available storage space and permissions',
  });
}

/// Type alias for Either with Failure
typedef EitherFailure<T> = Either<Failure, T>;
