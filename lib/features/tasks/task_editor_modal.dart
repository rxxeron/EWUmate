import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import 'task_repository.dart';
import '../../core/widgets/glass_kit.dart';
import 'package:uuid/uuid.dart';

class TaskEditorModal extends StatefulWidget {
  final List<Course> availableCourses;
  final Function(Task) onTaskSaved;
  final Task? taskToEdit; // If null, create new task

  const TaskEditorModal({
    super.key,
    required this.availableCourses,
    required this.onTaskSaved,
    this.taskToEdit,
  });

  @override
  State<TaskEditorModal> createState() => _TaskEditorModalState();
}

class _TaskEditorModalState extends State<TaskEditorModal> {
  final TaskRepository _taskRepo = TaskRepository();
  bool _saving = false;
  bool _isCompleted = false;
  bool _isMissed = false;

  Course? _selectedCourse;
  DateTime _assignDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);

  SubmissionType _submissionType = SubmissionType.offline;
  TaskType _taskType = TaskType.assignment;

  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _loadExistingTask(widget.taskToEdit!);
    } else {
      if (widget.availableCourses.isNotEmpty) {
        _selectedCourse = widget.availableCourses.first;
      }
    }
  }

  void _loadExistingTask(Task task) {
    _titleController.text = task.title;
    _assignDate = task.assignDate;
    _dueDate = task.dueDate;
    _dueTime = TimeOfDay.fromDateTime(task.dueDate);
    _submissionType = task.submissionType;
    _taskType = task.type;
    _isCompleted = task.isCompleted;
    _isMissed = task.isMissed;

    try {
      _selectedCourse = widget.availableCourses.firstWhere(
        (c) => c.code == task.courseCode,
      );
    } catch (e) {
      // Course mismatch or archived
    }
  }

  Future<void> _pickDate(bool isAssign) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isAssign ? _assignDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isAssign) {
          _assignDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _dueTime);
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _submit() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a course")));
      return;
    }

    setState(() => _saving = true);
    final finalDue = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, _dueTime.hour, _dueTime.minute);

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      title = "${_taskType.name[0].toUpperCase()}${_taskType.name.substring(1)}";
    }

    final task = Task(
      id: widget.taskToEdit?.id ?? const Uuid().v4(),
      title: title,
      courseCode: _selectedCourse!.code,
      courseName: _selectedCourse!.courseName,
      assignDate: _assignDate,
      dueDate: finalDue,
      submissionType: _submissionType,
      type: _taskType,
      isCompleted: _isCompleted,
      isMissed: _isMissed,
    );

    try {
      if (widget.taskToEdit != null) {
        await _taskRepo.updateTask(task);
      } else {
        await _taskRepo.addTask(task);
      }
      widget.onTaskSaved(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
      labelStyle: const TextStyle(color: Colors.white70),
    );

    return GlassContainer(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      borderRadius: 20,
      opacity: 0.1,
      borderColor: Colors.white.withValues(alpha: 0.2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.taskToEdit != null ? "Edit Task" : "New Task",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            DropdownButtonFormField<Course>(
              decoration: inputDecoration.copyWith(labelText: "Course", prefixIcon: const Icon(Icons.book, color: Colors.cyanAccent)),
              dropdownColor: const Color(0xFF1E1E2E),
              style: const TextStyle(color: Colors.white),
              initialValue: _selectedCourse,
              items: widget.availableCourses.map((c) => DropdownMenuItem(value: c, child: Text(c.code))).toList(),
              onChanged: (val) => setState(() => _selectedCourse = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(labelText: "Assigned", prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.cyanAccent)),
                      child: Text(DateFormat('MMM d').format(_assignDate), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(labelText: "Due Date", prefixIcon: const Icon(Icons.event_busy, size: 18, color: Colors.cyanAccent)),
                      child: Text(DateFormat('MMM d').format(_dueDate), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: inputDecoration.copyWith(labelText: "Due Time", prefixIcon: const Icon(Icons.access_time, color: Colors.cyanAccent)),
                child: Text(_dueTime.format(context), style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration.copyWith(labelText: "Description (e.g. Quiz 1)", prefixIcon: const Icon(Icons.edit, color: Colors.cyanAccent)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskType>(
                    decoration: inputDecoration.copyWith(labelText: "Type"),
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: const TextStyle(color: Colors.white),
                    initialValue: _taskType,
                    items: TaskType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _taskType = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SubmissionType>(
                    decoration: inputDecoration.copyWith(labelText: "Sub."),
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: const TextStyle(color: Colors.white),
                    initialValue: _submissionType,
                    items: SubmissionType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _submissionType = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.cyanAccent)),
                elevation: 0,
              ),
              child: _saving 
                ? const CircularProgressIndicator() 
                : Text(
                    widget.taskToEdit != null ? "Save Changes" : "Create Task", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
