import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';
import '../widgets/glass_kit.dart';
import '../repositories/notification_repository.dart';
import '../models/notification.dart' as model;

class PendingNotificationAction {
  final String title;
  final String body;
  final String? url;
  final String? imageUrl;

  PendingNotificationAction({
    required this.title,
    required this.body,
    this.url,
    this.imageUrl,
  });
}

final fcmServiceProvider = Provider<FCMService>((ref) => FCMService(ref));

class FCMService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool isDashboardStable = false;
  PendingNotificationAction? _pendingAction;
  PendingNotificationAction? get pendingAction => _pendingAction;

  void clearPendingAction() {
    _pendingAction = null;
  }

  FCMService(this._ref);

  Future<void> initialize() async {
    // 0. Setup Local Notifications for Foreground and Channel Creation
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
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
            Future.delayed(const Duration(milliseconds: 200), () {
              _handleIncomingAction(data['title'], data['body'], data['url'], data['image']);
            });
          } catch (_) {}
        }
      },
    );

    // Register primary channel (v2, matching Edge Functions)
    const AndroidNotificationChannel channelV2 = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v2', 
      'High Priority Reminders',
      description: 'Notifications for class, task timing and announcements',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Register fallback channel (v1) for backward compatibility
    const AndroidNotificationChannel channelV1 = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v1', 
      'Task Reminders',
      description: 'Notifications for class and task timing',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channelV2);
    await androidImplementation?.createNotificationChannel(channelV1);
    
    // Explicitly request notification permission on Android 13+ (API 33+)
    try {
      await androidImplementation?.requestNotificationsPermission();
    } catch (_) {}

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );
    } catch (_) {}

    // Always register FCM message listeners regardless of initial auth status
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notifTitle = message.notification?.title ?? 
                         (message.data['title'] as String?) ?? 
                         'New Notification';
      final notifBody = message.notification?.body ?? 
                        (message.data['body'] as String?) ?? 
                        '';
      final routingUrl = (message.data['url'] as String?) ?? 
                         (message.data['link'] as String?);
      final notifImage = message.notification?.android?.imageUrl ?? 
                         message.notification?.apple?.imageUrl ?? 
                         (message.data['image'] as String?) ??
                         (message.data['image_url'] as String?) ??
                         (message.data['imageUrl'] as String?);

      // Save locally for in-app notifications feed
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final newNotif = model.Notification(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            title: notifTitle,
            body: notifBody,
            type: (message.data['type'] as String?) ?? 'system',
            isRead: false,
            createdAt: message.sentTime ?? DateTime.now(),
            payload: {
              ...message.data,
              if (routingUrl != null) 'url': routingUrl,
              if (notifImage != null) 'image': notifImage,
            },
          );
          _ref.read(notificationRepositoryProvider).saveLocalNotification(newNotif);
        }
      } catch (_) {}

      // Display heads-up notification in foreground using v2 channel
      final int notifId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch).remainder(100000).abs();
      _localNotifications.show(
        id: notifId,
        title: notifTitle,
        body: notifBody,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelV2.id,
            channelV2.name,
            channelDescription: channelV2.description,
            icon: '@mipmap/ic_launcher',
            importance: channelV2.importance,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: jsonEncode({
          'title': notifTitle, 
          'body': notifBody, 
          'url': routingUrl, 
          'image': notifImage
        }),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Future.delayed(const Duration(milliseconds: 800), () {
        final img = message.notification?.android?.imageUrl ?? 
                    message.notification?.apple?.imageUrl ?? 
                    (message.data['image'] as String?) ??
                    (message.data['image_url'] as String?) ??
                    (message.data['imageUrl'] as String?);
        final url = (message.data['url'] as String?) ?? (message.data['link'] as String?);
        _handleIncomingAction(
          message.notification?.title ?? message.data['title'], 
          message.notification?.body ?? message.data['body'], 
          url,
          img,
        );
      });
    });

    // Handle terminated-state notification tap (app was fully closed)
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          final img = initialMessage.notification?.android?.imageUrl ?? 
                      initialMessage.notification?.apple?.imageUrl ?? 
                      (initialMessage.data['image'] as String?) ??
                      (initialMessage.data['image_url'] as String?) ??
                      (initialMessage.data['imageUrl'] as String?);
          final url = (initialMessage.data['url'] as String?) ?? (initialMessage.data['link'] as String?);
          _handleIncomingAction(
            initialMessage.notification?.title ?? initialMessage.data['title'],
            initialMessage.notification?.body ?? initialMessage.data['body'],
            url,
            img,
          );
        });
      }
    } catch (_) {}

    // Listen for FCM token refreshes
    _messaging.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(token);
    });

    // Attempt token sync
    await syncToken();
  }

  /// Explicitly retrieve the device token and register it with the current user in Supabase
  Future<void> syncToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint("[FCM] syncToken error: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('fcm_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'token');
        debugPrint("[FCM] Token saved successfully for user ${user.id} on ${defaultTargetPlatform.name}");
      } catch (e) {
        debugPrint("[FCM] Token Registration Failed: $e");
      }
    } else {
      debugPrint("[FCM] No current user signed in. Token will sync upon login.");
    }
  }

  void _handleIncomingAction(String? title, String? body, String? url, [String? imageUrl]) {
    if (!isDashboardStable) {
      debugPrint("[FCM] Dashboard not stable yet. Saving pending notification action.");
      _pendingAction = PendingNotificationAction(
        title: title ?? 'Notification Received',
        body: body ?? '',
        url: url,
        imageUrl: imageUrl,
      );
    } else {
      showNotificationPopup(
        title ?? 'Notification Received',
        body ?? '',
        url,
        imageUrl,
      );
    }
  }

  void _navigateToUrl(String? url) {
    if (url == null || url.isEmpty) return;
    if (url.startsWith('/')) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) context.go(url);
    } else if (url.startsWith('http')) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void showNotificationPopup(String title, String body, String? url, [String? imageUrl]) {
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const Icon(Icons.notifications_active, color: Colors.cyanAccent, size: 48),
                      const SizedBox(height: 16),
                    ],
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
                                _navigateToUrl(url);
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
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
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
