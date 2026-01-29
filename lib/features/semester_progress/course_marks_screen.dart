import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/semester_progress_models.dart';
import '../../core/widgets/glass_kit.dart';
import 'semester_progress_repository.dart';

class CourseMarksScreen extends StatefulWidget {
  final String semesterCode;
  final String courseCode;
  final String courseName;

  const CourseMarksScreen({
    super.key,
    required this.semesterCode,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<CourseMarksScreen> createState() => _CourseMarksScreenState();
}

class _CourseMarksScreenState extends State<CourseMarksScreen>
    with SingleTickerProviderStateMixin {
  final SemesterProgressRepository _repo = SemesterProgressRepository();
  late TabController _tabController;

  bool _loading = true;
  CourseMarks? _courseMarks;

  // Distribution Controllers
  final _midDistCtrl = TextEditingController();
  final _finalDistCtrl = TextEditingController();
  final _quizDistCtrl = TextEditingController();
  final _shortQuizDistCtrl = TextEditingController();
  final _assignmentDistCtrl = TextEditingController();
  final _presentationDistCtrl = TextEditingController();
  final _vivaDistCtrl = TextEditingController();
  final _labDistCtrl = TextEditingController();
  final _attendanceDistCtrl = TextEditingController();

  // Strategy Controllers
  String _quizStrategy = 'bestN'; // bestN, average, sum
  final _quizNCtrl = TextEditingController(text: '2');
  final _shortQuizNCtrl = TextEditingController(text: '2');

  // Obtained Marks Controllers
  final _midObtCtrl = TextEditingController();
  final _finalObtCtrl = TextEditingController();
  final _assignmentObtCtrl = TextEditingController();
  final _presentationObtCtrl = TextEditingController();
  final _vivaObtCtrl = TextEditingController();
  final _labObtCtrl = TextEditingController();
  final _attendanceObtCtrl = TextEditingController();
  final _newQuizCtrl = TextEditingController();
  final _newShortQuizCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // Initialize if needed
    await _repo.initializeCourse(
      widget.semesterCode,
      widget.courseCode,
      courseName: widget.courseName,
    );

    // Fetch
    final marks = await _repo.fetchCourseMarks(
      widget.semesterCode,
      widget.courseCode,
    );

    if (marks != null) {
      _courseMarks = marks;

      // Populate Distribution
      _midDistCtrl.text = marks.distribution.mid?.toString() ?? '';
      _finalDistCtrl.text = marks.distribution.finalExam?.toString() ?? '';
      _quizDistCtrl.text = marks.distribution.quiz?.toString() ?? '';
      _shortQuizDistCtrl.text = marks.distribution.shortQuiz?.toString() ?? '';
      _assignmentDistCtrl.text =
          marks.distribution.assignment?.toString() ?? '';
      _presentationDistCtrl.text =
          marks.distribution.presentation?.toString() ?? '';
      _vivaDistCtrl.text = marks.distribution.viva?.toString() ?? '';
      _labDistCtrl.text = marks.distribution.lab?.toString() ?? '';
      _attendanceDistCtrl.text =
          marks.distribution.attendance?.toString() ?? '';

      // Populate Strategies
      _quizStrategy = marks.quizStrategy;
      _quizNCtrl.text = marks.quizN.toString();
      _shortQuizNCtrl.text = marks.shortQuizN.toString();

      // Populate Obtained
      _midObtCtrl.text = marks.obtained.mid?.toString() ?? '';
      _finalObtCtrl.text = marks.obtained.finalExam?.toString() ?? '';
      _assignmentObtCtrl.text = marks.obtained.assignment?.toString() ?? '';
      _presentationObtCtrl.text = marks.obtained.presentation?.toString() ?? '';
      _vivaObtCtrl.text = marks.obtained.viva?.toString() ?? '';
      _labObtCtrl.text = marks.obtained.lab?.toString() ?? '';
      _attendanceObtCtrl.text = marks.obtained.attendance?.toString() ?? '';
    } else {
      _courseMarks = CourseMarks(
        courseCode: widget.courseCode,
        courseName: widget.courseName,
        distribution: MarkDistribution(),
        obtained: ObtainedMarks(),
        quizStrategy: 'bestN',
        quizN: 2,
        shortQuizN: 2,
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDistribution() async {
    final dist = MarkDistribution(
      mid: double.tryParse(_midDistCtrl.text),
      finalExam: double.tryParse(_finalDistCtrl.text),
      quiz: double.tryParse(_quizDistCtrl.text),
      shortQuiz: double.tryParse(_shortQuizDistCtrl.text),
      assignment: double.tryParse(_assignmentDistCtrl.text),
      presentation: double.tryParse(_presentationDistCtrl.text),
      viva: double.tryParse(_vivaDistCtrl.text),
      lab: double.tryParse(_labDistCtrl.text),
      attendance: double.tryParse(_attendanceDistCtrl.text),
    );

    // Validate Total <= 100
    final total = (dist.mid ?? 0) +
        (dist.finalExam ?? 0) +
        (dist.quiz ?? 0) +
        (dist.shortQuiz ?? 0) +
        (dist.assignment ?? 0) +
        (dist.presentation ?? 0) +
        (dist.viva ?? 0) +
        (dist.lab ?? 0) +
        (dist.attendance ?? 0);

    if (total > 100.001) {
      // Floating point tolerance
      _showSnack("Total marks ($total) cannot exceed 100!", isError: true);
      return;
    }

    // Save Distribution
    await _repo.saveMarkDistribution(
      widget.semesterCode,
      widget.courseCode,
      dist,
      courseName: widget.courseName,
    );

    // Save Strategies
    // The repo doesn't have a specific method for strategies + N,
    // but we can just update the doc directly or add a method.
    // For now, I'll update the 'quizStrategy' and new fields by writing to the doc directly via repo logic
    // actually repo method saveQuizStrategy only takes string.
    // I should probably manually update the doc here or expand repo.
    // simpler: expand repo? No, I can't edit repo in this tool call easily without context switch.
    // I will use a simple workaround: initializeCourse actually sets defaults, I can use a generic update.
    // Or I'll assume I can just update the strategy field, but what about N?
    // Wait, I updated the model, but did I update the repo's save methods?
    // I checked repo, it has `saveQuizStrategy` but not `saveQuizN`.
    // I should have updated repo. I will do a quick direct firestore write here or add a method if I could.
    // Better: I'll use the generic Firestore instance here since I have it in _repo (private) ... no I don't.
    // I'll add a helper method updates to the repo first?
    // Actually, I can just use `_repo.saveMarkDistribution` which merges.
    // I will update the repo to accept the extra fields or just do a manual write if I had access.
    // Since I can't change repo in this call, I'll assume I can update the strategy string.
    // BUT the N values needs saving.
    // I will update the Repo in the NEXT step or include it in this file if I could.
    // Actually, `initializeCourse` sets defaults.
    // I will implement a local `_saveStrategies` that uses `FirebaseFirestore.instance` strictly speaking?
    // No, I should stick to repo pattern.
    // I will use `_repo` to save strategy, but I need to save N too.
    // I'll add a temporary direct write here to avoid blocking, reusing the `_repo`'s internal refs would be ideal but they are private.
    // I'll just use a fresh Firestore instance here for the strategy/N update.

    // ... Direct Firestore Write for Strategy details ...
    // Note: This matches the path in repository
    /*
        .collection('users').doc(uid)
        .collection('semesterProgress').doc(sem)
        .collection('courses').doc(code)
    */
    // I need currentUser.
    // I'll implement a safe update.

    await _saveStrategies(); // Defined below

    _showSnack("Settings saved!", isError: false);
    _loadData();
  }

  Future<void> _saveStrategies() async {
    // Logic to save strategy and N
    // Using direct firestore since repo update is pending/cumbersome in one go

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('semesterProgress')
        .doc(widget.semesterCode)
        .collection('courses')
        .doc(widget.courseCode)
        .set({
      'quizStrategy': _quizStrategy,
      'quizN': int.tryParse(_quizNCtrl.text) ?? 2,
      'shortQuizN': int.tryParse(_shortQuizNCtrl.text) ?? 2,
    }, SetOptions(merge: true));
  }

  Future<void> _saveObtainedMark(
    String category,
    String value, {
    double? maxAllowed,
  }) async {
    final numVal = double.tryParse(value);
    if (numVal == null && value.isNotEmpty) {
      _showSnack("Invalid number", isError: true);
      return;
    }
    // If empty, treat as 0 or null? Usually 0 for calculation.
    final val = numVal ?? 0.0;

    if (maxAllowed != null && val > maxAllowed) {
      _showSnack(
        "Cannot exceed ${maxAllowed.toStringAsFixed(1)}",
        isError: true,
      );
      return;
    }

    await _repo.saveObtainedMark(
      widget.semesterCode,
      widget.courseCode,
      category,
      val,
    );
    _loadData();
  }

  Future<void> _addQuiz(bool isShort) async {
    final ctrl = isShort ? _newShortQuizCtrl : _newQuizCtrl;
    final val = double.tryParse(ctrl.text);
    if (val == null) {
      _showSnack("Invalid mark", isError: true);
      return;
    }
    // Max for individual quiz? Typically not strictly enforcing against distribution-total here,
    // but maybe against a theoretical max like 20? I won't enforce strict single-quiz max
    // as it varies, but definitely non-negative.
    if (val < 0) return;

    if (isShort) {
      await _repo.addShortQuizMark(widget.semesterCode, widget.courseCode, val);
    } else {
      await _repo.addQuizMark(widget.semesterCode, widget.courseCode, val);
    }
    ctrl.clear();
    _loadData();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          widget.courseCode,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: "Marks"),
            Tab(text: "Setup"),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildMarksTab(), _buildSetupTab()],
            ),
    );
  }

