import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/task.dart';
import '../../../../core/providers/academic_providers.dart';
import '../../../../core/repositories/task_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../course_browser/presentation/providers/course_browser_providers.dart';

class AddTaskBottomSheet extends ConsumerStatefulWidget {
  final Task? existingTask;

  const AddTaskBottomSheet({super.key, this.existingTask});

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _supabase = Supabase.instance.client;
  User? get user => _supabase.auth.currentUser;

  String? selectedCourse;
  DateTime? assignedDate;
  DateTime? endDate;
  TimeOfDay? dueTime;
  String? selectedType;
  final TextEditingController _titleController = TextEditingController();

  List<String> enrolledCourses = [];
  bool _isLoadingCourses = true;
  bool _isSaving = false;

  final List<String> taskTypes = [
    'Mid Exam',
    'Final Exam',
    'Quiz',
    'Short Quiz',
    'Term Paper',
    'Assignment',
    'Project',
    'Lab Report',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _fetchEnrolledCourses();

    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      selectedCourse = t.courseCode;
      selectedType = t.type;
      assignedDate = t.assignDate?.toLocal();
      if (t.dueDate != null) {
        final localDue = t.dueDate!.toLocal();
        endDate = DateTime(localDue.year, localDue.month, localDue.day);
        dueTime = TimeOfDay(hour: localDue.hour, minute: localDue.minute);
      }
    } else {
      assignedDate = DateTime.now();
    }
  }

  Future<void> _fetchEnrolledCourses() async {
    try {
      final codes = await ref.read(userEnrollmentsProvider.future);

      if (mounted) {
        setState(() {
          enrolledCourses = List<String>.from(codes);

          if (widget.existingTask != null &&
              selectedCourse != null &&
              !enrolledCourses.contains(selectedCourse) &&
              selectedCourse != 'Other') {
            enrolledCourses.add(selectedCourse!);
          }

          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching courses: $e");
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isAssigned) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isAssigned ? assignedDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.primaryNavy,
              surface: Color(0xFF0D2342),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF09182D)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isAssigned) {
          assignedDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.primaryNavy,
              surface: Color(0xFF0D2342),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF09182D)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dueTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _saveTask() async {
    if (user == null) return;

    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a Task Type', style: GoogleFonts.sora()),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalTitle = _titleController.text.trim();
      if (finalTitle.isEmpty) {
        final typeStr = selectedType ?? "Task";
        final courseStr = selectedCourse ?? "General";
        finalTitle = "$typeStr - $courseStr";
      }

      DateTime? finalDueDate;
      if (endDate != null) {
        if (dueTime != null) {
          finalDueDate = DateTime(
            endDate!.year,
            endDate!.month,
            endDate!.day,
            dueTime!.hour,
            dueTime!.minute,
          );
        } else {
          finalDueDate = endDate;
        }
      }

      final taskRepo = ref.read(taskRepositoryProvider);

      if (widget.existingTask != null) {
        final updatedTask = widget.existingTask!.copyWith(
          title: finalTitle,
          courseCode: selectedCourse,
          type: selectedType,
          assignDate: assignedDate?.toUtc(),
          dueDate: finalDueDate?.toUtc(),
          semesterCode: ref.read(currentSemesterCodeProvider).value ?? 'Spring2026',
        );
        await taskRepo.updateTask(user!.id, updatedTask);
        ref.invalidate(allTasksStreamProvider);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task successfully updated', style: GoogleFonts.sora()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        final newTask = Task(
          id: const Uuid().v4(),
          userId: user!.id,
          title: finalTitle,
          courseCode: selectedCourse,
          type: selectedType,
          assignDate: assignedDate?.toUtc(),
          dueDate: finalDueDate?.toUtc(),
          semesterCode: ref.read(currentSemesterCodeProvider).value ?? 'Spring2026',
          isCompleted: false,
          createdAt: DateTime.now().toUtc(),
        );

        await taskRepo.createTask(user!.id, newTask);
        ref.invalidate(allTasksStreamProvider);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task successfully added', style: GoogleFonts.sora()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error saving task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existingTask != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09182D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                isEdit ? "Edit Task" : "Add New Task",
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _isLoadingCourses
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.primaryCyan),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    dropdownColor: const Color(0xFF0D2342),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryCyan),
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Course',
                      labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceNavyBlue,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                      ),
                    ),
                    items: [
                      ...enrolledCourses.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.sora(color: Colors.white)),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'Other',
                        child: Text('Other / No Course', style: GoogleFonts.sora(color: AppColors.secondaryText)),
                      ),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        selectedCourse = newValue == 'Other' ? null : newValue;
                      });
                    },
                  ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedType,
              dropdownColor: const Color(0xFF0D2342),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryCyan),
              style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Task Type *',
                labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceNavyBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                ),
              ),
              items: taskTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.sora(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedType = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'Defaults to Type - Course Code',
                hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 13),
                labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceNavyBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Assigned Date',
                        labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceNavyBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryCyan),
                      ),
                      child: Text(
                        _formatDate(assignedDate),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date / Due',
                        labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceNavyBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primaryCyan),
                      ),
                      child: Text(
                        _formatDate(endDate),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Time',
                  labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceNavyBlue,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryCyan),
                ),
                child: Text(
                  dueTime != null ? dueTime!.format(context) : 'Select Time',
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSaving ? null : _saveTask,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2.5),
                      )
                    : Text(
                        isEdit ? 'UPDATE TASK' : 'ADD TASK',
                        style: GoogleFonts.sora(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
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
