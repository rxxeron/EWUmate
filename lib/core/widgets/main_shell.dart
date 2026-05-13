import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'glass_kit.dart';
import '../providers/scaffold_provider.dart';
import 'app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Determine current index based on location
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = _getSelectedIndex(location);

    return ProviderScope(
      overrides: [
        scaffoldKeyProvider.overrideWithValue(_scaffoldKey),
      ],
      child: FullGradientScaffold(
        scaffoldKey: _scaffoldKey,
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
          child: widget.child,
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar: _shouldShowBottomNav(location)
          ? Container(
              height: 64,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPillNavItem(context, 0, Icons.home_rounded, 'Home', currentIndex == 0),
                  _buildPillNavItem(context, 1, Icons.task_alt_rounded, 'Tasks', currentIndex == 1),
                  _buildPillNavItem(context, 2, Icons.auto_graph_rounded, 'Semester', currentIndex == 2),
                ],
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildPillNavItem(BuildContext context, int index, IconData icon, String label, bool isSelected) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, color: Colors.white54, size: 24),
      onPressed: () => _onItemTapped(context, index),
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
      case 3:
        context.go('/services');
        break;
    }
  }
}
