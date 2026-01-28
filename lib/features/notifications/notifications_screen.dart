import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_repository.dart';
import '../../core/models/notification_model.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository();
  final StreamController<List<AppNotification>> _controller =
      StreamController();

  List<AppNotification> _personal = [];
  List<AppNotification> _broadcasts = [];

  StreamSubscription? _sub1;
  StreamSubscription? _sub2;

  @override
  void initState() {
    super.initState();

    // Manual Merge Logic
    _sub1 = _repo.getPersonalNotifications().listen((list) {
      if (mounted) {
        _personal = list;
        _emit();
      }
    });

    _sub2 = _repo.getBroadcasts().listen((list) {
      if (mounted) {
        _broadcasts = list;
        _emit();
      }
    });
  }

  void _emit() {
    if (_controller.isClosed) return;

    final combined = [..._personal, ..._broadcasts];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(combined);
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Dark background
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _controller.stream, // Fixed stream source
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final list = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildNotificationCard(list[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 60, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n) {
    IconData icon;
    Color color;

    switch (n.type) {
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = Colors.orangeAccent;
        break;
      case NotificationType.advising:
        icon = Icons.school;
        color = Colors.cyanAccent;
        break;
      case NotificationType.broadcast:
        icon = Icons.campaign;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blueGrey;
    }

    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), // Card color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  n.isRead ? Colors.transparent : color.withValues(alpha: 0.5),
              width: 1),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ]),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          n.title,
          style: TextStyle(
              color: Colors.white,
              fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n.body,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(n.createdAt),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          // Mark as read logic
          _repo.markAsRead(n.id);
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
