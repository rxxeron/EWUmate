import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static String _env(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet(key) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static String get getSupabaseUrl {
    final val = _env('SUPABASE_URL');
    return val.isNotEmpty ? val : 'https://jwygjihrbwxhehijldiz.supabase.co';
  }

  static String get getSupabaseAnonKey {
    final val = _env('SUPABASE_ANON_KEY');
    return val.isNotEmpty ? val : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM';
  }

  static String get getAzureFunctionUrl {
    final val = _env('AZURE_FUNCTION_URL');
    return val.isNotEmpty ? val : 'https://ewumate-parser-api.azurewebsites.net';
  }

  static String get getGoogleWebClientId {
    final val = _env('GOOGLE_WEB_CLIENT_ID');
    return val.isNotEmpty ? val : '561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com';
  }
}

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (kDebugMode) debugPrint('[SupabaseConfig] .env load notice: $e');
    }

    final url = AppConfig.getSupabaseUrl;
    final anonKey = AppConfig.getSupabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Warning: SUPABASE_URL or SUPABASE_ANON_KEY is empty in .env');
      }
    }

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
  }
}
