import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[FCM] Skipping FCM init on web.');
      return;
    }
    // 1. Request Permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Background Handler (Top Level)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Token Management
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToSupabase);

    // 4. Foreground Message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('Notification received: ${message.notification!.title}');
        _showNotificationOverlay(message);
      }
    });

    // 5. Subscribe to Broadcast Topic
    await _firebaseMessaging.subscribeToTopic('all_users');

    // 6. Handle interactions
    _setupInteractions();
  }

  Future<void> _setupInteractions() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) async {
    // 1. Check for Link (Priority)
    if (message.data.containsKey('link')) {
      final String url = message.data['link'];
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return; // Stop if link handled
        }
      }
    }

    // 2. Otherwise Show Overlay if it has notification content
    if (message.notification != null) {
      _showNotificationOverlay(message);
    }
  }

  // --- Overlay Logic ---
  void _showNotificationOverlay(RemoteMessage message) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? "Notification";
    final body = message.notification?.body ?? "";

    showDialog(
      context: context,
      barrierDismissible: true, // Allow tap outside to dismiss
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E), // Dark theme matching background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, blurRadius: 20, spreadRadius: 5)
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Colors.cyanAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(Icons.close, color: Colors.white54),
                    )
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Text(
                  body,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.4),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': kIsWeb ? 'web' : 'android', // Simple detection
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[FCM] Error saving token to Supabase: $e');
    }
  }
}
