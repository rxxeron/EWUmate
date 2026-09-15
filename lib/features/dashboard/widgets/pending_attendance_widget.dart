import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ewu_theme_extension.dart';

/// Compact, non-intrusive pending attendance card shown on the Dashboard.
class PendingAttendanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isSaving;
  final void Function(Map<String, dynamic> item, String status) onMarkSingle;
  final void Function(List<Map<String, dynamic>> items, String status) onMarkMultiple;

  const PendingAttendanceWidget({
    super.key,
    required this.items,
    required this.isSaving,
    required this.onMarkSingle,
    required this.onMarkMultiple,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.ewuColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.8 : 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amberAccent.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fact_check_rounded, color: Colors.amberAccent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Pending Attendance",
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${items.length} pending",
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMarkMultiple(items, 'joined');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'All Attended',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: colors.primaryCyan, strokeWidth: 2),
                ),
              ),
            )
          else
            ...items.take(3).map((it) {
              final code = it['course_code'] ?? 'Unknown';
              final sessionType = it['session_type'] ?? 'Theory';
              final dt = it['date'] as DateTime? ?? DateTime.now();
              final dateStr = DateFormat('EEE, MMM d').format(dt);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Text(
                        code,
                        style: GoogleFonts.sora(
                          color: colors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (sessionType == 'Lab' ? Colors.orange : colors.primaryCyan).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sessionType.toUpperCase(),
                          style: GoogleFonts.sora(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: sessionType == 'Lab' ? Colors.orangeAccent : colors.primaryCyan,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: GoogleFonts.sora(
                          color: colors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onMarkSingle(it, 'joined');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onMarkSingle(it, 'missed');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  "+ ${items.length - 3} more pending classes",
                  style: GoogleFonts.sora(
                    color: colors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
