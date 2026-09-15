import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/animated_progress_ring.dart';
import '../dashboard_logic.dart'; // For ScheduleItem
import 'package:google_fonts/google_fonts.dart';

class NextClassCard extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback onMarkAttendance;
  final VoidCallback onOpenMap;
  final VoidCallback? onViewDetails;
  final bool isToday;
  final DateTime? targetDate;

  const NextClassCard({
    super.key,
    required this.item,
    required this.onMarkAttendance,
    required this.onOpenMap,
    this.onViewDetails,
    this.isToday = true,
    this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isCancelled) {
      return const SizedBox.shrink();
    }

    // Dynamic countdown and progress calculation
    final now = DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    final startMins = TimeUtils.parseTime(item.startTime);
    final endMins = TimeUtils.parseTime(item.endTime);

    final bool isOngoing = isToday && currentMins >= startMins && currentMins <= endMins;
    final String countdownNumber;
    final double progress;
    final String countdownUnit;

    if (isToday) {
      if (currentMins < startMins) {
        final diff = startMins - currentMins;
        if (diff >= 60) {
          final h = diff ~/ 60;
          final m = diff % 60;
          countdownNumber = "${h}h ${m}m";
          countdownUnit = "starts in";
        } else {
          countdownNumber = "$diff";
          countdownUnit = "min\nstarts in";
        }
        progress = (1.0 - (diff / 60.0)).clamp(0.08, 1.0);
      } else if (isOngoing) {
        final total = (endMins - startMins) > 0 ? (endMins - startMins) : 90;
        final minsRemaining = endMins - currentMins;
        countdownNumber = "$minsRemaining";
        progress = (1.0 - (minsRemaining / total)).clamp(0.08, 1.0);
        countdownUnit = "min\nremaining";
      } else {
        countdownNumber = "0";
        progress = 1.0;
        countdownUnit = "completed";
      }
    } else {
      // Upcoming on a future date (e.g. tomorrow)
      final target = targetDate ?? now.add(const Duration(days: 1));
      final startHour = startMins ~/ 60;
      final startMin = startMins % 60;
      final classDt = DateTime(target.year, target.month, target.day, startHour, startMin);
      final diff = classDt.difference(now);

      if (diff.inHours >= 1) {
        countdownNumber = "${diff.inHours}h";
        countdownUnit = "${diff.inMinutes % 60}m\nstarts in";
        progress = 0.35;
      } else if (diff.inMinutes > 0) {
        countdownNumber = "${diff.inMinutes}";
        countdownUnit = "min\nstarts in";
        progress = (1.0 - (diff.inMinutes / 60.0)).clamp(0.08, 1.0);
      } else {
        countdownNumber = item.startTime;
        countdownUnit = "upcoming";
        progress = 0.5;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2547).withValues(alpha: 0.72),
            const Color(0xFF08182F).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryCyan.withValues(alpha: 0.50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOngoing ? const Color(0xFF10B981) : AppColors.primaryCyan,
                    ),
                  ),
                  Text(
                    isOngoing
                        ? "Happening Now"
                        : (isToday ? "Next Class" : "Next Class Tomorrow"),
                    style: GoogleFonts.sora(
                      color: isOngoing ? const Color(0xFF10B981) : AppColors.primaryCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    isOngoing ? Icons.radio_button_checked_rounded : Icons.arrow_forward_rounded,
                    color: isOngoing ? const Color(0xFF10B981) : AppColors.primaryCyan,
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.courseCode} · ${item.sessionType}",
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.courseName.isNotEmpty ? item.courseName : "Course Name",
                      style: GoogleFonts.sora(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time_rounded, "${item.startTime} - ${item.endTime}"),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.location_on_outlined, item.room),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.person_outline, item.faculty),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Compact Animated Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isOngoing ? const Color(0xFF10B981) : AppColors.primaryCyan).withValues(alpha: 0.28),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedProgressRing(
                      progress: progress,
                      size: 78,
                      strokeWidth: 5.5,
                      activeColor: isOngoing ? const Color(0xFF10B981) : AppColors.primaryCyan,
                      backgroundColor: AppColors.primaryNavy,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        countdownNumber,
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: countdownNumber.length > 3 ? 15 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        countdownUnit,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          color: Colors.white70,
                          fontSize: 8.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: (isOngoing || (isToday && currentMins >= endMins))
                    ? ElevatedButton(
                        onPressed: onMarkAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: AppColors.primaryCyan.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Text(
                              "Mark Attendance",
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onViewDetails ?? onOpenMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: AppColors.primaryCyan.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_outlined, size: 15, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Text(
                              "View Details",
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryCyan),
                      const SizedBox(width: 5),
                      Text(
                        "Open Map",
                        style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.sora(
              color: Colors.white70,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
