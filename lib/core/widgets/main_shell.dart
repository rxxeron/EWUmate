import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/semester_progress/semester_progress_screen.dart';
// import 'dart:ui';
import 'glass_kit.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<TasksScreenState> _tasksKey = GlobalKey<TasksScreenState>();

  void _onItemTapped(int index) {
    if (index == 1) {
      // Refresh tasks when switching to the tab
      _tasksKey.currentState?.refreshData();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(
        onSeeAllTasks: () => _onItemTapped(1),
      ),
      TasksScreen(key: _tasksKey),
      const SemesterProgressScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      scaffoldKey: MainShell.scaffoldKey, // Pass the static key
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      drawer: Drawer(
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
                            color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage:
                            (user != null && user?.photoURL != null)
                                ? NetworkImage(user!.photoURL!)
                                : null,
                        child: (user?.photoURL == null)
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
                              user?.displayName ?? "Student",
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
                      _buildDrawerItem(Icons.person_outline, "Profile",
                          () => context.push('/profile')),
                      _buildDrawerItem(
                          Icons.notifications_outlined,
                          "Notifications",
                          () => context.push('/notifications')),
                      _buildDrawerItem(
                          Icons.bar_chart_rounded,
                          "Degree Progress",
                          () => context.push('/degree-progress')),
                      _buildDrawerItem(Icons.search, "Course Browser",
                          () => context.push('/courses')),
                      _buildDrawerItem(Icons.event_note_rounded, "Advising",
                          () => context.push('/advising')),
                      _buildDrawerItem(Icons.edit_calendar, "Manage Schedule",
                          () => context.push('/schedule-manager')),
                      _buildDrawerItem(Icons.next_plan_rounded, "Next Semester",
                          () => context.push('/next-semester'),
                          color: Colors.cyanAccent),
                      const Divider(color: Colors.white24),
                      _buildDrawerItem(
                        Icons.logout,
                        "Logout",
                        () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          opacity: 0.15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.task_alt_rounded, 'Tasks'),
              _buildNavItem(2, Icons.trending_up_rounded, 'Semester'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color:
                    const Color(0xFF00E5FF).withValues(alpha: 0.2), // Neon Cyan
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1)
                ],
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white54,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
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
