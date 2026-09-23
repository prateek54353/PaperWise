import 'package:flutter/material.dart';
import '../models/failure.dart';

/// Centralized error handler for consistent error display across the app
class ErrorHandler {
  /// Show a user-friendly error message using SnackBar
  static void showError(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    
    // Create the SnackBar content
    Widget content = Text(failure.displayMessage);
    
    // Add recovery suggestion if available
    if (failure.recoverySuggestion != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(failure.displayMessage),
          const SizedBox(height: 4),
          Text(
            failure.recoverySuggestion!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    // Create SnackBar with optional retry action
    final snackBar = SnackBar(
      content: content,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: duration,
      action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: onRetry,
            )
          : null,
    );

    messenger.clearSnackBars();
    messenger.showSnackBar(snackBar);
  }

  /// Show a success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration,
      ),
    );
  }

  /// Show an info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Show a loading message with progress indicator
  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 30),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
      ),
    );
  }

  /// Hide any visible SnackBars
  static void hideLoading(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Convert a generic exception to a Failure
  static Failure exceptionToFailure(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    final message = exception.toString();
    
    // Try to categorize common exceptions
    if (message.contains('permission') || message.contains('Permission')) {
      return const PermissionFailure('Permission denied');
    }
    if (message.contains('storage') || message.contains('Storage') || message.contains('file') || message.contains('File')) {
      return const StorageFailure('Storage operation failed');
    }
    if (message.contains('network') || message.contains('Network') || message.contains('internet') || message.contains('Internet')) {
      return const NetworkFailure('Network error');
    }
    if (message.contains('camera') || message.contains('Camera')) {
      return const CameraFailure('Camera operation failed');
    }
    if (message.contains('image') || message.contains('Image')) {
      return const ImageProcessingFailure('Image processing failed');
    }
    if (message.contains('pdf') || message.contains('PDF')) {
      return const PdfFailure('PDF operation failed');
    }

    return UnexpectedFailure(message);
  }

  /// Handle an Either result and show appropriate UI feedback
  static Future<void> handleEitherResult<T>(
    BuildContext context,
    dynamic either, {
    String? successMessage,
    VoidCallback? onSuccess,
    VoidCallback? onRetry,
  }) async {
    // This is a placeholder - actual implementation depends on how Either is used
    // In real usage, you would check if it's Right (success) or Left (failure)
    // and call the appropriate methods
  }
}