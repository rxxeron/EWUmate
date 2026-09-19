import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Improved GlassScaffold with Full Screen Gradient
class FullGradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool autoHandleBack;
  final VoidCallback? onBackOverride;

  static DateTime? _lastBackPressTime;

  const FullGradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.scaffoldKey,
    this.autoHandleBack = true,
    this.onBackOverride,
  });

  static void _showExitSnackBar(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.removeCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Press back again to exit EWUmate',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Dark Navy Deep Foundation Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF060B18), // Deep Midnight Slate
                  Color(0xFF0A1128), // High-depth Navy
                  Color(0xFF050B16), // Solid Foundation
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        // 2. Subtle Cyan/Cobalt Ambient Radial Glow in upper screen
        Positioned(
          top: -80,
          left: -60,
          width: 320,
          height: 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.10), // Vibrant Cyan glow
                    const Color(0xFF0D47A1).withValues(alpha: 0.12), // Deep Cobalt
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        // 3. Secondary Soft Blue Ambient Glow in lower screen
        Positioned(
          bottom: 40,
          right: -100,
          width: 360,
          height: 360,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // 4. Scaffold on top with smart back handling
        () {
          Widget scaffold = Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: appBar,
            drawer: drawer,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            body: body,
          );

          if (autoHandleBack) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, dynamic result) {
                if (didPop) return;

                if (onBackOverride != null) {
                  onBackOverride!();
                  return;
                }

                // 1. If drawer is open on this scaffold or ancestor scaffold, close it
                if (scaffoldKey?.currentState?.isDrawerOpen == true) {
                  scaffoldKey?.currentState?.closeDrawer();
                  return;
                }
                final parentScaffold = Scaffold.maybeOf(context);
                if (parentScaffold?.isDrawerOpen == true) {
                  parentScaffold?.closeDrawer();
                  return;
                }

                // 2. If there are stacked routes to pop, pop it
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                // 3. Fallback routing based on current path
                String currentPath = '';
                try {
                  currentPath = GoRouterState.of(context).uri.path;
                } catch (_) {}

                // Auth flow
                if (currentPath == '/login' || currentPath == '/') {
                  final now = DateTime.now();
                  if (_lastBackPressTime != null &&
                      now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
                    SystemNavigator.pop();
                  } else {
                    _lastBackPressTime = now;
                    _showExitSnackBar(context);
                  }
                  return;
                }

                if (currentPath == '/register' ||
                    currentPath == '/forgot-password' ||
                    currentPath == '/reset-password') {
                  context.go('/login');
                  return;
                }

                // Dashboard / Home root: double-tap to exit
                if (currentPath == '/dashboard' || currentPath.isEmpty) {
                  final now = DateTime.now();
                  if (_lastBackPressTime != null &&
                      now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
                    SystemNavigator.pop();
                  } else {
                    _lastBackPressTime = now;
                    _showExitSnackBar(context);
                  }
                  return;
                }

                // For all other secondary tabs/pages without pop history, return to Dashboard
                context.go('/dashboard');
              },
              child: scaffold,
            );
          }

          return scaffold;
        }(),
      ],
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width; // Made nullable to allow content-sized width in Row
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // Added support
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.width, // Removed default double.infinity to prevent layout issues
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius = 20,
    this.borderColor,
    this.color,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
              gradient: LinearGradient(
                colors: [
                  (color ?? Colors.white).withValues(alpha: opacity + 0.05),
                  (color ?? Colors.white).withValues(alpha: opacity),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }
    return content;
  }
}
