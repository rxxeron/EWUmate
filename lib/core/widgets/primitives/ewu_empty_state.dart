import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/ewu_theme_extension.dart';
import 'ewu_pill_button.dart';

/// A standardized, friendly student empty state component.
class EwuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const EwuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    this.accentColor,
  })  : actionLabel = actionLabel ?? ctaLabel,
        onAction = onAction ?? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final primaryAccent = accentColor ?? colors.primaryCyan;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryAccent.withValues(alpha: colors.isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: primaryAccent.withValues(alpha: colors.isDark ? 0.25 : 0.20),
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: primaryAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: colors.secondaryText,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              EwuPillButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: EwuButtonVariant.secondary,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
