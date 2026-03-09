import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_repository.dart';
import '../../core/models/notification_model.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/glass_kit.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  Future<void> _confirmClearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Clear Notifications", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete all personal notifications? This cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete All", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EWUmateAppBar(
          title: "Notifications",
          showMenu: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              tooltip: 'Clear All',
              onPressed: _confirmClearAll,
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<AppNotification>>(
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
    ),
  ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
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
            trailing: n.type == NotificationType.broadcast 
                ? null 
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                    onPressed: () {
                      _repo.deleteNotification(n.id);
                    },
                  ),
            onTap: () {
              // Mark as read logic
              _repo.markAsRead(n.id);
            },
          ),
          if (n.link != null && n.link!.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Open Link", style: TextStyle(fontSize: 13)),
                    onPressed: () => _launchUrl(n.link!),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text("Download", style: TextStyle(fontSize: 13)),
                    onPressed: () => _launchUrl(n.link!),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
