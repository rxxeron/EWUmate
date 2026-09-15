import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
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
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF091A33),
              Color(0xFF061224),
              Color(0xFF040A14),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            right: BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. User Profile Header Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: profileAsync.when(
                  data: (profile) {
                    final displayName = profile?.nickname ??
                        profile?.fullName ??
                        user?.userMetadata?['full_name']?.toString().split(' ').first ??
                        "Student";
                    final photoURL = profile?.photoUrl ??
                        user?.userMetadata?['avatar_url'] ??
                        user?.userMetadata?['photoURL'];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: CircleAvatar(
                                backgroundColor: AppColors.primaryNavy,
                                backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                                    ? CachedNetworkImageProvider(photoURL)
                                    : null,
                                child: (photoURL == null || photoURL.isEmpty)
                                    ? const Icon(Icons.person, color: AppColors.secondaryText, size: 26)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? "",
                                  style: GoogleFonts.sora(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Active Student",
                                        style: GoogleFonts.sora(
                                          color: const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primaryCyan),
                    ),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),

              // 2. Navigation List
              // 2. Navigation List
              Expanded(
                child: Builder(
                  builder: (context) {
                    String currentPath = '';
                    try {
                      currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
                    } catch (_) {}

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      children: [
                        _buildSectionHeader("MAIN NAVIGATION"),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.dashboard_rounded,
                          title: "Dashboard",
                          route: '/dashboard',
                          currentPath: currentPath,
                          onTap: () => context.go('/dashboard'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          title: "Profile",
                          route: '/profile',
                          currentPath: currentPath,
                          onTap: () => context.push('/profile'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.notifications_outlined,
                          title: "Notifications",
                          route: '/notifications',
                          currentPath: currentPath,
                          onTap: () => context.push('/notifications'),
                        ),

                        const SizedBox(height: 12),
                        _buildSectionHeader("ACADEMICS"),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.search_rounded,
                          title: "Course Browser",
                          route: '/courses',
                          currentPath: currentPath,
                          onTap: () => context.push('/courses'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.event_note_rounded,
                          title: "Pre-Advising",
                          route: '/advising',
                          currentPath: currentPath,
                          onTap: () => context.push('/advising'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.bar_chart_rounded,
                          title: "Degree Progress",
                          route: '/degree-progress',
                          currentPath: currentPath,
                          onTap: () => context.push('/degree-progress'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.insights_rounded,
                          title: "Semester Summary",
                          route: '/semester-summary',
                          currentPath: currentPath,
                          onTap: () => context.push('/semester-summary'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.edit_calendar_rounded,
                          title: "Manage Schedule",
                          route: '/schedule-manager',
                          currentPath: currentPath,
                          onTap: () => context.push('/schedule-manager'),
                        ),

                        const SizedBox(height: 12),
                        _buildSectionHeader("SERVICES & UTILITIES"),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.cloud_sync_rounded,
                          title: "Portal Sync",
                          route: '/portal-sync',
                          currentPath: currentPath,
                          onTap: () => context.push('/portal-sync'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.apps_rounded,
                          title: "App Services",
                          route: '/services',
                          currentPath: currentPath,
                          onTap: () => context.push('/services'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.assignment_ind_outlined,
                          title: "Faculty Assignment",
                          route: '/services/faculty-assignment',
                          currentPath: currentPath,
                          onTap: () => context.push('/services/faculty-assignment'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.play_circle_outline_rounded,
                          title: "Video Tutorials",
                          route: '/tutorials',
                          currentPath: currentPath,
                          onTap: () => context.push('/tutorials'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.auto_stories_rounded,
                          title: "Feature Walkthrough",
                          route: '/onboarding/welcome-tour',
                          currentPath: currentPath,
                          onTap: () => context.push('/onboarding/welcome-tour'),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.feedback_outlined,
                          title: "Feedback & Support",
                          route: '/feedback',
                          currentPath: currentPath,
                          onTap: () => context.push('/feedback'),
                        ),

                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.08)),
                        const SizedBox(height: 8),

                        // Logout Action
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                          ),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            title: Text(
                              "Logout",
                              style: GoogleFonts.sora(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 3. App Version Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "EWUmate v2.0 • Built for EWU Students",
                  style: GoogleFonts.sora(
                    color: AppColors.secondaryText.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.sora(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? route,
    String? currentPath,
  }) {
    final bool isActive = route != null &&
        currentPath != null &&
        currentPath.isNotEmpty &&
        (currentPath == route || (route != '/dashboard' && currentPath.startsWith(route)));

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryCyan.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.28), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.surfaceNavyBlue.withValues(alpha: 0.5),
          splashColor: AppColors.primaryCyan.withValues(alpha: 0.12),
          onTap: () {
            if (context.mounted) {
              Navigator.pop(context);
            }
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryCyan.withValues(alpha: 0.20)
                        : AppColors.primaryCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryCyan.withValues(alpha: 0.40)
                          : AppColors.primaryCyan.withValues(alpha: 0.14),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryCyan,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.sora(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isActive
                      ? AppColors.primaryCyan
                      : Colors.white.withValues(alpha: 0.18),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

