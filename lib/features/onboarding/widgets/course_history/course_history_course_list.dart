import 'package:flutter/material.dart';
import '../../../../core/utils/course_utils.dart';

class CourseHistoryCourseList extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> catalog;
  final bool isCurrentSemester;
  final String? currentSemester;
  final Map<String, Map<String, String>> history;
  final String? Function(String courseCode) getPassedGrade;
  final void Function(Map<String, dynamic> course) onAddCourse;

  const CourseHistoryCourseList({
    super.key,
    required this.loading,
    required this.catalog,
    required this.isCurrentSemester,
    required this.currentSemester,
    required this.history,
    required this.getPassedGrade,
    required this.onAddCourse,
  });

  static String formatSchedule(dynamic scheduleData) {
    if (scheduleData == null || scheduleData is! List || scheduleData.isEmpty) {
      return 'TBA';
    }
    final formatted = scheduleData
        .map((s) {
          if (s is Map) {
            final day = s['day'] ?? '';
            final start = s['startTime'] ?? s['start_time'] ?? '';
            final end = s['endTime'] ?? s['end_time'] ?? '';
            final room = s['room'] ?? '';
            final type = s['type'] != null && s['type'] != 'Theory'
                ? '(${s['type']}) '
                : '';

            String sessionText = '$type$day $start-$end'.trim();
            if (room.isNotEmpty) sessionText += ' [$room]';
            return sessionText;
          }
          return '';
        })
        .where((e) => e.isNotEmpty)
        .join(', ');

    return formatted.isEmpty ? 'TBA' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }
    if (catalog.isEmpty) {
      return const Center(
        child: Text(
          "No courses found.",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final cleanCurrent = CourseUtils.cleanSemester(currentSemester ?? '');

    if (!isCurrentSemester) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: catalog.length,
        itemBuilder: (ctx, i) {
          final c = catalog[i];
          final code = c['code'] as String;
          final isSelected = (history[cleanCurrent] ?? {}).containsKey(code);
          final String? passedGrade = getPassedGrade(code);

          return Card(
            color: passedGrade != null
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              enabled: passedGrade == null,
              title: Text(
                code,
                style: TextStyle(
                  color: passedGrade != null
                      ? Colors.white38
                      : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  decoration: passedGrade != null
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: Colors.white38,
                ),
              ),
              subtitle: Text(
                c['name'] ?? '',
                style: TextStyle(
                  color: passedGrade != null ? Colors.white24 : Colors.white70,
                ),
              ),
              trailing: passedGrade != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Passed ($passedGrade)",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: isSelected ? Colors.greenAccent : Colors.white38,
                    ),
              onTap: passedGrade != null ? null : () => onAddCourse(c),
            ),
          );
        },
      );
    } else {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var c in catalog) {
        grouped.putIfAbsent(c['code'], () => []).add(c);
      }
      final sortedKeys = grouped.keys.toList()..sort();

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedKeys.length,
        itemBuilder: (ctx, i) {
          final code = sortedKeys[i];
          final sections = grouped[code]!;
          final name = sections.first['name'] ?? '';
          final String? passedGrade = getPassedGrade(code);

          int selectedCount = 0;
          if (passedGrade == null) {
            for (var c in sections) {
              final section = (c['section'] ?? '').toString();
              final selectionKey = "${code}_Sec$section";
              if ((history[cleanCurrent] ?? {}).containsKey(selectionKey)) {
                selectedCount++;
              }
            }
          }

          return Card(
            color: passedGrade != null
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: selectedCount > 0
                    ? Colors.cyanAccent.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                enabled: passedGrade == null,
                iconColor: passedGrade != null ? Colors.white38 : null,
                collapsedIconColor: passedGrade != null ? Colors.transparent : null,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  code,
                  style: TextStyle(
                    color: passedGrade != null
                        ? Colors.white38
                        : Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    decoration: passedGrade != null
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
                  ),
                ),
                subtitle: Text(
                  name,
                  style: TextStyle(
                    color: passedGrade != null
                        ? Colors.white24
                        : Colors.white70,
                  ),
                ),
                trailing: passedGrade != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Passed ($passedGrade)",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : selectedCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Enrolled",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white38,
                          ),
                children: passedGrade != null
                    ? []
                    : sections.map((c) {
                        final section = (c['section'] ?? '').toString();
                        final selectionKey = "${code}_Sec$section";
                        final isSelected = (history[cleanCurrent] ?? {})
                            .containsKey(selectionKey);

                        final faculty = c['faculty'] ?? 'TBA';
                        final schedule = formatSchedule(c['schedule']);

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            title: Text(
                              "Section $section",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Faculty: $faculty\nSchedule: $schedule",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected
                                  ? Colors.greenAccent
                                  : Colors.white38,
                            ),
                            onTap: () => onAddCourse(c),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        },
      );
    }
  }
}
