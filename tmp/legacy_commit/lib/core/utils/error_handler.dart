import 'package:flutter/foundation.dart';

/// Utility class for consistent error handling across the app
class ErrorHandler {
  /// Logs error with context and returns user-friendly message
  static String handleError(dynamic error, {String? context}) {
    final errorMessage = _getErrorMessage(error);
    final logMessage = context != null
        ? '[$context] Error: $errorMessage'
        : 'Error: $errorMessage';

    debugPrint(logMessage);

    // Return user-friendly message (don't expose internal details)
    if (error is Exception) {
      return _getUserFriendlyMessage(error);
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Extracts error message from various error types
  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString();
    }
    return error?.toString() ?? 'Unknown error';
  }

  /// Converts technical error messages to user-friendly ones
  static String _getUserFriendlyMessage(Exception error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    }
    if (errorStr.contains('not found')) {
      return 'Resource not found.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('auth')) {
      return 'Authentication failed. Please login again.';
    }

    // Default message
    return 'Something went wrong. Please try again.';
  }

  /// Logs error without throwing (for background operations)
  static void logError(dynamic error, {String? context}) {
    handleError(error, context: context);
  }
}
