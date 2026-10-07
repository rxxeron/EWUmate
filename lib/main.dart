import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'core/providers/session_guardian.dart';
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

String? globalFirebaseInitError;

Future<void> _bootloader(CacheService cache) async {
  // 1. Cache Layer
  try { 
    await cache.init(); 
  } catch (e) { 
    if (kDebugMode) debugPrint('[Boot] Cache init error: $e'); 
  }
  

  // 2. Firebase Layer (Gracefully skipped on Web to prevent JS Object crashes)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      globalFirebaseInitError = e.toString();
      if (kDebugMode) debugPrint('[Boot] Firebase init error: $e');
    }
  } else {
    if (kDebugMode) debugPrint('[Boot] Web detected: Bypassing Firebase init.');
  }

  // 3. Supabase Layer
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    if (kDebugMode) debugPrint('[Boot] Supabase init error: $e');
  }
}

void main() async {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();

  final cacheService = CacheService();
  await _bootloader(cacheService);

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM once during app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize().catchError((err) {
        if (kDebugMode) debugPrint('FCM Init Error: $err');
      });
      if (!kIsWeb) {
        AppUpdateService.checkForPlayStoreUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Session Guardian
    ref.read(sessionGuardianProvider);


    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EWUmate',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
