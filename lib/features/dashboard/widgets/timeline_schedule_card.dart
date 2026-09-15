import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../dashboard_logic.dart'; // For ScheduleItem
import '../../../core/utils/time_utils.dart';

class TimelineScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final bool isOngoing;
  final bool isNext;

  const TimelineScheduleCard({
    super.key,
    required this.item,
    this.isOngoing = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${TimeUtils.extractTimeNumber(item.startTime)} ${TimeUtils.extractAmPm(item.startTime).toUpperCase()}',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${TimeUtils.extractTimeNumber(item.endTime)} ${TimeUtils.extractAmPm(item.endTime).toUpperCase()}',
                  style: GoogleFonts.sora(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Timeline Indicator (Dot + Line)
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOngoing 
                      ? AppColors.primaryCyan 
                      : (isNext ? AppColors.secondarySoftBlue : AppColors.secondaryText.withValues(alpha: 0.3)),
                  border: isOngoing 
                      ? Border.all(color: AppColors.primaryNavy, width: 2)
                      : null,
                ),
              ),
              Container(
                width: 2,
                height: 50, // Arbitrary height for timeline connection
                color: AppColors.secondaryText.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content Card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${item.courseCode} · ${item.sessionType}",
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOngoing || isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOngoing 
                              ? AppColors.primaryCyan.withValues(alpha: 0.1)
                              : AppColors.secondarySoftBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isOngoing ? AppColors.primaryCyan : AppColors.secondarySoftBlue,
                          ),
                        ),
                        child: Text(
                          isOngoing ? "Ongoing" : "Next",
                          style: GoogleFonts.sora(
                            color: isOngoing ? AppColors.primaryCyan : AppColors.secondarySoftBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Room ${item.room} | ${item.faculty}",
                  style: GoogleFonts.sora(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
