import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import '../router/app_router.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _defaultIcon = '@mipmap/ic_launcher';

  Future<void> initialize() async {
    try {
      await _initLocalNotifications();
    } catch (e) {
      debugPrint('[RealtimeNotification] _initLocalNotifications ERROR: $e');
    }

    // Listen for auth state changes to re-initialize when user logs in/out
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (session?.user != null) {
          await _setupForUser(session!.user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        await _localNotificationsPlugin.cancelAll();
      }
    });

    // Check if user is already logged in at startup
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _setupForUser(user);
    }
  }

  Future<void> _setupForUser(User user) async {
    // 1. Sync future alerts for offline support
    await syncScheduledAlerts();

    // 2. Sync FCM Token with Supabase
    await _syncFcmToken(user.id);

    // 3. Listen to Realtime INSERTs for active app pushes (Legacy/Redundant, keeping for safety)
    _supabase
        .channel('public:notifications:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final title = newRecord['title'] ?? 'New Notification';
              final body = newRecord['body'] ?? '';
              
              _showNativeNotification(title, body);
              showNotificationOverlay(title, body);
            }
          },
        )
        .subscribe();

    // 4. Listen to incoming FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? 'New Notification';
        final body = message.notification!.body ?? '';
        final link = message.data['link'] as String? ?? message.data['url'] as String?;

        _showNativeNotification(title, body, payload: link);
        showNotificationOverlay(title, body, link: link);
      }
    });

    // 5. Handle taps on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final link = message.data['link'] as String? ?? message.data['url'] as String?;
      if (link != null && link.isNotEmpty) {
        _launchUrl(link);
      }
    });

    // 6. Handle taps on notification when app was completely terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        final link = message.data['link'] as String? ?? message.data['url'] as String?;
        if (link != null && link.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () => _launchUrl(link));
        }
      }
    });

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveTokenToSupabase(user.id, newToken);
    });
  }

  Future<void> _syncFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[FCM] Token retrieval timed out.');
          return null;
        },
      );
      if (token != null) {
        await _saveTokenToSupabase(userId, token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String userId, String token) async {
    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
      }, onConflict: 'token').timeout(const Duration(seconds: 3));
      debugPrint('[FCM] Token synced successfully.');
    } catch (e) {
      debugPrint('[FCM] Error saving token to Supabase: $e');
    }
  }

  /// Fetches future alerts from Supabase and schedules them locally
  Future<void> syncScheduledAlerts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      
      // Fetch alerts scheduled in the future
      final response = await _supabase
          .from('scheduled_alerts')
          .select()
          .eq('user_id', user.id)
          .eq('is_dispatched', false)
          .gte('trigger_at', now)
          .timeout(const Duration(seconds: 5));

      final List alerts = response as List;
      int count = 0;

      for (var alert in alerts) {
        final id = alert['id'].hashCode;
        final title = alert['title'] ?? 'EWUmate Reminder';
        final body = alert['body'] ?? '';
        final triggerAt = DateTime.parse(alert['trigger_at']);

        await _scheduleLocalNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: triggerAt,
        );
        count++;
      }
      if (count > 0) {
        debugPrint('[RealtimeNotification] Synced $count future alerts for offline use.');
      }
    } catch (e) {
      debugPrint('[RealtimeNotification] syncScheduledAlerts ERROR: $e');
    }
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Convert to TZDateTime
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final nowTZ = tz.TZDateTime.now(tz.local);
      
      if (scheduledTZDate.isBefore(nowTZ)) {
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'ewumate_offline_channel',
        'Offline Reminders',
        channelDescription: 'Stored reminders that trigger even without internet.',
        importance: Importance.max,
        priority: Priority.high,
        icon: _defaultIcon,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[OfflineSync] ERROR scheduling $title: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(_defaultIcon);
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          _launchUrl(response.payload!);
        }
      },
    );

    // Request permissions for Android 13+
    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> _showNativeNotification(String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ewumate_alerts_channel',
      'Class & Task Alerts',
      channelDescription: 'Important reminders for classes and tasks.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: _defaultIcon,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: title,
      body: body,
      payload: payload,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[RealtimeNotification] Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('[RealtimeNotification] Error launching url: $e');
    }
  }

  // --- Overlay Logic ---
  void showNotificationOverlay(String title, String body, {String? link}) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

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
                padding: EdgeInsets.fromLTRB(20, 20, 20, link != null ? 10 : 30),
                child: Text(
                  body,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.4),
                  textAlign: TextAlign.left,
                ),
              ),
              if (link != null) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text("Open Link"),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _launchUrl(link);
                        },
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                        ),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text("Download"),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _launchUrl(link);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Test Notification Logic ---
  Future<void> scheduleTestNotification(int minutes) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final triggerTime = DateTime.now().add(Duration(minutes: minutes));
    
    // 1. Schedule locally
    await _scheduleLocalNotification(
      id: 9999,
      title: "Test Reminder ($minutes min)",
      body: "If you see this, local notifications are working!",
      scheduledDate: triggerTime,
    );

    // 2. Insert into Supabase (Optional: but good for testing dispatcher/real-time)
    try {
      await _supabase.from('scheduled_alerts').upsert({
        'user_id': user.id,
        'title': "Supabase Test Alert",
        'body': "This came from the database!",
        'trigger_at': triggerTime.toUtc().toIso8601String(),
        'alert_key': "test_${DateTime.now().millisecondsSinceEpoch}",
        'is_dispatched': false,
      });
    } catch (e) {
      debugPrint('[NotificationTest] Supabase Insert Error: $e');
    }
  }
}
