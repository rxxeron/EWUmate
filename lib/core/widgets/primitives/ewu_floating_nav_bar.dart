import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/ewu_theme_extension.dart';

class EwuNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const EwuNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A modern, detached floating glass navigation bar with smooth animated
/// active indicators and tactile feedback.
class EwuFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<EwuNavItem> items;

  const EwuFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.86 : 0.94),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : colors.borderSubtle,
                  width: 1.2,
                ),
                boxShadow: [
                  // Deep shadow for floating detachment
                  BoxShadow(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.65)
                        : const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  // Ambient cyan flow underglow
                  if (colors.isDark)
                    BoxShadow(
                      color: colors.primaryCyan.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return _NavBarItemWidget(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.selectionClick();
                        onItemSelected(index);
                      }
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatefulWidget {
  final EwuNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.primaryCyan
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: colors.primaryCyan.withValues(alpha: 0.42),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                size: 20,
                color: widget.isSelected
                    ? const Color(0xFF071426)
                    : colors.secondaryText,
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.sora(
                    color: const Color(0xFF071426),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
