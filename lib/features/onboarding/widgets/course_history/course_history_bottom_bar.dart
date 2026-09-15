import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_kit.dart';

class CourseHistoryBottomBar extends StatelessWidget {
  final bool isEditMode;
  final bool isCurrentSemester;
  final VoidCallback onAction;

  const CourseHistoryBottomBar({
    super.key,
    required this.isEditMode,
    required this.isCurrentSemester,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          width: double.infinity,
          onTap: onAction,
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              isEditMode
                  ? "SAVE CHANGES"
                  : (isCurrentSemester ? "FINISH" : "CONTINUE"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
