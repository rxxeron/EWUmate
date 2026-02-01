import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';

import 'core/providers/theme_provider.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FIX: Make Firebase initialization non-blocking to handle devices without Google Play Services
  // This allows the app to launch even if Firebase fails to initialize
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Main] Firebase init error (non-fatal): $e');
  }

  // Initialize Services (non-blocking, fire-and-forget)
  FCMService().initialize().catchError((e) {
    debugPrint('[Main] FCMService init error: $e');
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
      title: 'Mobile App',
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
