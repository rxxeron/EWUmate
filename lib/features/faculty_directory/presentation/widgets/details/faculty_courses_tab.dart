import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/academic_state.dart';
import '../../../../../core/models/course_section.dart';
import '../../../../../core/repositories/faculty_repository.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primitives/ewu_empty_state.dart';

class FacultyCoursesTab extends ConsumerWidget {
  final String facultyShortName;
  final AsyncValue<AcademicState?> activeSemesterAsync;

  const FacultyCoursesTab({
    super.key,
    required this.facultyShortName,
    required this.activeSemesterAsync,
  });

  Widget _buildClassScheduleCard(CourseSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2342),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      section.code,
                      style: GoogleFonts.sora(
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SEC: ${section.section}',
                      style: GoogleFonts.sora(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'CR: ${section.credits}',
                style: GoogleFonts.sora(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.courseName,
            style: GoogleFonts.sora(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Class sessions list
          ...section.sessions.map((session) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.day,
                      style: GoogleFonts.sora(
                        color: const Color(0xFFA78BFA),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${session.startTime} - ${session.endTime}',
                    style: GoogleFonts.sora(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.room_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    session.room,
                    style: GoogleFonts.sora(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return activeSemesterAsync.when(
      data: (state) {
        if (state == null) {
          return Center(
            child: Text(
              'Active semester not loaded.',
              style: GoogleFonts.sora(color: Colors.grey),
            ),
          );
        }

        final semesterCode = state.currentSemesterCode;
        final scheduleAsync = ref.watch(facultySectionsProvider(
          initials: facultyShortName,
          semesterCode: semesterCode,
        ));

        return scheduleAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return const Center(
                child: EwuEmptyState(
                  icon: Icons.free_breakfast_rounded,
                  title: 'No Classes Scheduled',
                  subtitle: 'This faculty member does not have any classes on schedule for this semester.',
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return _buildClassScheduleCard(section);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryCyan),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading schedule: $err',
              style: GoogleFonts.sora(color: AppColors.error),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: GoogleFonts.sora(color: AppColors.error),
        ),
      ),
    );
  }
}
