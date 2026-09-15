import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/ewu_theme_extension.dart';

class PendingEventsTab extends StatelessWidget {
  final List<Map<String, dynamic>> pendingActions;
  final void Function(Map<String, dynamic> action) onRevert;
  final void Function(Map<String, dynamic> action) onMakeup;

  const PendingEventsTab({
    super.key,
    required this.pendingActions,
    required this.onRevert,
    required this.onMakeup,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    if (pendingActions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.done_all_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              "Everything is on schedule!",
              style: GoogleFonts.sora(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No cancelled or pending makeup sessions.",
              style: GoogleFonts.sora(
                color: colors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingActions.length,
      itemBuilder: (ctx, idx) {
        final action = pendingActions[idx];
        final dateStr = action['date']?.toString() ?? 'Pending Date';
        final code = action['course_code']?.toString() ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.75 : 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cancelled: $code",
                      style: GoogleFonts.sora(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Original Date: $dateStr",
                      style: GoogleFonts.sora(
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => onRevert(action),
                    child: Text(
                      "REVERT",
                      style: GoogleFonts.sora(
                        color: colors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => onMakeup(action),
                    child: Text(
                      "MAKEUP",
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
