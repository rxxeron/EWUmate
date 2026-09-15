import 'package:flutter/material.dart';

class NextSemConfirmationFooter extends StatelessWidget {
  final int selectedCoursesCount;
  final bool isManualMode;
  final bool isSaving;
  final VoidCallback onClearAll;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  const NextSemConfirmationFooter({
    super.key,
    required this.selectedCoursesCount,
    required this.isManualMode,
    required this.isSaving,
    required this.onClearAll,
    required this.onSave,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  selectedCoursesCount == 0
                      ? 'No Courses Selected'
                      : '$selectedCoursesCount Courses Selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (selectedCoursesCount > 0)
                  TextButton(
                    onPressed: onClearAll,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            if (isManualMode || selectedCoursesCount > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSaving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                        )
                      : Text(
                          selectedCoursesCount == 0
                              ? 'Clear & Save Empty Strategy'
                              : 'Confirm & Save Strategy',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            if (selectedCoursesCount > 0) const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Skip / Do it Later',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
