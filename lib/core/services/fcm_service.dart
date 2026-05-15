import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router/app_router.dart';
import '../widgets/glass_kit.dart';
import '../repositories/notification_repository.dart';
import '../models/notification.dart' as model;

final fcmServiceProvider = Provider<FCMService>((ref) => FCMService(ref));

class FCMService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FCMService(this._ref);

  Future<void> initialize() async {
    // 0. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
          try {
            final data = jsonDecode(payload);
            _handleIncomingAction(data['title'], data['body'], data['url']);
          } catch (_) {}
        }
      },
    );

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

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        if (notification != null) {
          final routingUrl = message.data['url'] as String?;
          
          // Save locally
          try {
            final userId = _supabase.auth.currentUser?.id;
            if (userId != null) {
              final newNotif = model.Notification(
                id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                userId: userId,
                title: notification.title ?? 'No Title',
                body: notification.body ?? 'No Message',
                type: message.data['type'] ?? 'system',
                isRead: false,
                createdAt: message.sentTime ?? DateTime.now(),
                payload: message.data.isNotEmpty ? message.data : null,
              );
              _ref.read(notificationRepositoryProvider).saveLocalNotification(newNotif);
            }
          } catch (_) {}

          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: channel.importance,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
            ),
            payload: jsonEncode({'title': notification.title, 'body': notification.body, 'url': routingUrl}),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleIncomingAction(
          message.notification?.title, 
          message.notification?.body, 
          message.data['url'] as String?
        );
      });
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('fcm_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint("[FCM] Token Registration Failed: $e");
      }
    }
  }

  void _handleIncomingAction(String? title, String? body, String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
    // You can add more complex routing here if needed
  }

  void showNotificationPopup(String title, String body, String? url) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, color: Colors.cyanAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      decoration: TextDecoration.none,
                    ),
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
                      if (url != null && url.isNotEmpty)
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleIncomingAction(title, body, url);
                            },
                            style: FilledButton.styleFrom(backgroundColor: Colors.cyanAccent),
                            child: const Text('View Action', style: TextStyle(color: Colors.black)),
                          ),
                        ),
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
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('notifications_box')) {
      await Hive.openBox('notifications_box');
    }

    final data = message.data;
    final userId = data['user_id'];

    if (userId != null) {
      final newNotif = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId,
        'title': message.notification?.title ?? data['title'] ?? 'No Title',
        'body': message.notification?.body ?? data['body'] ?? 'No Message',
        'type': data['type'] ?? 'system',
        'is_read': false,
        'created_at': (message.sentTime ?? DateTime.now()).toIso8601String(),
        'payload': data.isNotEmpty ? data : null,
      };

      final box = Hive.box('notifications_box');
      final key = 'notifs_$userId';
      final existingData = box.get(key) as String?;
      List<dynamic> list = [];
      if (existingData != null) {
        try {
          list = jsonDecode(existingData);
        } catch (_) {}
      }
      
      if (!list.any((n) => n['id'] == newNotif['id'])) {
        list.insert(0, newNotif);
        if (list.length > 100) list = list.sublist(0, 100);
        await box.put(key, jsonEncode(list));
      }
    }
  } catch (_) {}
}
