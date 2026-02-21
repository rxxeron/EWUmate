import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/semester_progress/semester_progress_screen.dart';
// import 'dart:ui';
import 'glass_kit.dart';
import 'app_drawer.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Determine current index based on location
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = _getSelectedIndex(location);

    return FullGradientScaffold(
      scaffoldKey: MainShell.scaffoldKey,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: child,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: _shouldShowBottomNav(location)
          ? Container(
              margin: const EdgeInsets.all(16),
              child: GlassContainer(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                opacity: 0.15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, 0, Icons.home_rounded, 'Home',
                        currentIndex == 0),
                    _buildNavItem(context, 1, Icons.task_alt_rounded, 'Tasks',
                        currentIndex == 1),
                    _buildNavItem(context, 2, Icons.trending_up_rounded,
                        'Semester', currentIndex == 2),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  int _getSelectedIndex(String location) {
    if (location == '/dashboard') return 0;
    if (location == '/tasks') return 1;
    if (location == '/semester-progress') return 2;
    return 0; // Default or fallback
  }

  bool _shouldShowBottomNav(String location) {
    // Only show bottom nav on main tabs
    return location == '/dashboard' ||
        location == '/tasks' ||
        location == '/semester-progress';
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/semester-progress');
        break;
    }
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon,
      String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
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
}
