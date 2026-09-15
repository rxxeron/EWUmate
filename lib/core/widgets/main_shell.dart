import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'glass_kit.dart';
import '../providers/scaffold_provider.dart';
import 'app_drawer.dart';
import '../../features/auth/auth_providers.dart';

import 'primitives/ewu_floating_nav_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<EwuNavItem> _navItems = [
    EwuNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Home',
    ),
    EwuNavItem(
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
      label: 'Tasks',
    ),
    EwuNavItem(
      icon: Icons.auto_graph_outlined,
      activeIcon: Icons.auto_graph_rounded,
      label: 'Progress',
    ),
    EwuNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Schedule',
    ),
    EwuNavItem(
      icon: Icons.widgets_outlined,
      activeIcon: Icons.widgets_rounded,
      label: 'Services',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen to grade blocker changes and redirect immediately if blocked
    ref.listen<AsyncValue<bool>>(requiresGradeEntryProvider, (previous, next) {
      if (next.hasValue && next.value == true) {
        debugPrint("[MainShell] Grade blocker detected! Redirecting to grade entry.");
        context.go('/results/grade-entry');
      }
    });

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
          duration: const Duration(milliseconds: 250),
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
            ? EwuFloatingNavBar(
                currentIndex: currentIndex,
                onItemSelected: (index) => _onItemTapped(context, index),
                items: _navItems,
              )
            : null,
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/semester-progress')) return 2;
    if (location.startsWith('/schedule-manager')) return 3;
    if (location.startsWith('/services')) return 4;
    return 0; // Default or fallback
  }

  bool _shouldShowBottomNav(String location) {
    return location == '/dashboard' ||
        location == '/tasks' ||
        location == '/semester-progress' ||
        location == '/schedule-manager' ||
        location == '/services';
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
        context.go('/schedule-manager');
        break;
      case 4:
        context.go('/services');
        break;
    }
  }
}
