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
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones();

  // 1. Initialize Supabase (Primary Backend)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 1.5. Initialize Offline Storage & Connectivity
  await OfflineCacheService().init();
  await OfflineCacheService().clearRamadanCache(); // One-time clear as requested
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
