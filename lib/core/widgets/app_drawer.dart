import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'glass_kit.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        borderRadius: 0,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        opacity: 0.1,
        blur: 20,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: profileAsync.when(
                data: (profile) {
                  final displayName = profile?.nickname ?? profile?.fullName ?? user?.userMetadata?['full_name']?.toString().split(' ').first ?? "Student";
                  final photoURL = profile?.photoUrl ?? user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['photoURL'];
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                            ? CachedNetworkImageProvider(photoURL)
                            : null,
                        child: (photoURL == null || photoURL.isEmpty)
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
                error: (e, _) => const Center(child: Icon(Icons.error, color: Colors.red)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(context, Icons.dashboard_rounded, "Dashboard",
                      () => context.go('/dashboard')),
                  _buildDrawerItem(context, Icons.person_outline, "Profile",
                      () => context.push('/profile')),
                  _buildDrawerItem(
                      context,
                      Icons.notifications_outlined,
                      "Notifications",
                      () => context.push('/notifications')),
                  _buildDrawerItem(
                      context,
                      Icons.bar_chart_rounded,
                      "Degree Progress",
                      () => context.push('/degree-progress')),
                  _buildDrawerItem(
                      context,
                      Icons.insights_rounded,
                      "Semester Summary",
                      () => context.push('/semester-summary'),
                      color: Colors.cyanAccent),
                  _buildDrawerItem(context, Icons.search, "Course Browser",
                      () => context.push('/courses')),
                  _buildDrawerItem(context, Icons.event_note_rounded, "Advising",
                      () => context.push('/advising')),
                  _buildDrawerItem(context, Icons.edit_calendar, "Manage Schedule",
                      () => context.push('/schedule-manager')),
                  _buildDrawerItem(
                      context, Icons.next_plan_rounded, "Next Semester",
                      () => context.push('/next-semester'),
                      color: Colors.cyanAccent),                  _buildDrawerItem(
                    context,
                    Icons.apps_rounded,
                    "App Services",
                    () => context.push('/services'),
                    color: Colors.amberAccent,
                  ),
                  _buildDrawerItem(
                        context, Icons.feedback_outlined, "Feedback & Support",
                        () => context.push('/feedback'),
                        color: Colors.lightGreenAccent),                  const Divider(color: Colors.white24),
                  _buildDrawerItem(
                    context,
                    Icons.logout,
                    "Logout",
                    () async {
                      // Do not wait out the context, use a callback immediately.
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    color: Colors.redAccent,
                    closeDrawer: false, // Don't pop manually, routing to /login will destroy the widget tree anyway!
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.white, bool closeDrawer = true}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        if (closeDrawer && context.mounted) {
          Navigator.pop(context);
        }
        onTap();
      },
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
