import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/ewu_theme_extension.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/time_utils.dart';
import 'dashboard_logic.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final Widget? trailing;
  final bool compact;

  const ScheduleCard({super.key, required this.item, this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final bool isLab = item.sessionType == 'Lab';
    Color accentColor = isLab ? colors.accentAmber : colors.primaryCyan;
    String badgeText = item.sessionType;
    if (item.isMakeup) {
      accentColor = colors.secondarySoftBlue;
      badgeText = "MAKEUP";
    } else if (item.isCancelled) {
      accentColor = colors.accentAlert;
      badgeText = "CANCELLED";
    }

    return compact ? _buildCompact(accentColor, badgeText, colors) : _buildRich(accentColor, badgeText, colors);
  }

  // ─── RICH LAYOUT (Dashboard) ───
  Widget _buildRich(Color accentColor, String badgeText, EwuColors colors) {
    return GlassContainer(
      color: colors.surfaceNavyBlue,
      opacity: 0.65,
      borderColor: accentColor.withValues(alpha: 0.28),
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column with vertical connector line
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TimeUtils.extractTimeNumber(item.startTime),
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              Text(
                TimeUtils.extractAmPm(item.startTime),
                style: GoogleFonts.sora(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 14,
                width: 2,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(vertical: 3),
              ),
              Text(
                TimeUtils.extractTimeNumber(item.endTime),
                style: GoogleFonts.sora(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Vertical divider
          Container(
            height: 38,
            width: 1,
            color: colors.borderSubtle,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Course name + badge on right
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.courseName.isNotEmpty ? item.courseName : item.courseCode,
                        style: GoogleFonts.sora(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                          decorationThickness: 2.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.sora(color: accentColor, fontWeight: FontWeight.bold, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Row 2: Course code + faculty on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.courseCode,
                      style: GoogleFonts.sora(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, size: 13, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.faculty.isNotEmpty ? item.faculty : "TBA",
                          style: GoogleFonts.sora(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Row 3: Room (bold, accent)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Room ${item.room.isNotEmpty ? item.room : 'TBA'}",
                        style: GoogleFonts.sora(color: accentColor, fontWeight: FontWeight.w600, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMPACT LAYOUT (Schedule Manager) ───
  Widget _buildCompact(Color accentColor, String badgeText, EwuColors colors) {
    return GlassContainer(
      color: colors.surfaceNavyBlue,
      opacity: 0.65,
      borderColor: accentColor.withValues(alpha: 0.28),
      borderRadius: 18,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TimeUtils.extractTimeNumber(item.startTime),
                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              Text(
                TimeUtils.extractAmPm(item.startTime).toUpperCase(),
                style: GoogleFonts.sora(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 14,
                width: 2,
                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 3),
              ),
              Text(
                TimeUtils.extractTimeNumber(item.endTime),
                style: GoogleFonts.sora(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Course code + badge
                Row(
                  children: [
                    Text(
                      item.courseCode,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.sora(color: accentColor, fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: Course name
                Text(
                  item.courseName.isNotEmpty ? item.courseName : 'Session',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Row 3: Faculty + Room
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.faculty.isNotEmpty ? item.faculty : "TBA",
                      style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_outlined, size: 13, color: accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.room,
                        style: GoogleFonts.sora(color: accentColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trailing action (Cancel/Delete button)
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
