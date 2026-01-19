import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import 'task_repository.dart';
import '../../core/widgets/glass_kit.dart';

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
      // Default course selection if available
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

    // Find course object that matches courseCode
    try {
      _selectedCourse = widget.availableCourses.firstWhere(
        (c) => c.code == task.courseCode,
      );
    } catch (e) {
      // Course might not be in the list anymore, try to handle gracefully
      // For now, we leave it null or keep the old code/name if we had a text input
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
    final picked =
        await showTimePicker(context: context, initialTime: _dueTime);
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _submit() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a course")));
      return;
    }

    setState(() => _saving = true);

    // Construct final due date
    final finalDue = DateTime(_dueDate.year, _dueDate.month, _dueDate.day,
        _dueTime.hour, _dueTime.minute);

    // Auto-generate title if empty based on type
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      title =
          "${_taskType.name[0].toUpperCase()}${_taskType.name.substring(1)}";
    }

    // Create Updated/New Task
    final task = Task(
      id: widget.taskToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      courseCode: _selectedCourse!.code,
      courseName: _selectedCourse!.courseName,
      assignDate: _assignDate,
      dueDate: finalDue,
      submissionType: _submissionType,
      type: _taskType,
      isCompleted: _isCompleted,
    );

    try {
      if (widget.taskToEdit != null) {
        await _taskRepo.updateTask(task);
      } else {
        await _taskRepo.addTask(task);
      }

      widget.onTaskSaved(task);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving task: $e")));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent)),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: Colors.cyanAccent,
    );

    return GlassContainer(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      borderRadius: 20,
      opacity: 0.1,
      blur: 20,
      borderColor: Colors.white.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEditing ? "Edit Task" : "Add New Task",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            DropdownButtonFormField<Course>(
              decoration: inputDecoration.copyWith(
                  labelText: "Select Course",
                  prefixIcon: const Icon(Icons.book)),
              dropdownColor: const Color(0xFF1e1e1e),
              style: const TextStyle(color: Colors.white),
              initialValue: _selectedCourse,
              items: widget.availableCourses
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.code, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCourse = val),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                          labelText: "Assigned Date",
                          prefixIcon: const Icon(Icons.calendar_today)),
                      child: Text(DateFormat('MMM d, y').format(_assignDate),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                          labelText: "Due Date",
                          prefixIcon: const Icon(Icons.event_busy)),
                      child: Text(DateFormat('MMM d, y').format(_dueDate),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: inputDecoration.copyWith(
                    labelText: "Due Time",
                    prefixIcon: const Icon(Icons.access_time)),
                child: Text(_dueTime.format(context),
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SubmissionType>(
                    decoration:
                        inputDecoration.copyWith(labelText: "Submission"),
                    dropdownColor: const Color(0xFF1e1e1e),
                    style: const TextStyle(color: Colors.white),
                    initialValue: _submissionType,
                    items: SubmissionType.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _submissionType = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<TaskType>(
                    decoration: inputDecoration.copyWith(labelText: "Type"),
                    dropdownColor: const Color(0xFF1e1e1e),
                    style: const TextStyle(color: Colors.white),
                    initialValue: _taskType,
                    items: TaskType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _taskType = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration.copyWith(
                labelText: "Title (Optional)",
                hintText: "e.g. Chapter 1 Quiz",
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            if (isEditing) ...[
              SwitchListTile(
                title: const Text("Mark as Completed",
                    style: TextStyle(color: Colors.white)),
                value: _isCompleted,
                activeTrackColor: Colors.cyanAccent,
                activeThumbColor: Colors.white, // Thumb color when active
                onChanged: (val) {
                  setState(() => _isCompleted = val);
                },
              ),
              const SizedBox(height: 15),
            ],
            GlassContainer(
              borderRadius: 12,
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              borderColor: Colors.cyanAccent,
              child: InkWell(
                onTap: _saving ? null : _submit,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? "Save Changes" : "Create Task",
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
