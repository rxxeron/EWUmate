import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/models/notification.dart' as model;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(userNotificationsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleNotificationTap(
      BuildContext context, model.Notification notification) async {
    // 1. Always mark it as read
    if (!notification.isRead) {
      ref.read(notificationRepositoryProvider).markAsRead(notification.id);
    }

    // 2. Show the detail popup (Front and Center)
    if (context.mounted) {
      ref.read(fcmServiceProvider).showNotificationPopup(
        notification.title, 
        notification.body, 
        notification.payload != null ? notification.payload!['url']?.toString() : null
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.cyanAccent),
            tooltip: 'Class Reminder Settings',
            onPressed: () => context.push('/notifications/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white70),
            tooltip: 'Mark all as read',
            onPressed: () {
              final user = ref.read(currentUserProvider); // Make sure you have this or use your auth repo
              if (user != null) {
                ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userNotificationsProvider);
        },
        color: Colors.cyanAccent,
        backgroundColor: const Color(0xFF1A1A2E),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: Text('No new notifications.',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationTile(context, ref, notif);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
          error: (err, stack) => Center(
            child: Text('Failed to load notifications: $err',
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref, model.Notification notif) {
    // Pick an icon/color based on type
    IconData iconData = Icons.notifications;
    Color iconColor = Colors.cyanAccent;

    final type = notif.type.toLowerCase();
    if (type == 'update' || type == 'system') {
      iconData = Icons.system_update;
      iconColor = Colors.greenAccent;
    } else if (type == 'task') {
      iconData = Icons.assignment;
      iconColor = Colors.amberAccent;
    } else if (type == 'schedule') {
      iconData = Icons.calendar_today;
      iconColor = Colors.purpleAccent;
    }

    final isUnread = !notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationRepositoryProvider).deleteNotification(notif.id);
      },
      child: ListTile(
        onTap: () => _handleNotificationTap(context, notif),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: isUnread ? Colors.white.withOpacity(0.05) : Colors.transparent,
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(iconData, color: iconColor),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notif.title,
          style: TextStyle(
              color: Colors.white,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
              fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.body,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                notif.createdAt != null
                    ? DateFormat('MMM d, yyyy • h:mm a').format(notif.createdAt!.toLocal())
                    : 'Just now',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: (notif.payload != null && notif.payload!.containsKey('url'))
            ? const Icon(Icons.download, color: Colors.greenAccent, size: 20)
            : null,
      ),
    );
  }
}
