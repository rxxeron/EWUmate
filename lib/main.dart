import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as t_z;

import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/lifecycle_notification_service.dart';
import 'core/config/supabase_config.dart';
import 'core/services/offline_cache_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Attempt to load .env, but don't crash if it fails (using hardcoded fallback in SupabaseConfig)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('[Main] Environment load failed (Non-critical): $e');
    }

    tz.initializeTimeZones();

    // 1. Initialize Supabase (Primary Backend)
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // 1.5. Initialize Offline Storage & Connectivity
    await OfflineCacheService().init();
    await OfflineCacheService().clearRamadanCache(); 
    await ConnectivityService().init();

    // 2. Request Permissions
    await Permission.notification.request();

    // 3. Initialize In-App Services (non-blocking)
    RealtimeNotificationService().initialize().catchError((e) {
      debugPrint('[Main] RealtimeNotificationService Error: $e');
    });

    LifecycleNotificationService().initialize().catchError((e) {
      debugPrint('[Main] LifecycleNotificationService Error: $e');
    });

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
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
