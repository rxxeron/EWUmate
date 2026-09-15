import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/repositories/office_hours_repository.dart';
import '../../../../core/providers/academic_providers.dart';

class SubmitOfficeHoursSheet extends ConsumerStatefulWidget {
  final String facultyInitials;

  const SubmitOfficeHoursSheet({
    super.key,
    required this.facultyInitials,
  });

  @override
  ConsumerState<SubmitOfficeHoursSheet> createState() => _SubmitOfficeHoursSheetState();
}

class _SubmitOfficeHoursSheetState extends ConsumerState<SubmitOfficeHoursSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // List of dynamic slots
  final List<Map<String, dynamic>> _slots = [];
  final _roomController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  final List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    // Start with one default slot
    _slots.add({
      'day': 'Sunday',
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 10, minute: 30),
    });
  }

  void _addSlot() {
    setState(() {
      _slots.add({
        'day': 'Sunday',
        'startTime': const TimeOfDay(hour: 9, minute: 0),
        'endTime': const TimeOfDay(hour: 10, minute: 30),
      });
    });
  }

  void _removeSlot(int index) {
    if (_slots.length > 1) {
      setState(() {
        _slots.removeAt(index);
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _selectStartTime(BuildContext context, int index) async {
    final initialTime = _slots[index]['startTime'] as TimeOfDay? ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _slots[index]['startTime'] = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context, int index) async {
    final initialTime = _slots[index]['endTime'] as TimeOfDay? ?? const TimeOfDay(hour: 10, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _slots[index]['endTime'] = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _submit() async {
    // 1. Verify all slots have valid times
    for (int i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      final startTime = slot['startTime'] as TimeOfDay?;
      final endTime = slot['endTime'] as TimeOfDay?;
      final day = slot['day'] as String;

      if (startTime == null || endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select times for Slot #${i + 1} ($day)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Verify start is before end
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      if (startMinutes >= endMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Start time must be before end time in Slot #${i + 1} ($day)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // 2. Verify proof file is selected
    if (_selectedFile == null || _selectedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a proof document (PDF or Image)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(officeHoursRepositoryProvider);
      
      // Format each slot
      final formattedSlots = _slots.map((s) {
        final start = s['startTime'] as TimeOfDay;
        final end = s['endTime'] as TimeOfDay;
        return {
          'day': s['day'] as String,
          'startTime': _formatTimeOfDay(start),
          'endTime': _formatTimeOfDay(end),
        };
      }).toList();

      final activeSemester = ref.read(academicStateProvider).value;
      final semesterCode = activeSemester?.currentSemesterCode ?? 'Summer 2026';

      await repo.submitOfficeHours(
        file: File(_selectedFile!.path!),
        fileName: _selectedFile!.name,
        facultyInitials: widget.facultyInitials,
        slots: formattedSlots,
        semesterCode: semesterCode,
        officeRoom: _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully submitted office hours for verification!'),
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submit Office Hours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FACULTY: ${widget.facultyInitials}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SLOTS LIST
              ...List.generate(
                _slots.length,
                (index) {
                  final slot = _slots[index];
                  final day = slot['day'] as String;
                  final startTime = slot['startTime'] as TimeOfDay?;
                  final endTime = slot['endTime'] as TimeOfDay?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slot Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SLOT #${index + 1}',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (_slots.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeSlot(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Day Dropdown
                        const Text(
                          'DAY',
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: day,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              items: _daysOfWeek.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _slots[index]['day'] = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Time Pickers Row
                        const Text(
                          'TIME RANGE',
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectStartTime(context, index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        startTime != null ? _formatTimeOfDay(startTime) : 'Start Time',
                                        style: TextStyle(
                                          color: startTime != null ? Colors.white : Colors.white30,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_rounded, color: Colors.white38, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('to', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectEndTime(context, index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        endTime != null ? _formatTimeOfDay(endTime) : 'End Time',
                                        style: TextStyle(
                                          color: endTime != null ? Colors.white : Colors.white30,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_rounded, color: Colors.white38, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ADD SLOT BUTTON
              OutlinedButton.icon(
                onPressed: _addSlot,
                icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent, size: 18),
                label: const Text(
                  'Add Another Time Slot',
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // OFFICE ROOM SECTION
              const Text(
                'OFFICE ROOM',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter the office room number where this faculty member sits.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomController,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g., SAC 402, Annex 501',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // UPLOAD PROOF SECTION
              const Text(
                'VERIFICATION PROOF',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Provide one notice, flyer, outline, or syllabus image/PDF confirming these hours.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 12),

              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedFile!.name.split('.').last.toLowerCase() == 'pdf'
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               _selectedFile!.name,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 13,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 2),
                             Text(
                               '${((_selectedFile!.size) / 1024 / 1024).toStringAsFixed(2)} MB',
                               style: const TextStyle(color: Colors.white38, fontSize: 10),
                             ),
                           ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Colors.cyanAccent, size: 24),
                        const SizedBox(height: 8),
                        const Text(
                          'Attach Image or PDF proof',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Max 10MB (PDF, JPG, PNG)',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 36),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit Verification Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
