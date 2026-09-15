import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickActionPill(
            label: "Routine",
            icon: Icons.calendar_month_rounded,
            accentColor: colors.primaryCyan,
            onTap: () => context.push('/schedule-manager'),
          ),
          const SizedBox(width: 8),
          _QuickActionPill(
            label: "CGPA Calc",
            icon: Icons.calculate_outlined,
            accentColor: colors.primaryCyan,
            onTap: () => context.push('/semester-progress'),
          ),
          const SizedBox(width: 8),
          _QuickActionPill(
            label: "Faculty",
            icon: Icons.people_outline_rounded,
            accentColor: colors.primaryCyan,
            onTap: () => context.push('/services/faculty-directory'),
          ),
          const SizedBox(width: 8),
          _QuickActionPill(
            label: "My Tasks",
            icon: Icons.task_alt_rounded,
            accentColor: colors.primaryCyan,
            onTap: () => context.push('/tasks'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<_QuickActionPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.65 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: colors.isDark ? 0.16 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(widget.icon, size: 20, color: widget.accentColor),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.sora(
                    color: colors.primaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
