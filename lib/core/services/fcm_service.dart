import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../router/app_router.dart';
import '../widgets/glass_kit.dart';
import '../repositories/notification_repository.dart';
import '../models/notification.dart' as model;
import '../../firebase_options.dart';
import '../../main.dart';
import 'local_notification_scheduler.dart';

import 'package:permission_handler/permission_handler.dart';

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

final fcmServiceProvider = Provider<FCMService>((ref) {
  final service = FCMService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class FCMService {
  final Ref _ref;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  void _showStatusChip(String message, {bool isError = false, bool isSuccess = false}) {
    if (kDebugMode) {
      debugPrint('[FCM Status] $message');
    }
  }

  bool isDashboardStable = false;
  PendingNotificationAction? _pendingAction;
  PendingNotificationAction? get pendingAction => _pendingAction;

  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  void clearPendingAction() {
    _pendingAction = null;
  }

  FCMService(this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return _initCompleter.future;
    _isInitialized = true;

    if (kIsWeb || Firebase.apps.isEmpty) {
      if (!kIsWeb) {
        _showStatusChip("FCM Init Bypassed: Firebase crashed. Error: ${globalFirebaseInitError ?? 'Unknown'}", isError: true);
      }
      debugPrint('[FCM] Bypassing initialization (Web or Firebase inactive).');
      _initCompleter.complete();
      return;
    }
    
    try {
      // 0. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle terminated-state notification tap (app was fully closed)
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Add a 2.5 second delay to let the initial GoRouter splash/auth redirects fully settle
        Future.delayed(const Duration(milliseconds: 2500), () {
          final img = initialMessage.notification?.android?.imageUrl ?? 
                      initialMessage.notification?.apple?.imageUrl ?? 
                      (initialMessage.data['image'] as String?) ??
                      (initialMessage.data['image_url'] as String?);
          _handleIncomingAction(
            initialMessage.notification?.title,
            initialMessage.notification?.body,
            initialMessage.data['url'] as String?,
            img,
          );
        });
      }

      // 1. Setup Local Notifications for Foreground and Channel Creation
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      try {
        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) async {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              try {
                final data = jsonDecode(payload);
                final alertKey = data['alert_key'] as String?;
                if (alertKey != null && alertKey.isNotEmpty) {
                  _ref.read(localNotificationSchedulerProvider).markAlertDelivered(alertKey);
                }
                // Slight delay to let any foreground screen state settle
                Future.delayed(const Duration(milliseconds: 200), () {
                  _handleIncomingAction(data['title'], data['body'], data['url'], data['image']);
                });
              } catch (_) {}
            }
          },
        );
      } catch (e) {
        _showStatusChip("Local Notifs Init Error: $e", isError: true);
        if (kDebugMode) debugPrint('[FCM] Local Notifications Init Error: $e');
      }

      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Create both v1 and v2 channels to ensure compatibility with client and server defaults
      const AndroidNotificationChannel channelV1 = AndroidNotificationChannel(
        'ewumate_high_priority_reminders_v1', 
        'Task Reminders',
        description: 'Notifications for class and task timing',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      const AndroidNotificationChannel channelV2 = AndroidNotificationChannel(
        'ewumate_high_priority_reminders_v2', 
        'Task Reminders (V2)',
        description: 'Notifications for class and task timing',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      try {
        await androidImplementation?.createNotificationChannel(channelV1);
        await androidImplementation?.createNotificationChannel(channelV2);
      } catch (e) {
        _showStatusChip("Channel Creation Error: $e", isError: true);
        if (kDebugMode) debugPrint('[FCM] Channel Creation Error: $e');
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }
      }
      
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((t) => _saveTokenToDatabase(t));

      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        if (notification != null) {
          final routingUrl = message.data['url'] as String?;
          final notifImage = message.notification?.android?.imageUrl ?? 
                             message.notification?.apple?.imageUrl ?? 
                             (message.data['image'] as String?) ??
                             (message.data['image_url'] as String?);
          final alertKey = (message.data['alert_key'] ?? '').toString();

          // Anti-Duplication: If this exact alert was handled locally, suppress duplicate push!
          if (alertKey.isNotEmpty) {
            final scheduler = _ref.read(localNotificationSchedulerProvider);
            if (scheduler.isRecentlyScheduledOrDelivered(alertKey)) {
              if (kDebugMode) {
                debugPrint('[FCM] Suppressed duplicate push alert: $alertKey (local alarm active/handled)');
              }
              return;
            }
          }
          
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

          final scheduler = _ref.read(localNotificationSchedulerProvider);
          final notifId = alertKey.isNotEmpty ? scheduler.getNotificationId(alertKey) : notification.hashCode;

          _localNotifications.show(
            id: notifId,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'ewumate_high_priority_reminders_v2',
                'Task Reminders (V2)',
                channelDescription: 'Notifications for class and task timing',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                tag: alertKey.isNotEmpty ? alertKey : null,
              ),
              iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
            ),
            payload: jsonEncode({'title': notification.title, 'body': notification.body, 'url': routingUrl, 'image': notifImage}),
          );
        }
      });

      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Add 800ms delay to let the app resume and route state settle perfectly
        Future.delayed(const Duration(milliseconds: 800), () {
          final img = message.notification?.android?.imageUrl ?? 
                      message.notification?.apple?.imageUrl ?? 
                      (message.data['image'] as String?) ??
                      (message.data['image_url'] as String?);
          _handleIncomingAction(
            message.notification?.title, 
            message.notification?.body, 
            message.data['url'] as String?,
            img,
          );
        });
      });
    } catch (e) {
      _showStatusChip("FCM Initialization Failed: $e", isError: true);
      debugPrint('[FCM] Initialization Error: $e');
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'));
        await _supabase.from('fcm_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'token');
        if (kDebugMode) debugPrint("[FCM] Token successfully saved for platform $platform");

      } catch (e) {
        if (kDebugMode) debugPrint("[FCM] Token Registration Failed: $e");
      }
    }
  }

  Future<void> syncToken() async {
    if (kIsWeb || Firebase.apps.isEmpty) return;
    try {
      _showStatusChip("Waiting for FCM Initialization...");
      await _initCompleter.future;
      _showStatusChip("Fetching token from Firebase...");
      final token = await _messaging.getToken();
      if (token != null) {
        _showStatusChip("Token fetched. Saving to database...");
        await _saveTokenToDatabase(token);
      } else {
        _showStatusChip("Firebase returned a null token.", isError: true);
      }
    } catch (e) {
      _showStatusChip("FCM Token Fetch Error: $e", isError: true);
      if (kDebugMode) debugPrint("[FCM] syncToken error: $e");
    }
  }

  Future<bool> promptNotificationPermission({
    BuildContext? context,
    bool showSettingsDialog = true,
  }) async {
    if (kIsWeb || Firebase.apps.isEmpty) {
      _showStatusChip("Cannot prompt: Firebase not active. Error: ${globalFirebaseInitError ?? 'Unknown'}", isError: true);
      return false;
    }
    try {
      _showStatusChip("Requesting notification permission...");
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _showStatusChip("Permission granted! Syncing...", isSuccess: true);
        await syncToken();
        return true;
      } else if (showSettingsDialog) {
        _showStatusChip("Permission denied. Redirecting to settings...", isError: true);
        await openAppSettings();
        // Since we don't know immediately if they granted it in settings, 
        // we leave syncToken to the AppLifecycleState or they can click banner again.
      } else {
        _showStatusChip("Permission denied by user.", isError: true);
      }
    } catch (e) {
      _showStatusChip("Permission Request Error: $e", isError: true);
      if (kDebugMode) debugPrint("[FCM] promptNotificationPermission error: $e");
    }
    return false;
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

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
