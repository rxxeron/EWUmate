import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

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
          debugPrint('[FCM] Foreground Local Notification tapped with payload: $payload');
          _handleRouteAuth(payload);
        }
      },
    );

    // Create high importance channel for Android heads-up + vibration
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v1', // Must match the channel ID sent from Supabase alert-dispatcher
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
      debugPrint('[FCM] User granted permission');

      // Registration token handling
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle foreground notifications manually via Local Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          final routingUrl = message.data['url'] as String?;
          
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            payload: routingUrl, // Inject for foreground click
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: channel.importance,
                priority: Priority.high,
                enableVibration: true,
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

      // Handle clicks when app is in Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Background message tapped: ${message.messageId}');
        final routingUrl = message.data['url'] as String?;
        if (routingUrl != null && routingUrl.isNotEmpty) {
          _handleRouteAuth(routingUrl);
        }
      });

      // Handle clicks when app is Killed
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] Killed message tapped: ${initialMessage.messageId}');
        final routingUrl = initialMessage.data['url'] as String?;
        if (routingUrl != null && routingUrl.isNotEmpty) {
          // Delay routing slightly to let UI render first
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleRouteAuth(routingUrl);
          });
        }
      }
    } else {
      debugPrint('[FCM] User declined permission');
    }
  }

  void _handleRouteAuth(String url) {
    if (rootNavigatorKey.currentContext != null) {
      if (url.startsWith('/')) {
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
      debugPrint('[FCM] Token synchronized to Database.');
    } catch (e) {
      debugPrint('[FCM] Failed to sync token: $e');
    }
  }
}
