import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/providers/academic_providers.dart';


import '../../../../core/models/task.dart';
import '../../../../core/repositories/task_repository.dart';
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
    'Mid Exam', 'Final Exam', 'Quiz', 'Short Quiz', 'Term Paper',
    'Assignment', 'Project', 'Lab Report', 'Others'
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
          
          if (widget.existingTask != null && selectedCourse != null && !enrolledCourses.contains(selectedCourse) && selectedCourse != 'Other') {
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
        const SnackBar(content: Text('Please select a Task Type'), backgroundColor: Colors.red),
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
            const SnackBar(content: Text('Task successfully updated'), backgroundColor: Colors.green),
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
            const SnackBar(content: Text('Task successfully added'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error saving task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e)), backgroundColor: Colors.red),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E32),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? "Edit Task" : "Add New Task",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _isLoadingCourses 
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  initialValue: selectedCourse,
                  dropdownColor: const Color(0xFF1E1E32),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Course',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    ...enrolledCourses.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: 'Other',
                      child: Text('Other / No Course'),
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
              dropdownColor: const Color(0xFF1E1E32),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Task Type *',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: taskTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'Defaults to Type - Course Code',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Assigned Date',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        _formatDate(assignedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date / Due',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        _formatDate(endDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Time',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Text(
                  dueTime != null ? dueTime!.format(context) : 'Select Time',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: const Color(0xFF1E1E32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _saveTask,
                child: _isSaving 
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Update Task' : 'Add Task', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
