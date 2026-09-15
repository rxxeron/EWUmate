import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/grade_helper.dart';
import '../../../../core/models/grade_scale.dart';
import '../../../semester_progress/semester_summary_providers.dart';

class CourseHistoryGradeDialog {
  static Future<String?> show({
    required BuildContext context,
    required WidgetRef ref,
    required String courseCode,
    required String currentSemester,
  }) {
    final policy = GradeHelper.getPolicyForSemester(currentSemester);
    final scaleAsync = ref.read(gradeScaleListProvider);
    final scale = scaleAsync.valueOrNull ?? [];

    List<String> grades = scale
        .where((s) => s.policy == policy)
        .map((s) => s.grade)
        .toSet()
        .toList();

    if (grades.isEmpty) {
      grades = (policy == 'legacy')
          ? ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "D", "F"]
          : ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"];
    }

    if (scale.isNotEmpty) {
      grades.sort((a, b) {
        final pa = scale
            .firstWhere(
              (s) => s.grade == a && s.policy == policy,
              orElse: () => GradeScale(grade: a, point: 0, policy: policy),
            )
            .point;
        final pb = scale
            .firstWhere(
              (s) => s.grade == b && s.policy == policy,
              orElse: () => GradeScale(grade: b, point: 0, policy: policy),
            )
            .point;
        return pb.compareTo(pa);
      });
    }

    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          "Grade for $courseCode",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: grades
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, g),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      g,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
