import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as t_z;

import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/lifecycle_notification_service.dart';
import 'core/config/supabase_config.dart';
import 'core/services/offline_cache_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/repositories/app_config_repository.dart';
import 'core/widgets/maintenance_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling a background message: ${message.messageId}');
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a future for the initialization logic
  final initFuture = _initializeServices();

  // Wait for init with a hard timeout of 10 seconds (increased from 7 for remote config)
  await initFuture.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      debugPrint('[Main] STARTUP TIMEOUT: Initialization took too long, proceeding to runApp.');
    },
  ).catchError((e) {
    debugPrint('[Main] STARTUP ERROR: $e');
  });

  // Check for Maintenance Mode before launch
  final config = AppConfigRepository();
  if (config.isFeatureEnabled('maintenance_mode', defaultValue: false)) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MaintenanceScreen(),
    ));
    return;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Attempt to load .env, but don't crash if it fails
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('[Main] Environment load failed (Non-critical): $e');
    }

    tz.initializeTimeZones();

    // 0. Initialize Firebase
    await Firebase.initializeApp().timeout(const Duration(seconds: 5)).catchError((e) {
      debugPrint('[Main] Firebase Init Timeout/Error: $e');
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 1. Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ).timeout(const Duration(seconds: 5)).catchError((e) {
      debugPrint('[Main] Supabase Init Timeout/Error: $e');
    });

    // 1.5. Initialize Offline Storage, Connectivity & App Config
    await OfflineCacheService().init();
    await OfflineCacheService().clearRamadanCache(); 
    await ConnectivityService().init();
    await AppConfigRepository().init();

    // 2. Request Permissions with Timeout
    await Permission.notification.request().timeout(
      const Duration(seconds: 2),
      onTimeout: () => PermissionStatus.denied,
    ).catchError((_) => PermissionStatus.denied);

    // 3. Initialize In-App Services (non-blocking)
    RealtimeNotificationService().initialize().catchError((e) {
      debugPrint('[Main] RealtimeNotificationService Error: $e');
    });

    LifecycleNotificationService().initialize().catchError((e) {
      debugPrint('[Main] LifecycleNotificationService Error: $e');
    });

    SyncService().init();
  } catch (e, stack) {
    debugPrint('[Main] CRITICAL STARTUP ERROR: $e');
    debugPrint('[Main] Stacktrace: $stack');
    
    // Show a fallback UI if initialization fails completely
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text("Startup Error", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart or at least show login
                    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("Restart the app please.")))));
                  }, 
                  child: const Text("Retry")
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'EWUmate',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
