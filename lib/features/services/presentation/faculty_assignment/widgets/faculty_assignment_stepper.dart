import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class FacultyAssignmentStepper extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  const FacultyAssignmentStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'num': 1, 'label': 'Assign Courses'},
      {'num': 2, 'label': 'Upload Proof'},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = currentStep > stepBefore;

          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isCompleted
                  ? AppColors.primaryCyan
                  : Colors.white.withValues(alpha: 0.12),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isDone = currentStep > stepIndex;
        final isActive = currentStep == stepIndex;
        final stepData = steps[stepIndex];

        return InkWell(
          onTap: () {
            if (stepIndex < currentStep) {
              onStepTapped(stepIndex);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primaryCyan
                      : isActive
                          ? AppColors.primaryCyan.withValues(alpha: 0.20)
                          : const Color(0xFF0D2342),
                  border: Border.all(
                    color: (isDone || isActive)
                        ? AppColors.primaryCyan
                        : Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryNavy)
                      : Text(
                          '${stepData['num']}',
                          style: GoogleFonts.sora(
                            color: isActive ? AppColors.primaryCyan : Colors.white38,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stepData['label'] as String,
                style: GoogleFonts.sora(
                  color: isActive
                      ? AppColors.primaryCyan
                      : isDone
                          ? Colors.white70
                          : Colors.white38,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
