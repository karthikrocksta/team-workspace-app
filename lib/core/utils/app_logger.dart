import 'dart:developer' as developer;

/// Centralized logging so we never scatter `print()` across the codebase.
/// Swap the implementation for Sentry/Crashlytics/Firebase Analytics later
/// without touching call sites.
class AppLogger {
  AppLogger._();

  static void info(String message, {String tag = 'APP'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void warning(String message, {String tag = 'APP'}) {
    developer.log(message, name: tag, level: 900);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String tag = 'APP'}) {
    developer.log(message, name: tag, level: 1000, error: error, stackTrace: stackTrace);
  }
}
