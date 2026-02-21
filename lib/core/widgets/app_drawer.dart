import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'glass_kit.dart';
import '../../features/results/results_repository.dart';
import '../../core/models/result_models.dart';
import '../services/ramadan_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return StreamBuilder<AcademicProfile>(
      stream: ResultsRepository().streamAcademicProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        // Fallback hierarchy: Nickname -> First Name -> Student
        String displayName = profile?.nickname ?? "";
        if (displayName.isEmpty) {
          displayName = profile?.studentName.split(' ').first ?? "";
        }
        if (displayName.isEmpty) {
          displayName = user?.userMetadata?['full_name']?.toString() ??
              user?.userMetadata?['name']?.toString() ??
              "Student";
        }

        final photoURL = profile?.photoUrl ??
            user?.userMetadata?['avatar_url']?.toString() ??
            user?.userMetadata?['photoURL']?.toString();

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                            ? NetworkImage(photoURL)
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
                          color: Colors.cyanAccent),
                      FutureBuilder<bool>(
                        future: RamadanService.isRamadanSeason(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return _buildDrawerItem(
                                context, Icons.mosque_outlined, "Ramadan Calendar",
                                () => context.push('/ramadan'),
                                color: Colors.amberAccent);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildDrawerItem(
                        context,
                        Icons.logout,
                        "Logout",
                        () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
