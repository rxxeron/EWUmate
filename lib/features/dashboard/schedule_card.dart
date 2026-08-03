import 'package:flutter/material.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/time_utils.dart';
import 'dashboard_logic.dart'; // For ScheduleItem

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final Widget? trailing;
  final bool compact;

  const ScheduleCard({super.key, required this.item, this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final bool isLab = item.sessionType == 'Lab';
    Color accentColor = isLab ? Colors.orangeAccent : Colors.cyanAccent;
    String badgeText = item.sessionType;
    if (item.isMakeup) {
      accentColor = Colors.purpleAccent;
      badgeText = "MAKEUP";
    } else if (item.isCancelled) {
      accentColor = Colors.redAccent;
      badgeText = "CANCELLED";
    }

    return compact ? _buildCompact(accentColor, badgeText) : _buildRich(accentColor, badgeText);
  }

  // ─── RICH LAYOUT (Dashboard) ───
  // Course name big on top, type badge + faculty on right, room bold below
  Widget _buildRich(Color accentColor, String badgeText) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      opacity: item.isCancelled ? 0.05 : 0.1,
      borderColor: accentColor.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          Column(
            children: [
              Text(
                TimeUtils.extractTimeNumber(item.startTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                TimeUtils.extractAmPm(item.startTime),
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 25, width: 3,
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              Text(
                TimeUtils.extractTimeNumber(item.endTime),
                style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Course name + badge on right
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.courseName.isNotEmpty ? item.courseName : item.courseCode,
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                          decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                          decorationThickness: 2.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(badgeText, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: Course code + faculty on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.courseCode,
                      style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14,
                        decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                        decorationThickness: 2.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          item.faculty.isNotEmpty ? item.faculty : "TBA",
                          style: TextStyle(
                            color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500,
                            decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                            decorationThickness: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 3: Room (bold, accent)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Room ${item.room.isNotEmpty ? item.room : 'TBA'}",
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
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
  // Tight card with trailing action slot for Cancel button
  Widget _buildCompact(Color accentColor, String badgeText) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      opacity: item.isCancelled ? 0.05 : 0.1,
      borderColor: accentColor.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TimeUtils.extractTimeNumber(item.startTime),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                TimeUtils.extractAmPm(item.startTime).toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 15, width: 2,
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              Text(
                TimeUtils.extractTimeNumber(item.endTime),
                style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 16),
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
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: accentColor,
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
                      child: Text(badgeText, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: Course name
                Text(
                  item.courseName.isNotEmpty ? item.courseName : 'Session',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Row 3: Faculty + Room
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(item.faculty.isNotEmpty ? item.faculty : "TBA", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(item.room, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trailing action (Cancel button)
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
