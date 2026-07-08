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
import '../../../../core/providers/academic_providers.dart';
import '../../../../core/repositories/progress_repository.dart';
import '../../../../features/semester_progress/semester_progress_repository.dart';
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
    final enrollmentsAsync = ref.watch(userEnrollmentsProvider);
    final bool hasEnrolled = enrollmentsAsync.maybeWhen(
      data: (codes) => codes.any((c) => c.toUpperCase() == widget.course.code.toUpperCase()),
      orElse: () => false,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
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
                Expanded(
                  child: Text(
                    widget.course.code,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasEnrolled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Enrolled', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
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
    final academicState = ref.watch(academicStateProvider).value;
    final activeSemCode = academicState?.currentSemesterCode ?? 'Spring2026';
    final sectionsAsync = ref.watch(courseSectionsProvider(semesterCode: activeSemCode, courseCode: widget.course.code));
    
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
                // 1. By exact ID match
                // 2. OR if enrollment has null section_id, we treat the first section as the 'enrolled' one for UI purposes 
                //    so they can at least drop/switch it.
                final bool isThisEnrolled = (targetEnrolled != null) && 
                    (targetEnrolled['section_id'] == section.id || 
                     (targetEnrolled['section_id'] == null && (section.section == '1' || section.id == sections.first.id)));

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Section ${section.section}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 12),
                                    _buildCapacityIndicator(section.capacity),
                                  ],
                                ),
                                if (!isThisEnrolled && !enrolledInAny) _buildConflictWarning(section, details),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            isThisEnrolled: isThisEnrolled,
                            hasAnyInThisCourse: enrolledInAny,
                            enrolledSectionId: targetEnrolled?['section_id'] ?? section.id,
                            thisSectionId: section.id,
                            thisSectionNumber: section.section,
                            academicSemCode: activeSemCode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...section.sessions.map((session) {
                        final bool isLabFallback = CourseUtils.isLab(session.startTime, session.endTime, widget.course.code);
                        final displayType = session.type ?? (isLabFallback ? 'Lab' : 'Theory');
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

  Widget _buildConflictWarning(CourseSection section, List<dynamic> enrolledDetails) {
    String? conflictCourse;
    
    for (final enrolled in enrolledDetails) {
      if (enrolled == null) continue;
      final enrolledCode = enrolled['course_code'] ?? '';
      if (CourseUtils.areEquivalent(enrolledCode, widget.course.code)) continue;

      final enrolledTime = enrolled['time']?.toString() ?? '';
      if (enrolledTime.isEmpty || enrolledTime == 'TBA') continue;

      // Check each session of the current section against the enrolled time string
      for (final session in section.sessions) {
        final sessionTime = '${session.day} ${session.startTime}-${session.endTime}';
        final conflict = CourseUtils.hasTimeConflict([{'time': enrolledTime}], {'time': sessionTime});
        if (conflict != null) {
          conflictCourse = enrolledCode;
          break;
        }
      }
      if (conflictCourse != null) break;
    }

    if (conflictCourse == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Conflicts with $conflictCourse',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
          color: (isFull ? Colors.redAccent : Colors.tealAccent).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: (isFull ? Colors.redAccent : Colors.tealAccent).withOpacity(0.3),
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
