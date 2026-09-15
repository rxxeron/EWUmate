import 'dart:ui';
import 'package:flutter/material.dart';

// Improved GlassScaffold with Full Screen Gradient
class FullGradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final GlobalKey<ScaffoldState>? scaffoldKey; // Added

  const FullGradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.scaffoldKey, // Added
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base Gradient Background (Deep Midnight Navy)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF08172E), // Rich Figma Navy
                Color(0xFF050E1A), // Deep Navy Void
                Color(0xFF040A14), // Base Dark
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // 2. Luminous Ambient Radial Glow ("Cyan Flow" - matches Figma 15.21.20 & 15.28.30 (5))
        Positioned(
          top: -80,
          left: -60,
          right: -60,
          height: 480,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.25),
                  radius: 0.95,
                  colors: [
                    const Color(0xFF19D9F5).withValues(alpha: 0.18), // EWU Cyan Glow
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
        // 4. Scaffold on top
        Scaffold(
          key: scaffoldKey, // Added
          backgroundColor: Colors.transparent,
          appBar: appBar,
          drawer: drawer,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          body: body, // Body is transparent, so gradient shows through
        ),
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
