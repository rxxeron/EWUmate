import 'package:flutter/material.dart';

class ReminderDurationPickerDialog {
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'}';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours hr${hours == 1 ? '' : 's'}';
    }
    return '$hours hr${hours == 1 ? '' : 's'} $remainingMins min${remainingMins == 1 ? '' : 's'}';
  }

  static Future<int?> show({
    required BuildContext context,
    required int initialMinutes,
  }) {
    int selectedHours = initialMinutes ~/ 60;
    int selectedMins = initialMinutes % 60;

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalCalculated = selectedHours * 60 + selectedMins;
            final isTooLong = totalCalculated > 300;
            final isZero = totalCalculated == 0;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Text('Custom Reminder Time', style: TextStyle(color: Colors.white, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose how much time before class you want this alert:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text('Hours', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: selectedHours,
                            dropdownColor: const Color(0xFF282846),
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: List.generate(6, (h) => DropdownMenuItem(value: h, child: Text('$h h'))),
                            onChanged: (h) {
                              if (h != null) {
                                setDialogState(() {
                                  selectedHours = h;
                                  if (selectedHours == 5) selectedMins = 0;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          const Text('Minutes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: (selectedMins ~/ 5) * 5,
                            dropdownColor: const Color(0xFF282846),
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
                            underline: const SizedBox(),
                            items: List.generate(12, (m) {
                              final minVal = m * 5;
                              return DropdownMenuItem(value: minVal, child: Text('$minVal m'));
                            }),
                            onChanged: selectedHours == 5
                                ? null
                                : (m) {
                                    if (m != null) {
                                      setDialogState(() {
                                        selectedMins = m;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: ${formatDuration(totalCalculated)} before class',
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  if (isTooLong)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Maximum lead time is 5 hours.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  if (isZero)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Time must be greater than 0.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: (isTooLong || isZero)
                      ? null
                      : () => Navigator.pop(ctx, totalCalculated),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
