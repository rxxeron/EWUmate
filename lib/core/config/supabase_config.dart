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

  static String get getSupabaseUrl => _env('SUPABASE_URL');
  static String get getSupabaseAnonKey => _env('SUPABASE_ANON_KEY');
  static String get getAzureFunctionUrl => _env('AZURE_FUNCTION_URL');
  static String get getGoogleWebClientId => _env('GOOGLE_WEB_CLIENT_ID');
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
