import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/ewu_theme_extension.dart';

enum EwuButtonVariant { primary, secondary, danger, ghost }

/// A premium pill CTA button featuring the Button-in-Button nested architecture,
/// subtle micro-interactions, and loading states.
class EwuPillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final EwuButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final double height;
  final double? fontSize;

  const EwuPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = EwuButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.height = 46.0,
    this.fontSize,
  });

  @override
  State<EwuPillButton> createState() => _EwuPillButtonState();
}

class _EwuPillButtonState extends State<EwuPillButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Color border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case EwuButtonVariant.primary:
        bg = isEnabled ? colors.primaryCyan : colors.primaryCyan.withValues(alpha: 0.4);
        fg = colors.isDark ? colors.primaryNavy : Colors.white;
        border = Colors.transparent;
        shadows = isEnabled
            ? [
                BoxShadow(
                  color: colors.primaryCyan.withValues(alpha: colors.isDark ? 0.35 : 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null;
        break;
      case EwuButtonVariant.secondary:
        bg = colors.surfaceElevated;
        fg = colors.primaryText;
        border = colors.borderSubtle;
        shadows = null;
        break;
      case EwuButtonVariant.danger:
        bg = colors.error.withValues(alpha: 0.15);
        fg = colors.error;
        border = colors.error.withValues(alpha: 0.3);
        shadows = null;
        break;
      case EwuButtonVariant.ghost:
        bg = Colors.transparent;
        fg = colors.secondaryText;
        border = Colors.transparent;
        shadows = null;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: GoogleFonts.sora(
            color: fg,
            fontSize: widget.fontSize ?? 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 10),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(widget.trailingIcon, size: 13, color: fg),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.2),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
