import 'package:flutter/material.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/utils/time_utils.dart';
import 'dashboard_logic.dart'; // For ScheduleItem

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;

  const ScheduleCard({super.key, required this.item});

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

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      opacity: item.isCancelled ? 0.05 : 0.1,
      borderColor: accentColor.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                TimeUtils.extractTimeNumber(item.startTime),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                TimeUtils.extractAmPm(item.startTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                height: 25,
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              Text(
                TimeUtils.extractTimeNumber(item.endTime),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.courseName.isNotEmpty
                            ? item.courseName
                            : item.courseCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: item.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationThickness: 2.5,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.courseCode,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: item.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationThickness: 2.5,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.faculty.isNotEmpty ? item.faculty : "TBA",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationThickness: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!item.isCancelled)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Room ${item.room.isNotEmpty ? item.room : 'TBA'}",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
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
}
