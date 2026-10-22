import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for Firebase Crashlytics integration
class CrashlyticsService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Initialize Firebase Crashlytics
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      
      // Initialize Crashlytics
      final crashlytics = FirebaseCrashlytics.instance;
      
      // Set Crashlytics-enabled flag to true in Release mode
      const isReleaseMode = bool.fromEnvironment('dart.vm.product');
      
      await crashlytics.setCrashlyticsCollectionEnabled(isReleaseMode);
      
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        if (isReleaseMode) {
          crashlytics.recordFlutterFatalError(errorDetails);
        } else {
          // In debug mode, also print to console
          FlutterError.dumpErrorToConsole(errorDetails);
        }
      };
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        if (isReleaseMode) {
          crashlytics.recordError(error, stack, fatal: true);
        }
        return true;
      };
      
      _isInitialized = true;
      _logger.i('Firebase Crashlytics initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Firebase Crashlytics: $e');
      // Don't crash the app if Crashlytics fails to initialize
    }
  }

  /// Record a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      _logger.w('Crashlytics not initialized, error not recorded');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: isFatal,
        information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );
      _logger.d('Error recorded to Crashlytics: $exception');
    } catch (e) {
      _logger.e('Failed to record error to Crashlytics: $e');
    }
  }

  /// Set a user identifier for crash reports
  static Future<void> setUserIdentifier(String identifier) async {
    if (!_isInitialized) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      _logger.d('User identifier set: $identifier');
    } catch (e) {
      _logger.e('Failed to set user identifier: $e');
    }
  }

  /// Set custom key-value pairs for crash reports
  static Future<void> setCustomKey(String key, String value) async {
    if (!_isInitialized) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
      _logger.d('Custom key set: $key = $value');
    } catch (e) {
      _logger.e('Failed to set custom key: $e');
    }
  }

  /// Log a message that will be included in crash reports
  static Future<void> log(String message) async {
    if (!_isInitialized) return;

    try {
      await FirebaseCrashlytics.instance.log(message);
      _logger.d('Logged to Crashlytics: $message');
    } catch (e) {
      _logger.e('Failed to log to Crashlytics: $e');
    }
  }

  /// Check if Crashlytics is initialized
  static bool get isInitialized => _isInitialized;
}
