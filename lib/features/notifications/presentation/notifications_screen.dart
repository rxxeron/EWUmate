import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/models/notification.dart' as model;
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Timer? _refreshTimer;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Unread', 'Schedule', 'Tasks', 'System'];

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(userNotificationsProvider);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.notificationsKey,
          steps: OnboardingSteps.notifications,
        );
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

    final imageUrl = (notification.payload?['image'] as String?) ??
                     (notification.payload?['image_url'] as String?) ??
                     (notification.payload?['imageUrl'] as String?);
    final linkUrl = (notification.payload?['url'] as String?) ??
                    (notification.payload?['link'] as String?);

    // 2. Show the detail popup (Front and Center)
    if (context.mounted) {
      ref.read(fcmServiceProvider).showNotificationPopup(
        notification.title, 
        notification.body, 
        linkUrl,
        imageUrl,
      );
    }
  }

  void _launchActionUrl(BuildContext context, String url) {
    if (url.startsWith('/')) {
      context.go(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.primaryCyan, size: 20),
            ),
            tooltip: 'Class Reminder Settings',
            onPressed: () => context.push('/notifications/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.secondaryText, size: 22),
            tooltip: 'Mark all as read',
            onPressed: () {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All notifications marked as read.', style: GoogleFonts.sora()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                            )
                          : null,
                      color: isSelected ? null : AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: GoogleFonts.sora(
                          color: isSelected ? AppColors.primaryNavy : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userNotificationsProvider);
        },
        color: AppColors.primaryCyan,
        backgroundColor: AppColors.surfaceNavyBlue,
        child: notificationsAsync.when(
          data: (notifications) {
            // Apply filter
            final filtered = notifications.where((n) {
              if (_selectedFilter == 'Unread') return !n.isRead;
              if (_selectedFilter == 'Schedule') return n.type.toLowerCase() == 'schedule';
              if (_selectedFilter == 'Tasks') return n.type.toLowerCase() == 'task';
              if (_selectedFilter == 'System') {
                final t = n.type.toLowerCase();
                return t == 'system' || t == 'update';
              }
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: const Icon(Icons.notifications_off_outlined, size: 32, color: AppColors.primaryCyan),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _selectedFilter == 'All' ? 'No Notifications' : 'No $_selectedFilter Notifications',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You are all caught up! Important alerts will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = filtered[index];
                return _buildNotificationCard(context, ref, notif);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load notifications: $err',
              style: GoogleFonts.sora(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, model.Notification notif) {
    // Pick an icon/color based on type
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = AppColors.primaryCyan;
    String tagLabel = 'ALERT';

    final type = notif.type.toLowerCase();
    if (type == 'update' || type == 'system') {
      iconData = Icons.system_update_rounded;
      iconColor = const Color(0xFF10B981);
      tagLabel = 'SYSTEM';
    } else if (type == 'task') {
      iconData = Icons.assignment_turned_in_rounded;
      iconColor = const Color(0xFFF59E0B);
      tagLabel = 'TASK';
    } else if (type == 'schedule') {
      iconData = Icons.calendar_month_rounded;
      iconColor = const Color(0xFFA855F7);
      tagLabel = 'SCHEDULE';
    }

    final isUnread = !notif.isRead;
    final cardImage = (notif.payload?['image'] as String?) ??
                      (notif.payload?['image_url'] as String?) ??
                      (notif.payload?['imageUrl'] as String?);
    final cardUrl = (notif.payload?['url'] as String?) ??
                    (notif.payload?['link'] as String?);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) {
        ref.read(notificationRepositoryProvider).deleteNotification(notif.id);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(context, notif),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.surfaceNavyBlue.withValues(alpha: 0.85)
                : AppColors.surfaceNavyBlue.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread
                  ? AppColors.primaryCyan.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1.2,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryNavy, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag & Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tagLabel,
                            style: GoogleFonts.sora(
                              color: iconColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          notif.createdAt != null
                              ? DateFormat('MMM d • h:mm a').format(notif.createdAt!.toLocal())
                              : 'Just now',
                          style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      notif.title,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Body
                    Text(
                      notif.body,
                      style: GoogleFonts.sora(
                        color: isUnread ? Colors.white.withValues(alpha: 0.85) : AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    // Image preview if present
                    if (cardImage != null && cardImage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: cardImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 150,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: AppColors.primaryCyan, strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    // Clickable link if present
                    if (cardUrl != null && cardUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          if (!notif.isRead) {
                            ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                          }
                          _launchActionUrl(context, cardUrl);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryCyan),
                              const SizedBox(width: 6),
                              Text(
                                'Open Link',
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  cardUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
