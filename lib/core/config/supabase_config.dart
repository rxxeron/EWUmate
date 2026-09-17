import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const String supabaseUrl = 'https://jwygjihrbwxhehijldiz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM';
  static const String azureFunctionUrl = 'https://ewumate-parser.azurewebsites.net';
  static const String googleWebClientId = '561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com';
  static const String googleAndroidClientId = '561956344734-tserledl1nlsae5g46eaqfmbf31npvaf.apps.googleusercontent.com';

  static String get getSupabaseUrl => dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
  static String get getSupabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
  static String get getAzureFunctionUrl => dotenv.env['AZURE_FUNCTION_URL'] ?? azureFunctionUrl;
  static String get getGoogleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? googleWebClientId;
}

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (kDebugMode) debugPrint('[SupabaseConfig] .env load notice: $e');
    }

    await Supabase.initialize(
      url: AppConfig.getSupabaseUrl,
      publishableKey: AppConfig.getSupabaseAnonKey,
    );
  }
}
