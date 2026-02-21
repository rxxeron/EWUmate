import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../router/app_router.dart';

class RealtimeNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

    // 2. Listen to Realtime INSERTs for active app pushes
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
          .gte('trigger_at', now);

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
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<void> _showNativeNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ewumate_alerts_channel',
      'Class & Task Alerts',
      channelDescription: 'Important reminders for classes and tasks.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // --- Overlay Logic ---
  void showNotificationOverlay(String title, String body) {
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
}
