import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
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
  FirebaseMessaging? _messagingInstance;
  FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;
  SupabaseClient get _supabase => Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool isDashboardStable = false;
  PendingNotificationAction? _pendingAction;
  PendingNotificationAction? get pendingAction => _pendingAction;
  Timer? _periodicRefreshTimer;

  void clearPendingAction() {
    _pendingAction = null;
  }

  FCMService(this._ref);

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      // Periodically refresh/re-sync token every hour to keep database updated_at fresh
      _periodicRefreshTimer?.cancel();
      _periodicRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
        debugPrint("[FCM] Periodic 1-hour token sync running...");
        syncToken();
      });
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not initialized. Skipping FCM setup.');
        return;
      }
    } catch (e) {
      debugPrint('[FCM] Firebase check notice: $e');
      return;
    }

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

    // Define tactile alert vibration pattern (total vibration: 2.0s within 1-3s range):
    // wait 0ms, vibrate 1000ms, pause 300ms, vibrate 1000ms
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 300, 1000]);

    // Primary High Priority Channel (v4) with chime audio and 2-second tactile vibration
    final AndroidNotificationChannel channelV4 = AndroidNotificationChannel(
      'ewumate_high_priority_v4', 
      'High Priority Alerts',
      description: 'Notifications for class, task timing and announcements',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color(0xFF00E5FF),
    );

    // Fallback channels (v3, v2 and v1) for backward compatibility
    final AndroidNotificationChannel channelV3 = AndroidNotificationChannel(
      'ewumate_high_priority_v3', 
      'High Priority Alerts v3',
      description: 'Notifications for class, task timing and announcements',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    final AndroidNotificationChannel channelV2 = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v2', 
      'Task Reminders',
      description: 'Notifications for class and task timing',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    const AndroidNotificationChannel channelV1 = AndroidNotificationChannel(
      'ewumate_high_priority_reminders_v1', 
      'Task Reminders Legacy',
      description: 'Notifications for class and task timing',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channelV4);
    await androidImplementation?.createNotificationChannel(channelV3);
    await androidImplementation?.createNotificationChannel(channelV2);
    await androidImplementation?.createNotificationChannel(channelV1);
    
    // Explicitly request notification permission on Android 13+ (API 33+) via permission_handler and local plugin
    try {
      await Permission.notification.request();
    } catch (_) {}

    try {
      await androidImplementation?.requestNotificationsPermission();
    } catch (_) {}

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      final notifSettings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // Explicit full permission for alerts, sound & vibration
      );
      debugPrint('[FCM] Notification authorization status: ${notifSettings.authorizationStatus}');
      // Exact 1.1.12 mechanism: immediately acquire token & register if authorized
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('[FCM] Permission/Token request notice: $e');
    }

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
        final userId = _supabase.auth.currentUser?.id ?? (message.data['user_id'] as String?);
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

      // Display heads-up notification in foreground using v4 channel with custom sound & tactile vibration
      final int notifId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch).remainder(100000).abs();
      _localNotifications.show(
        id: notifId,
        title: notifTitle,
        body: notifBody,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelV4.id,
            channelV4.name,
            channelDescription: channelV4.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification_sound'),
            enableVibration: true,
            vibrationPattern: vibrationPattern,
            enableLights: true,
            color: const Color(0xFF00E5FF),
            ledColor: const Color(0xFF00E5FF),
            ledOnMs: 1000,
            ledOffMs: 500,
            ticker: 'EWUmate Alert',
            styleInformation: BigTextStyleInformation(
              notifBody,
              contentTitle: notifTitle,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, 
            presentSound: true,
            presentBadge: true,
            presentBanner: true,
            presentList: true,
            sound: 'notification_sound.wav',
          ),
        ),
        payload: jsonEncode({
          'title': notifTitle, 
          'body': notifBody, 
          'url': routingUrl, 
          'image': notifImage
        }),
      );

      // Trigger the real-time popup on Dashboard when app is open
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleIncomingAction(notifTitle, notifBody, routingUrl, notifImage);
      });
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
  Future<void> syncToken([int retryCount = 0]) async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) return;
      final token = await _messaging.getToken();
      if (token != null) {
        final saved = await _saveTokenToDatabase(token);
        // If session was still restoring and user was null, retry up to 3 times
        if (!saved && retryCount < 3) {
          Future.delayed(Duration(seconds: (retryCount + 1) * 2), () {
            syncToken(retryCount + 1);
          });
        }
      }
    } catch (e) {
      debugPrint("[FCM] syncToken error: $e");
    }
  }

  /// Force-refresh the device FCM registration token by acquiring the token and registering with Supabase
  Future<bool> forceRefreshToken() async {
    if (kIsWeb) return false;
    try {
      debugPrint("[FCM] Force-refreshing device token from Firebase...");
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        final success = await _saveTokenToDatabase(newToken);
        debugPrint("[FCM] Force-refresh complete. New token acquired: ${newToken.substring(0, 10)}... Success: $success");
        return success;
      }
    } catch (e) {
      debugPrint("[FCM] forceRefreshToken error: $e");
    }
    return false;
  }

  /// Actively checks notification permission. If denied by OS, requests it.
  /// If permanently denied or dismissed, shows a clean rationale modal guiding the user to phone Settings when [showSettingsDialog] is true.
  Future<bool> promptNotificationPermission({
    BuildContext? context,
    bool showSettingsDialog = true,
  }) async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        await syncToken();
        return true;
      }

      // 1. Request via permission_handler
      final reqResult = await Permission.notification.request();
      if (reqResult.isGranted) {
        await syncToken();
        return true;
      }

      // 2. Also request via Android Local Notifications plugin
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final localGranted = await androidImplementation?.requestNotificationsPermission();
      if (localGranted == true) {
        await syncToken();
        return true;
      }

      // 3. If still not granted, prompt the user to enable in system settings
      if (showSettingsDialog) {
        final targetContext = context ?? rootNavigatorKey.currentContext;
        if (targetContext != null && targetContext.mounted) {
          _showPermissionSettingsDialog(targetContext);
        }
      }
    } catch (e) {
      debugPrint("[FCM] promptNotificationPermission notice: $e");
    }
    return false;
  }

  void _showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF00E5FF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Enable Push Notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'EWUmate needs notification permissions to alert you about class routines, exam reminders, room changes, and important announcements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Not Now', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Enable in Settings',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  Future<bool> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('fcm_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint("[FCM] Token saved successfully for user ${user.id} on ${defaultTargetPlatform.name}");
        return true;
      } catch (e) {
        debugPrint("[FCM] Token Registration Failed with platform: $e");
        try {
          // Exact 1.1.12 payload fallback
          await _supabase.from('fcm_tokens').upsert({
            'user_id': user.id,
            'token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint("[FCM] Token saved successfully (exact 1.1.12 fallback) for user ${user.id}");
          return true;
        } catch (e2) {
          debugPrint("[FCM] Fallback Token Registration Failed: $e2");
        }
      }
    } else {
      debugPrint("[FCM] No current user signed in. Token will sync upon session restoration.");
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

  /// Trigger an immediate local test notification with chime sound and tactile vibration
  Future<void> triggerTestNotification() async {
    final int notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000).abs();
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 300, 1000]);

    await _localNotifications.show(
      id: notifId,
      title: '🔔 EWUmate Notification Test',
      body: 'Sound and vibration are working! You will receive timely alerts for classes and deadlines.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'ewumate_high_priority_v4',
          'High Priority Alerts',
          channelDescription: 'Notifications for class, task timing and announcements',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          color: const Color(0xFF00E5FF),
          ledColor: const Color(0xFF00E5FF),
          ledOnMs: 1000,
          ledOffMs: 500,
          ticker: 'EWUmate Alert Test',
          styleInformation: const BigTextStyleInformation(
            'Sound and vibration are working! You will receive timely alerts for classes and deadlines.',
            contentTitle: '🔔 EWUmate Notification Test',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          presentBanner: true,
          presentList: true,
          sound: 'notification_sound.wav',
        ),
      ),
      payload: jsonEncode({
        'title': '🔔 EWUmate Notification Test',
        'body': 'Sound and vibration are working! You will receive timely alerts for classes and deadlines.',
        'url': '/notifications',
      }),
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

    // If message is data-only (notification field is null), Android system does NOT display it automatically.
    // We display it using flutter_local_notifications with sound and vibration.
    if (message.notification == null && data.isNotEmpty && (data['title'] != null || data['body'] != null)) {
      final FlutterLocalNotificationsPlugin bgNotifs = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings bgAndroidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings bgSettings = InitializationSettings(android: bgAndroidInit);
      await bgNotifs.initialize(settings: bgSettings);

      final notifTitle = (data['title'] as String?) ?? 'EWUmate Alert';
      final notifBody = (data['body'] as String?) ?? '';
      final int notifId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch).remainder(100000).abs();
      final Int64List vibrationPattern = Int64List.fromList([0, 1000, 300, 1000]);

      await bgNotifs.show(
        id: notifId,
        title: notifTitle,
        body: notifBody,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'ewumate_high_priority_v4',
            'High Priority Alerts',
            channelDescription: 'Notifications for class, task timing and announcements',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification_sound'),
            enableVibration: true,
            vibrationPattern: vibrationPattern,
            styleInformation: BigTextStyleInformation(
              notifBody,
              contentTitle: notifTitle,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            presentBanner: true,
            presentList: true,
            sound: 'notification_sound.wav',
          ),
        ),
      );
    }
  } catch (_) {}
}