  Widget _buildMarksTab() {
    // Recalculate based on model logic
    final totalObt = _courseMarks?.totalObtained ?? 0;
    final totalPos = _courseMarks?.totalPossible ?? 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Summary
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            color: Colors.blueAccent.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryMeta("Obtained", totalObt.toStringAsFixed(1)),
                _summaryMeta("Total", totalPos.toStringAsFixed(0)),
                _summaryMeta("Grade", _courseMarks?.predictedGrade ?? "--"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Basic Fields
          _entryRow(
            "Mid Term",
            _midObtCtrl,
            _courseMarks?.distribution.mid,
            'mid',
          ),
          _entryRow(
            "Final Exam",
            _finalObtCtrl,
            _courseMarks?.distribution.finalExam,
            'finalExam',
          ),
          _entryRow(
            "Assignment",
            _assignmentObtCtrl,
            _courseMarks?.distribution.assignment,
            'assignment',
          ),
          _entryRow(
            "Presentation",
            _presentationObtCtrl,
            _courseMarks?.distribution.presentation,
            'presentation',
          ),
          _entryRow(
            "Viva",
            _vivaObtCtrl,
            _courseMarks?.distribution.viva,
            'viva',
          ),
          _entryRow("Lab", _labObtCtrl, _courseMarks?.distribution.lab, 'lab'),
          _entryRow(
            "Attendance",
            _attendanceObtCtrl,
            _courseMarks?.distribution.attendance,
            'attendance',
          ),

          const Divider(color: Colors.white24, height: 40),

          // Quizzes
          _quizSection(
            "Quizzes",
            _newQuizCtrl,
            _courseMarks?.obtained.quizzes ?? [],
            false,
          ),
          const SizedBox(height: 20),
          _quizSection(
            "Short Quizzes",
            _newShortQuizCtrl,
            _courseMarks?.obtained.shortQuizzes ?? [],
            true,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _summaryMeta(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _entryRow(
    String label,
    TextEditingController ctrl,
    double? max,
    String category,
  ) {
    if (max == null || max <= 0) {
      return const SizedBox.shrink(); // Hide if not applicable
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 2,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: 8,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "/ ${max.toStringAsFixed(0)}",
                  hintStyle: const TextStyle(color: Colors.white30),
                  isDense: true,
                ),
                onSubmitted: (_) =>
                    _saveObtainedMark(category, ctrl.text, maxAllowed: max),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
            onPressed: () =>
                _saveObtainedMark(category, ctrl.text, maxAllowed: max),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _quizSection(
    String title,
    TextEditingController ctrl,
    List<double> marks,
    bool isShort,
  ) {
    final distTotal = isShort
        ? _courseMarks?.distribution.shortQuiz
        : _courseMarks?.distribution.quiz;
    if (distTotal == null || distTotal <= 0) return const SizedBox.shrink();

    // Calculate effective
    final calc = isShort
        ? _courseMarks?.calculatedShortQuizMark
        : _courseMarks?.calculatedQuizMark;
    final strategy = _quizStrategy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Calc: ${calc?.toStringAsFixed(1)} / $distTotal  ($strategy)",
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: marks.asMap().entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                "${e.value}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Add mark",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
              onPressed: () => _addQuiz(isShort),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mark Distribution (Max 100)",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _distInput("Mid Term", _midDistCtrl),
          _distInput("Final Term", _finalDistCtrl),
          _distInput("Assignment", _assignmentDistCtrl),
          _distInput("Presentation", _presentationDistCtrl),
          _distInput("Viva", _vivaDistCtrl),
          _distInput("Lab", _labDistCtrl),
          _distInput("Attendance", _attendanceDistCtrl),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            "Quiz Strategy",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _distInput("Quiz Total Marks", _quizDistCtrl),
          _distInput("Short Quiz Total", _shortQuizDistCtrl),
          const SizedBox(height: 15),
          GlassContainer(
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _quizStrategy,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'bestN',
                    child: Text("Best N (Average of Top N)"),
                  ),
                  DropdownMenuItem(
                    value: 'average',
                    child: Text("Average of All"),
                  ),
                  DropdownMenuItem(value: 'sum', child: Text("Sum of All")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _quizStrategy = val);
                },
              ),
            ),
          ),
          if (_quizStrategy == 'bestN') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _distInput("N for Quiz", _quizNCtrl)),
                const SizedBox(width: 10),
                Expanded(
                  child: _distInput("N for Short Quiz", _shortQuizNCtrl),
                ),
              ],
            ),
          ],
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onPressed: _saveDistribution,
              child: const Text("Save Configuration"),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _distInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
