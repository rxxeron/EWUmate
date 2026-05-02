import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/semester_course_marks.dart';
import '../../../../core/repositories/progress_repository.dart';
import '../../../../core/utils/refresh_utils.dart';

class CourseMarksEditorScreen extends ConsumerStatefulWidget {
  final SemesterCourseMarks courseMarks;

  const CourseMarksEditorScreen({super.key, required this.courseMarks});

  @override
  ConsumerState<CourseMarksEditorScreen> createState() => _CourseMarksEditorScreenState();
}

class _CourseMarksEditorScreenState extends ConsumerState<CourseMarksEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SemesterCourseMarks _currentMarks;
  bool _isSaving = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentMarks = widget.courseMarks;
    _initControllers();
  }

  void _initControllers() {
    _controllers['distMid'] = TextEditingController(text: _currentMarks.distMid.toString());
    _controllers['distFinal'] = TextEditingController(text: _currentMarks.distFinal.toString());
    _controllers['distQuiz'] = TextEditingController(text: _currentMarks.distQuiz.toString());
    _controllers['distAssignment'] = TextEditingController(text: _currentMarks.distAssignment?.toString() ?? '');
    _controllers['distPresentation'] = TextEditingController(text: _currentMarks.distPresentation?.toString() ?? '');
    _controllers['distAttendance'] = TextEditingController(text: _currentMarks.distAttendance?.toString() ?? '');
    _controllers['distLab'] = TextEditingController(text: _currentMarks.distLab?.toString() ?? '');

    _controllers['obtMid'] = TextEditingController(text: _currentMarks.obtMid?.toString() ?? '');
    _controllers['obtFinal'] = TextEditingController(text: _currentMarks.obtFinal?.toString() ?? '');
    _controllers['obtAssignment'] = TextEditingController(text: _currentMarks.obtAssignment?.toString() ?? '');
    _controllers['obtPresentation'] = TextEditingController(text: _currentMarks.obtPresentation?.toString() ?? '');
    _controllers['obtAttendance'] = TextEditingController(text: _currentMarks.obtAttendance?.toString() ?? '');
    _controllers['obtLab'] = TextEditingController(text: _currentMarks.obtLab?.toString() ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMarks() async {
    setState(() => _isSaving = true);
    
    final updatedMarks = _currentMarks.copyWith(
      distMid: double.tryParse(_controllers['distMid']!.text) ?? 30.0,
      distFinal: double.tryParse(_controllers['distFinal']!.text) ?? 40.0,
      distQuiz: double.tryParse(_controllers['distQuiz']!.text) ?? 10.0,
      distAssignment: double.tryParse(_controllers['distAssignment']!.text),
      distPresentation: double.tryParse(_controllers['distPresentation']!.text),
      distAttendance: double.tryParse(_controllers['distAttendance']!.text),
      distLab: double.tryParse(_controllers['distLab']!.text),

      obtMid: double.tryParse(_controllers['obtMid']!.text),
      obtFinal: double.tryParse(_controllers['obtFinal']!.text),
      obtAssignment: double.tryParse(_controllers['obtAssignment']!.text),
      obtPresentation: double.tryParse(_controllers['obtPresentation']!.text),
      obtAttendance: double.tryParse(_controllers['obtAttendance']!.text),
      obtLab: double.tryParse(_controllers['obtLab']!.text),
    );

    try {
      await ref.read(progressRepositoryProvider).updateCourseMarks(updatedMarks);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      RefreshUtils.refreshAcademicData(ref);
      ref.invalidate(semesterProgressDataProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
    }
    
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  Widget _buildOutlineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Enter the total marks allocated for each category:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        _buildTextField('Midterm Target/Dist', _controllers['distMid']!),
        _buildTextField('Final Target/Dist', _controllers['distFinal']!),
        _buildTextField('Quizzes Target/Dist', _controllers['distQuiz']!),
        _buildTextField('Assignment Target/Dist', _controllers['distAssignment']!),
        _buildTextField('Presentation Target/Dist', _controllers['distPresentation']!),
        _buildTextField('Attendance Target/Dist', _controllers['distAttendance']!),
        _buildTextField('Lab Target/Dist', _controllers['distLab']!),
      ],
    );
  }

  Widget _buildObtainedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Enter the marks you have achieved so far:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        _buildTextField('Obtained Midterm', _controllers['obtMid']!),
        _buildTextField('Obtained Final', _controllers['obtFinal']!),
        _buildTextField('Obtained Assignment', _controllers['obtAssignment']!),
        _buildTextField('Obtained Presentation', _controllers['obtPresentation']!),
        _buildTextField('Obtained Attendance', _controllers['obtAttendance']!),
        _buildTextField('Obtained Lab', _controllers['obtLab']!),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text("${_currentMarks.courseCode} Progress", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.cyanAccent),
            onPressed: _isSaving ? null : _saveMarks,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Outline', icon: Icon(Icons.pie_chart_outline)),
            Tab(text: 'Obtained', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOutlineTab(),
          _buildObtainedTab(),
        ],
      ),
    );
  }
}
