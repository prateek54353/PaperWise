import 'package:dartz/dartz.dart';

/// Base class for all failures
abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message';
}

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Failure for network-related errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Failure for file system operations
class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure for OCR operations
class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

/// Failure for image processing
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(super.message);
}

/// Failure for PDF operations
class PdfFailure extends Failure {
  const PdfFailure(super.message);
}

/// Failure for settings operations
class SettingsFailure extends Failure {
  const SettingsFailure(super.message);
}

/// Failure for cache operations
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Type alias for Either with Failure
typedef EitherFailure<T> = Either<Failure, T>;
