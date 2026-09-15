import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/ewu_theme_extension.dart';

enum EwuBadgeVariant { filled, outline, subtle }
typedef EwuBadgeType = EwuBadgeVariant;

/// High-contrast status, room, and category badge component for fast scanning.
class EwuBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final EwuBadgeVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const EwuBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    EwuBadgeVariant? variant,
    EwuBadgeVariant? type,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  }) : variant = type ?? variant ?? EwuBadgeVariant.subtle;

  factory EwuBadge.room(String room, {double fontSize = 11.0}) {
    return EwuBadge(
      label: room,
      icon: Icons.meeting_room_outlined,
      color: const Color(0xFF19D9F5),
      variant: EwuBadgeVariant.subtle,
      fontSize: fontSize,
    );
  }

  factory EwuBadge.section(String section, {double fontSize = 11.0}) {
    return EwuBadge(
      label: section,
      icon: Icons.group_work_outlined,
      color: const Color(0xFF5EA8FF),
      variant: EwuBadgeVariant.subtle,
      fontSize: fontSize,
    );
  }

  factory EwuBadge.status(String status, {required Color color, double fontSize = 11.0}) {
    return EwuBadge(
      label: status,
      color: color,
      variant: EwuBadgeVariant.subtle,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final baseColor = color ?? colors.primaryCyan;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case EwuBadgeVariant.filled:
        bg = baseColor;
        fg = colors.isDark ? colors.primaryNavy : Colors.white;
        border = Colors.transparent;
        break;
      case EwuBadgeVariant.outline:
        bg = Colors.transparent;
        fg = baseColor;
        border = baseColor.withValues(alpha: 0.4);
        break;
      case EwuBadgeVariant.subtle:
        bg = baseColor.withValues(alpha: colors.isDark ? 0.16 : 0.12);
        fg = baseColor;
        border = baseColor.withValues(alpha: colors.isDark ? 0.28 : 0.24);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.sora(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
