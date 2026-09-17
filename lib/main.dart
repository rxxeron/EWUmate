import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'core/providers/session_guardian.dart';
import 'core/repositories/auth_repository.dart';
import 'dart:io';
import 'core/services/app_update_service.dart';
import 'core/theme/app_theme.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();


  // Initialize Cache Service (Hive), Firebase, and Supabase in parallel
  final cacheService = CacheService();
  
  try {
    await Future.wait([
      cacheService.init(),
      () async {
        try {
          if (!kIsWeb) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Firebase init error: $e');
        }
      }(),
      SupabaseConfig.initialize().catchError((e) {
        if (kDebugMode) debugPrint('Supabase init error: $e');
      }),
    ]);
  } catch (e) {
    if (kDebugMode) debugPrint('Parallel initialization error: $e');
  }

  // Register top-level FCM background message handler (required before runApp)
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase background handler registration error: $e');
    }
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
    // Initialize Session Guardian
    ref.read(sessionGuardianProvider);

    // Check Google Play Store for In-App Updates directly
    if (!kIsWeb) {
      AppUpdateService.checkForPlayStoreUpdate();
    }
    
    // Initialize FCM on mobile: setup channels, foreground handlers and permissions immediately
    if (!kIsWeb) {
      // 1. Initialize channels and listeners on app startup
      ref.read(fcmServiceProvider).initialize().catchError((err) {
        if (kDebugMode) debugPrint('FCM Init Error: $err');
      });

      // 2. React to auth state changes to keep fcm_tokens synced for current user
      ref.listen(authStateProvider, (previous, next) {
        final session = next.value?.session;
        if (session != null) {
          ref.read(fcmServiceProvider).syncToken().catchError((err) {
            if (kDebugMode) debugPrint('FCM Sync Error: $err');
          });
        }
      });
    }
    
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EWUmate',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
