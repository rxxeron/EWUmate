import 'package:flutter/material.dart';
import 'reminder_duration_picker_dialog.dart';

class ReminderSchedulePreviewSheet {
  static void show({
    required BuildContext context,
    required String selectedCourse,
    required List<int> currentOffsets,
    required VoidCallback onConfirmSave,
  }) {
    const exampleHour = 8;
    const exampleMin = 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: Colors.cyanAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confirm $selectedCourse Schedule',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Here is the exact notification timeline that will be scheduled for every $selectedCourse class:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Simulation Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulation Example:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Class at 08:30 AM', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    ...currentOffsets.map((offset) {
                      final totalClassMins = exampleHour * 60 + exampleMin;
                      var triggerMins = totalClassMins - offset;
                      if (triggerMins < 0) triggerMins += 24 * 60;
                      final th = triggerMins ~/ 60;
                      final tm = triggerMins % 60;
                      final ampm = th >= 12 ? 'PM' : 'AM';
                      final h12 = th % 12 == 0 ? 12 : th % 12;
                      final triggerTimeStr = '${h12.toString().padLeft(2, '0')}:${tm.toString().padLeft(2, '0')} $ampm';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: Colors.cyanAccent, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              triggerTimeStr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: (offset == 30 || offset == 15)
                                    ? Colors.white10
                                    : Colors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${ReminderDurationPickerDialog.formatDuration(offset)} before',
                                style: TextStyle(
                                  color: (offset == 30 || offset == 15) ? Colors.white70 : Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirmSave();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Confirm & Save Schedule',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
