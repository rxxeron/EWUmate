import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router/app_router.dart';
import '../widgets/glass_kit.dart';

final fcmServiceProvider = Provider<FCMService>((ref) => FCMService());

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Setup Local Notifications for Foreground and Channel Creation
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (kDebugMode) debugPrint('[FCM] Foreground Local Notification tapped with payload: $payload');
          _handleRouteAuth(payload);
        }
      },
    );

    // Create high importance channel for Android heads-up + vibration
    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 500;
    vibrationPattern[2] = 200;
    vibrationPattern[3] = 500;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v1', 
      'Task Reminders',
      description: 'Notifications for class and task timing',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);
    await androidImplementation?.requestNotificationsPermission();

    // Tell iOS to show foreground notifications directly via Firebase
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permission from OS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) debugPrint('[FCM] User granted permission');

      // Registration token handling
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle foreground notifications manually via Local Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          final routingUrl = message.data['url'] as String?;
          
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            payload: jsonEncode({
              'title': notification.title,
              'body': notification.body,
              'url': routingUrl,
            }), 
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: channel.importance,
                priority: Priority.high,
                enableVibration: true,
                vibrationPattern: vibrationPattern,
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              )
            ),
          );
        }
      });

      // Handle clicks when app is Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('[FCM] Background message tapped: ${message.messageId}');
        _handleIncomingAction(
          message.notification?.title, 
          message.notification?.body, 
          message.data['url'] as String?
        );
      });

      // Handle clicks when app is Killed
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) debugPrint('[FCM] Killed message tapped: ${initialMessage.messageId}');
        // Delay routing slightly to let UI render first
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleIncomingAction(
            initialMessage.notification?.title, 
            initialMessage.notification?.body, 
            initialMessage.data['url'] as String?
          );
        });
      }
    } else {
      if (kDebugMode) debugPrint('[FCM] User declined permission');
    }
  }

  void _handleIncomingAction(String? title, String? body, String? url) {
    // 1. Show the popup first (Front and center)
    if (title != null || body != null) {
      showNotificationPopup(title ?? 'Alert', body ?? '', url);
    } else if (url != null && url.isNotEmpty) {
      _handleRouteAuth(url);
    }
  }

  void showNotificationPopup(String title, String body, String? url) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassContainer(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, color: Colors.cyanAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Dismiss', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      if (url != null && url.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _handleRouteAuth(url);
                            },
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleRouteAuth(String url) async {
    // Check if it's a JSON payload instead of a raw URL (from foreground local notifications)
    if (url.startsWith('{')) {
      try {
        final data = jsonDecode(url);
        _handleIncomingAction(data['title'], data['body'], data['url']);
        return;
      } catch (_) {}
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else {
        if (kDebugMode) debugPrint('[FCM] Cannot launch URL: $url');
      }
    } else if (url.startsWith('/')) {
      if (rootNavigatorKey.currentContext != null) {
         rootNavigatorKey.currentContext!.go(url);
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final platform = defaultTargetPlatform.name.toLowerCase();
      await _supabase.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) debugPrint('[FCM] Token synchronized to Database.');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Failed to sync token: $e');
    }
  }
}
