import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Cache Service (Hive) before running the app
  final cacheService = CacheService();
  await cacheService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init error: $e');
  }

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    if (kDebugMode) debugPrint('Supabase init error: $e');
  }

  // Set up Firebase Cloud Messaging bindings if user is authenticated natively
  try {
    final supabase = Supabase.instance.client;
    // We listen to dynamic auth changes to secure push token binding even if they re-login
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        FCMService().initialize().catchError((err) {
          if (kDebugMode) debugPrint('FCM Init Error: $err');
        });
      }
    });
  } catch (e) {
    if (kDebugMode) debugPrint('FCM Auth listener error: $e');
  }

  runApp(
    ProviderScope(
      // Provide the initialized cache service instance synchronously to the remaining app
      overrides: [
        cacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EWUmate',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
