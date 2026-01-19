import 'dart:ui';
import 'package:flutter/material.dart';

// Improved GlassScaffold with Full Screen Gradient
class FullGradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Key? scaffoldKey; // Added

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
        // 1. Fixed Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E), // Darker Navy
                Color(0xFF16213E),
                Color(0xFF0F3460), // Cyber Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // 2. Scaffold on top
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
    this.width = double.infinity,
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
