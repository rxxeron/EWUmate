import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorUtils {
  static String getFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    final String errorStr = error.toString().toLowerCase();

    // 1. Supabase Specific Errors (AuthException)
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password. Please try again.';
        case 'email not confirmed':
          return 'Please verify your email address before logging in.';
        case 'user already exists':
          return 'An account with this email already exists.';
        case 'identity already linked to another user':
          return 'This Google account is already connected to another EWUmate profile.';
        default:
          if (error.message.contains('rate limit')) {
            return 'Too many attempts. Please wait a few minutes and try again.';
          }
          return error.message;
      }
    }

    // 2. Common Google/OAuth Errors
    if (errorStr.contains('id_token parameter not allowed')) {
      return 'Google Authorization failed. This usually happens if the app isn\'t configured correctly in Google Cloud.';
    }
    if (errorStr.contains('network_error') || errorStr.contains('socketexception')) {
      return 'Internet connection lost. Please check your data or Wi-Fi.';
    }
    if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
      return 'Sign-in was cancelled.';
    }
    if (errorStr.contains('invalid_grant')) {
      return 'Session expired. Please log in again.';
    }

    // 3. Fallback for everything else
    return 'Something went wrong. Please try again later.';
  }
}
