import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/course_metadata.dart';
import '../../../../../core/models/course_section.dart';
import '../../../../../core/repositories/course_repository.dart';
import 'capacity_indicator.dart';

class NextSemCourseCard extends ConsumerWidget {
  final CourseMetadata course;
  final String nextSemCode;
  final bool isAnySelected;
  final bool isSelectedTab;
  final Set<String> selectedSectionIds;
  final VoidCallback? onDeleteCourse;
  final void Function(CourseMetadata course, CourseSection section) onToggleSection;

  const NextSemCourseCard({
    super.key,
    required this.course,
    required this.nextSemCode,
    required this.isAnySelected,
    required this.isSelectedTab,
    required this.selectedSectionIds,
    this.onDeleteCourse,
    required this.onToggleSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnySelected
              ? Colors.cyan.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              course.name,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelectedTab && onDeleteCourse != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: onDeleteCourse,
              ),
            Icon(
              isAnySelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isAnySelected ? Colors.cyan : Colors.white24,
            ),
          ],
        ),
        children: [
          const Divider(
            height: 1,
            color: Colors.white10,
          ),
          Consumer(
            builder: (context, ref, child) {
              final sectionsAsync = ref.watch(
                courseSectionsProvider(
                  semesterCode: nextSemCode,
                  courseCode: course.code,
                ),
              );
              return sectionsAsync.when(
                loading: () => const LinearProgressIndicator(color: Colors.cyan),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Failed to load sections', style: TextStyle(color: Colors.redAccent)),
                ),
                data: (sections) => Column(
                  children: sections.map((sec) {
                    final isThisSelected = selectedSectionIds.contains(sec.id);
                    final faculty = sec.sessions.isNotEmpty &&
                            sec.sessions.first.faculty.isNotEmpty
                        ? sec.sessions.first.faculty
                        : null;

                    return ListTile(
                      title: Row(
                        children: [
                          Text(
                            'Section ${sec.section}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CapacityIndicator(capacity: sec.capacity),
                          if (faculty != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '• $faculty',
                                style: TextStyle(
                                  color: Colors.cyan.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        sec.sessions
                            .map((s) => '${s.day} ${s.startTime}-${s.endTime}')
                            .join(' | '),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      trailing: Switch(
                        value: isThisSelected,
                        activeThumbColor: Colors.cyan,
                        onChanged: (_) => onToggleSection(course, sec),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
