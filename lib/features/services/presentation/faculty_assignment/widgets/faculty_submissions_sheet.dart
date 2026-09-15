import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/course_utils.dart';
import '../../../../../core/widgets/primitives/ewu_empty_state.dart';
import '../../../repositories/faculty_assignment_repository.dart';

void showFacultySubmissionsSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF071426),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<List<FacultyAssignmentSubmission>>(
            future: ref.read(facultyAssignmentRepositoryProvider).fetchMySubmissions(),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, color: AppColors.primaryCyan, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'My Submissions History',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
                          : (snapshot.data == null || snapshot.data!.isEmpty)
                              ? const Center(
                                  child: EwuEmptyState(
                                    icon: Icons.history_edu_rounded,
                                    title: 'No Submissions Yet',
                                    subtitle: 'Your submitted faculty verification requests will appear here.',
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final item = snapshot.data![index];
                                    final isApproved = item.status == 'APPROVED';
                                    final isPending = item.status == 'PENDING';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D2342),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isApproved
                                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                              : isPending
                                                  ? AppColors.primaryCyan.withValues(alpha: 0.25)
                                                  : AppColors.error.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.facultyInitial ?? 'Faculty Assignment',
                                                style: GoogleFonts.sora(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (isApproved
                                                          ? const Color(0xFF10B981)
                                                          : isPending
                                                              ? const Color(0xFFF59E0B)
                                                              : AppColors.error)
                                                      .withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.status,
                                                style: GoogleFonts.sora(
                                                  color: isApproved
                                                      ? const Color(0xFF10B981)
                                                      : isPending
                                                          ? const Color(0xFFF59E0B)
                                                          : AppColors.error,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${CourseUtils.prettifySemesterCode(item.semester)} • ${item.assignments.length} Course Assignments',
                                          style: GoogleFonts.sora(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (item.assignments.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: item.assignments.map((asgn) {
                                              final isLab = asgn.sessionType.toLowerCase() == 'lab';
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF071426),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.white12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${asgn.courseCode} Sec ${asgn.sectionNumber}',
                                                      style: GoogleFonts.sora(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: isLab ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : AppColors.primaryCyan.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        isLab ? 'L' : 'T',
                                                        style: GoogleFonts.sora(
                                                          color: isLab ? const Color(0xFFF59E0B) : AppColors.primaryCyan,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    if (asgn.facultyInitial != null) ...[
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '→ ${asgn.facultyInitial}',
                                                        style: GoogleFonts.sora(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.w700),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                        if (item.adminNotes != null && item.adminNotes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Note: ${item.adminNotes}',
                                            style: GoogleFonts.sora(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
