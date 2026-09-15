import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_kit.dart';
import '../../../../core/utils/course_utils.dart';

class CourseHistoryHeaderCard extends StatelessWidget {
  final bool isCurrentSemester;
  final String? currentSemester;
  final Map<String, String> currentMap;
  final void Function(String key, String code) onTapGrade;
  final void Function(String key) onRemoveCourse;

  const CourseHistoryHeaderCard({
    super.key,
    required this.isCurrentSemester,
    required this.currentSemester,
    required this.currentMap,
    required this.onTapGrade,
    required this.onRemoveCourse,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      color: isCurrentSemester
          ? Colors.greenAccent.withValues(alpha: 0.1)
          : Colors.blueAccent.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCurrentSemester ? "Current Enrollment" : "Academic History",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          if (currentMap.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No courses selected for ${CourseUtils.prettifySemesterCode((currentSemester == null || currentSemester!.isEmpty) ? "this semester" : currentSemester!)}",
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentMap.entries
                  .map(
                    (e) => InputChip(
                      backgroundColor: Colors.white10,
                      label: Text(
                        "${e.key} (${e.value})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: isCurrentSemester
                          ? null
                          : () {
                              final String code = e.key.contains('_Sec')
                                  ? e.key.split('_Sec').first
                                  : e.key;
                              onTapGrade(e.key, code);
                            },
                      onDeleted: () => onRemoveCourse(e.key),
                      deleteIconColor: Colors.white54,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
