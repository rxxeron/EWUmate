import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/course_metadata.dart';
import '../../../../core/models/course_section.dart';
import '../../../../core/models/profile.dart';
import '../../../../core/utils/course_utils.dart';
import '../../../../core/repositories/course_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/repositories/progress_repository.dart';
import '../../../../features/semester_progress/semester_progress_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/course_browser_providers.dart';

class CourseCard extends ConsumerStatefulWidget {
  final CourseMetadata course;
  final bool isEnrolledView;
  final Profile? profile;

  const CourseCard({
    super.key,
    required this.course,
    this.isEnrolledView = false,
    this.profile,
  });

  @override
  ConsumerState<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends ConsumerState<CourseCard> {
  bool _isUpdating = false;

  Future<void> _handleEnrollmentAction({
    required String action, // 'enroll', 'drop', 'switch'
    required String sectionId,
      required String sectionNumber,
      String? oldSectionId,
      required String academicSemCode,
    }) async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(user.id);
      if (profile == null) return;

      setState(() => _isUpdating = true);

      try {
        if (action == 'enroll') {
          await profileRepo.enrollCourseSection(
            userId: user.id,
            courseCode: widget.course.code,
            semesterCode: academicSemCode,
            sectionId: sectionId,
            sectionNumber: sectionNumber,
            currentSections: profile.enrolledSections,
          );
        } else if (action == 'drop') {
          await profileRepo.dropCourseSection(
            userId: user.id,
            sectionId: sectionId,
            semesterCode: academicSemCode,
            currentSections: profile.enrolledSections,
          );
        } else if (action == 'switch' && oldSectionId != null) {
          await profileRepo.switchCourseSection(
            userId: user.id,
            courseCode: widget.course.code,
            semesterCode: academicSemCode,
            oldSectionId: oldSectionId,
            newSectionId: sectionId,
            newSectionNumber: sectionNumber,
            currentSections: profile.enrolledSections,
          );
        }

      if (mounted) {
        // Force refresh all enrollment and progress providers
        ref.invalidate(userEnrollmentsProvider);
        ref.invalidate(userEnrollmentDetailsProvider);
        ref.invalidate(currentSemesterMarksProvider);
        ref.invalidate(semesterProgressDataProvider(academicSemCode));
        
        String msg = '';
        if (action == 'enroll') msg = 'Enrolled in ${widget.course.code}';
        if (action == 'drop') msg = 'Dropped ${widget.course.code}';
        if (action == 'switch') msg = 'Switched to new section';
        
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: action == 'drop' ? Colors.redAccent : Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(selectedSemesterScopeProvider);
    final isUpcoming = scope == SemesterScope.upcoming;
    final enrollmentsAsync = ref.watch(userEnrollmentsProvider);
    final bool hasEnrolled = enrollmentsAsync.maybeWhen(
      data: (codes) => codes.any((c) => c.toUpperCase() == widget.course.code.toUpperCase()),
      orElse: () => false,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming && hasEnrolled 
              ? AppColors.primaryCyan.withValues(alpha: 0.4) 
              : Colors.white12, 
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: EdgeInsets.zero,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.course.code,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                if (hasEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUpcoming 
                          ? AppColors.primaryCyan.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: isUpcoming 
                          ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.6))
                          : null,
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming Planned' : 'Enrolled', 
                      style: TextStyle(
                        color: isUpcoming ? AppColors.primaryCyan : Colors.white, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.course.name,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        children: [
          const Divider(height: 1, color: Colors.white10),
          _buildSectionsList(context),
        ],
      ),
    );
  }

  Widget _buildSectionsList(BuildContext context) {
    final scope = ref.watch(selectedSemesterScopeProvider);
    final isUpcoming = scope == SemesterScope.upcoming;
    final targetSemCodeAsync = ref.watch(selectedBrowserSemesterCodeProvider);
    final targetSemCode = targetSemCodeAsync.valueOrNull ?? 'Spring2026';
    final sectionsAsync = ref.watch(courseSectionsProvider(semesterCode: targetSemCode, courseCode: widget.course.code));
    
    final enrollmentsDetailsAsync = ref.watch(userEnrollmentDetailsProvider);

    return enrollmentsDetailsAsync.when(
      data: (details) {
        // Find if this specific course is enrolled
        final targetEnrolled = details.cast<Map<String, dynamic>?>().firstWhere(
          (e) => e != null && CourseUtils.areEquivalent(e['course_code'], widget.course.code),
          orElse: () => null,
        );
        final bool enrolledInAny = targetEnrolled != null;

        return sectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No sections available.', style: TextStyle(color: Colors.grey))),
              );
            }

            return Column(
              children: sections.map((section) {
                // Logic: Is THIS specific section enrolled?
                final bool isThisEnrolled = (targetEnrolled != null) && 
                    (targetEnrolled['section_id'] == section.id || 
                     (targetEnrolled['section'] != null && targetEnrolled['section'].toString() == section.section) ||
                     (targetEnrolled['section_id'] == null && (section.section == '1' || section.id == sections.first.id)));

                final String? conflictCourse = (!isThisEnrolled && !enrolledInAny) 
                    ? _getConflictCourse(section, details) 
                    : null;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Section ${section.section}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 12),
                                  _buildCapacityIndicator(section.capacity),
                                ],
                              ),
                              if (conflictCourse != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Conflicts with $conflictCourse',
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isUpcoming
                              ? _buildUpcomingActionButton(
                                  context: context,
                                  isThisEnrolled: isThisEnrolled,
                                  hasAnyInThisCourse: enrolledInAny,
                                  section: section,
                                  targetSemCode: targetSemCode,
                                  conflictCourse: conflictCourse,
                                )
                              : _buildActionButton(
                                  isThisEnrolled: isThisEnrolled,
                                  hasAnyInThisCourse: enrolledInAny,
                                  enrolledSectionId: targetEnrolled?['section_id'] ?? section.id,
                                  thisSectionId: section.id,
                                  thisSectionNumber: section.section,
                                  academicSemCode: targetSemCode,
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...section.sessions.map((session) {
                        final bool isLabFallback = CourseUtils.isLab(session.startTime, session.endTime, widget.course.code);
                        final displayType = session.type.isNotEmpty ? session.type : (isLabFallback ? 'Lab' : 'Theory');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                              '${session.day} ${session.startTime}-${session.endTime} (${session.faculty}) • $displayType',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.3),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildUpcomingActionButton({
    required BuildContext context,
    required bool isThisEnrolled,
    required bool hasAnyInThisCourse,
    required CourseSection section,
    required String targetSemCode,
    required String? conflictCourse,
  }) {
    String label = 'Select';
    Color btnColor = AppColors.primaryCyan;
    Color textColor = const Color(0xFF04101E);

    if (isThisEnrolled) {
      label = 'Enrolled';
      btnColor = Colors.teal;
      textColor = Colors.white;
    } else if (hasAnyInThisCourse) {
      label = 'Switch';
      btnColor = Colors.orangeAccent;
      textColor = Colors.white;
    }

    return ElevatedButton(
      onPressed: () => _showUpcomingCourseDetailsDialog(
        context: context,
        section: section,
        targetSemCode: targetSemCode,
        isThisEnrolled: isThisEnrolled,
        hasAnyInThisCourse: hasAnyInThisCourse,
        conflictCourse: conflictCourse,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(76, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showUpcomingCourseDetailsDialog({
    required BuildContext context,
    required CourseSection section,
    required String targetSemCode,
    required bool isThisEnrolled,
    required bool hasAnyInThisCourse,
    required String? conflictCourse,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool isSavingDialog = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0C192E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle pill
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
                    const SizedBox(height: 16),

                    // Semester Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_added_rounded, size: 14, color: AppColors.primaryCyan),
                              const SizedBox(width: 6),
                              Text(
                                'Upcoming: ${CourseUtils.cleanSemester(targetSemCode)}',
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryCyan,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.course.creditVal} Credits',
                            style: GoogleFonts.sora(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Course Code & Name
                    Text(
                      widget.course.code,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.course.name,
                      style: GoogleFonts.sora(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section & Capacity Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.class_outlined, size: 16, color: Colors.tealAccent),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Section ${section.section}',
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              _buildCapacityIndicator(section.capacity),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.white10),
                          // Sessions
                          ...section.sessions.map((session) {
                            final bool isLab = CourseUtils.isLab(session.startTime, session.endTime, widget.course.code);
                            final displayType = session.type.isNotEmpty ? session.type : (isLab ? 'Lab' : 'Theory');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primaryCyan),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.sora(fontSize: 13, color: Colors.white70),
                                        children: [
                                          TextSpan(
                                            text: '${session.day} ',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          TextSpan(text: '${session.startTime} - ${session.endTime} '),
                                          TextSpan(
                                            text: '(${session.faculty.isNotEmpty ? session.faculty : "TBA"}) • $displayType',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Conflict warning if any
                    if (conflictCourse != null && !isThisEnrolled) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Schedule clash with $conflictCourse in upcoming semester.',
                                style: GoogleFonts.sora(
                                  color: Colors.amberAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Buttons
                    if (isThisEnrolled) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSavingDialog
                                  ? null
                                  : () async {
                                      setDialogState(() => isSavingDialog = true);
                                      await _handleUpcomingEnrollment(
                                        action: 'drop',
                                        section: section,
                                        targetSemCode: targetSemCode,
                                        dialogContext: dialogContext,
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFF5252)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: isSavingDialog
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252)))
                                  : Text(
                                      'Remove from Upcoming',
                                      style: GoogleFonts.sora(color: const Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceNavyBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.sora(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.sora(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSavingDialog
                                    ? null
                                    : () async {
                                        setDialogState(() => isSavingDialog = true);
                                        await _handleUpcomingEnrollment(
                                          action: hasAnyInThisCourse ? 'switch' : 'enroll',
                                          section: section,
                                          targetSemCode: targetSemCode,
                                          dialogContext: dialogContext,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: isSavingDialog
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF04101E)))
                                    : Text(
                                        hasAnyInThisCourse ? 'Switch & Save' : 'Confirm & Save',
                                        style: GoogleFonts.sora(
                                          color: const Color(0xFF04101E),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleUpcomingEnrollment({
    required String action, // 'enroll', 'switch', 'drop'
    required CourseSection section,
    required String targetSemCode,
    required BuildContext dialogContext,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) Navigator.of(dialogContext).pop();
      return;
    }

    final supabase = ref.read(supabaseClientProvider);

    try {
      if (action == 'drop') {
        await supabase
            .from('enrollments')
            .delete()
            .eq('user_id', user.id)
            .eq('semester_code', targetSemCode)
            .eq('course_code', widget.course.code)
            .eq('status', 'upcoming');

        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
        ref.invalidate(userEnrollmentsProvider);
        ref.invalidate(userEnrollmentDetailsProvider);
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${widget.course.code} from Upcoming Enrollments.'),
              backgroundColor: const Color(0xFFFF5252),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // First delete any existing upcoming enrollment for this course code
        await supabase
            .from('enrollments')
            .delete()
            .eq('user_id', user.id)
            .eq('semester_code', targetSemCode)
            .eq('course_code', widget.course.code)
            .eq('status', 'upcoming');

        // Insert new upcoming enrollment
        await supabase.from('enrollments').insert({
          'user_id': user.id,
          'course_code': widget.course.code,
          'semester_code': targetSemCode,
          'section': section.section,
          'section_id': section.id,
          'status': 'upcoming',
        });

        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
        ref.invalidate(userEnrollmentsProvider);
        ref.invalidate(userEnrollmentDetailsProvider);
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved ${widget.course.code} (Sec ${section.section}) to Upcoming Enrollments!'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update upcoming enrollment: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required bool isThisEnrolled,
    required bool hasAnyInThisCourse,
    required String? enrolledSectionId,
    required String thisSectionId,
    required String thisSectionNumber,
    required String academicSemCode,
  }) {
    String label = 'Enroll';
    Color btnColor = Colors.teal;
    String action = 'enroll';

    if (isThisEnrolled) {
      label = 'Drop';
      btnColor = const Color(0xFFFF5252);
      action = 'drop';
    } else if (hasAnyInThisCourse) {
      label = 'Switch';
      btnColor = Colors.orangeAccent;
      action = 'switch';
    }

    return ElevatedButton(
      onPressed: _isUpdating ? null : () => _handleEnrollmentAction(
        action: action,
        sectionId: thisSectionId,
        sectionNumber: thisSectionNumber,
        oldSectionId: enrolledSectionId,
        academicSemCode: academicSemCode,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minimumSize: const Size(80, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: _isUpdating 
        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  String? _getConflictCourse(CourseSection section, List<dynamic> enrolledDetails) {
    for (final enrolled in enrolledDetails) {
      if (enrolled == null) continue;
      final enrolledCode = enrolled['course_code'] ?? '';
      if (CourseUtils.areEquivalent(enrolledCode, widget.course.code)) continue;

      final enrolledTime = enrolled['time']?.toString() ?? '';
      if (enrolledTime.isEmpty || enrolledTime == 'TBA') continue;

      for (final session in section.sessions) {
        final sessionTime = '${session.day} ${session.startTime}-${session.endTime}';
        final conflict = CourseUtils.hasTimeConflict([{'time': enrolledTime}], {'time': sessionTime});
        if (conflict != null) {
          return enrolledCode;
        }
      }
    }
    return null;
  }

  Widget _buildCapacityIndicator(String capacity) {
    if (capacity.isEmpty || !capacity.contains('/')) {
      return const SizedBox.shrink();
    }

    try {
      final parts = capacity.split('/');
      final enrolled = int.parse(parts[0].trim());
      final total = int.parse(parts[1].trim());
      final bool isFull = (total > 0 && enrolled >= total) || (total == 0 && enrolled > 0);
      final int available = total - enrolled;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (isFull ? Colors.redAccent : Colors.tealAccent).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: (isFull ? Colors.redAccent : Colors.tealAccent).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isFull ? 'Section Full' : '$available Seats Left',
          style: TextStyle(
            color: isFull ? Colors.redAccent : Colors.tealAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } catch (e) {
      return Text(
        capacity,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
    }
  }
}
