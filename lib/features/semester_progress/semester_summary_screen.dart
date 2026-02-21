import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/models/result_models.dart';
import '../../core/models/task_model.dart';
import '../calendar/academic_repository.dart';
import 'semester_repository.dart';

class SemesterSummaryScreen extends StatefulWidget {
  const SemesterSummaryScreen({super.key});

  @override
  State<SemesterSummaryScreen> createState() => _SemesterSummaryScreenState();
}

class _SemesterSummaryScreenState extends State<SemesterSummaryScreen> {
  final _repo = SemesterRepository();
  final _academicRepo = AcademicRepository();
  String? _currentSemester;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final sem = await _academicRepo.getCurrentSemesterCode();
    if (mounted) {
      setState(() {
        _currentSemester = sem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentSemester == null 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _repo.fetchSemesterSummary(_currentSemester!),
          _repo.fetchAcademicProfile(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildEmptyState();
          }

          final summaries = snapshot.data![0] as List<CourseSummary>;
          final profile = snapshot.data![1] as AcademicProfile;

          if (summaries.isEmpty) return _buildEmptyState();

          final projection = _repo.getScholarshipProjection(profile, summaries);

          return Column(
            children: [
              const EWUmateAppBar(
                title: "Semester Summary",
                showMenu: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildOverviewHeader(summaries),
                    const SizedBox(height: 20),
                    _buildScholarshipCard(projection),
                    const SizedBox(height: 30),
                    const Text(
                      "Course Performance",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: summaries.map((s) => SizedBox(
                              width: (constraints.maxWidth - 20) / 2,
                              child: _buildCourseCard(s)
                            )).toList(),
                          );
                        }
                        return Column(
                          children: summaries.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildCourseCard(s),
                          )).toList(),
                        );
                      }
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.data_exploration_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("No enrolled courses found", style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text("Retry", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard(ScholarshipProjection projection) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      borderColor: Colors.amberAccent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🏆 Scholarship Projection",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Existing CGPA: ${projection.currentCGPA.toStringAsFixed(2)}", 
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Target SGPA: ${projection.projectedSGPA.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (projection.currentTier.isNotEmpty)
             _buildTierInfo("Current Eligibility", "🎉 ${projection.currentTier}", Icons.verified, Colors.greenAccent)
          else
            const Text("🌱 Keep pushing! Set goals to unlock scholarships.", style: TextStyle(color: Colors.white70, fontSize: 13)),
          
          const Divider(height: 30, color: Colors.white10),
          
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Next Milestone: ${projection.nextTier}", 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      projection.distanceToNext > 0 
                        ? "Expected CGPA: ${projection.projectedCGPA.toStringAsFixed(2)}. You are ${projection.distanceToNext.toStringAsFixed(2)} away! ✨"
                        : "Expected CGPA: ${projection.projectedCGPA.toStringAsFixed(2)}. Awesome! Keep it up! 🔥",
                      style: TextStyle(color: projection.distanceToNext > 0 ? Colors.cyanAccent : Colors.amberAccent, fontSize: 12),
                    ),
                    if (projection.requiredSGPA != null && projection.distanceToNext > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "💡 Suggestion: You need an SGPA of ${projection.requiredSGPA!.toStringAsFixed(2)} this semester to reach this tier.",
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ] else if (projection.requiredSGPA == null && projection.distanceToNext > 0) ...[
                       const SizedBox(height: 6),
                       const Text(
                          "⚠️ This tier is mathematically out of reach this semester based on your current credits. Keep pushing for the next one!",
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                        ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierInfo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewHeader(List<CourseSummary> summaries) {
    int onTrack = summaries.where((s) => (s.marksObtained / 100) >= 0.7).length;
    
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
      child: Row(
        children: [
          _buildSummaryRing(onTrack / summaries.length),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Semester Track", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  onTrack == summaries.length ? "EXCELLENT" : "ON TRACK",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$onTrack of ${summaries.length} courses meeting goals",
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRing(double progress) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, _) => Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseSummary summary) {
    bool isHampered = summary.upcomingTasks.any((t) => t.dueDate.isBefore(DateTime.now()));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141927), // deep navy background from image
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF29314F), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, size: 14, color: Colors.white24),
              const SizedBox(width: 4),
              const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFFE5B585)), // box icon from image
              const SizedBox(width: 8),
              Expanded(
                child: Text(summary.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis,),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showGoalManager(summary),
                child: const Icon(Icons.edit, size: 14, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              // Dummy Switch
              Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B61D1), // Active blue track
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          Center(
            child: _buildLargePerformanceRing(summary.marksObtained, isHampered),
          ),
          
          const SizedBox(height: 30),
          
          _buildDetailRow("Course Code", summary.code),
          const SizedBox(height: 12),
          _buildDetailRow("Target Goal", summary.gradeGoal ?? "Not Set"),
          const SizedBox(height: 12),
          if (summary.gradeGoal != null) ...[
             _buildDetailRow("Need In Final", "${summary.targetFinalScore.toStringAsFixed(2)}%"),
             const SizedBox(height: 12),
          ],
          _buildDetailRow("Status", isHampered ? "Danger" : "Healthy", 
             valueColor: isHampered ? Colors.redAccent : const Color(0xFF2BD8D5)),
             
          const SizedBox(height: 16),
          const _DashedDivider(),
          const SizedBox(height: 16),
          
          Text("Included Exams (${(summary.midExam != null ? 1 : 0) + (summary.finalExam != null ? 1 : 0)}):", 
             style: const TextStyle(color: Colors.white30, fontSize: 11)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
               if (summary.midExam != null)
                 _buildChip("Mid: ${_formatDate(summary.midExam!['date'])}"),
               if (summary.finalExam != null)
                 _buildChip("Final: ${_formatDate(summary.finalExam!['exam_date'])}"),
               if (summary.midExam == null && summary.finalExam == null)
                 _buildChip("No exams mapped")
            ],
          )
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "TBA";
    DateTime? date = DateTime.tryParse(dateStr);
    if (date == null) {
      try {
        date = DateFormat("d MMMM yyyy").parse(dateStr);
      } catch (_) {}
    }
    return date != null ? DateFormat('MM/dd/yyyy').format(date) : dateStr;
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(color: valueColor ?? Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF2B3A70)), // blueish badge border
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF7B8DD8), fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildLargePerformanceRing(double marks, bool hasHamper) {
    final progress = marks / 100;
    final activeColor = hasHamper ? Colors.redAccent : const Color(0xFF2BD8D5); // Cyan active
    final trackColor = const Color(0xFF1B2236);
    
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
           BoxShadow(
             color: activeColor.withValues(alpha: 0.15), // Outer glow
             blurRadius: 20,
             spreadRadius: 2,
           ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130, height: 130,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
               width: 130, height: 130,
               child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${marks.toStringAsFixed(2)}%",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalManager(CourseSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Performance Tracking", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildMarksInput(summary),
            const SizedBox(height: 20),
            const Text("Set Grade Goal", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _repo.availableGrades.map((g) => ChoiceChip(
                label: Text(g),
                selected: summary.gradeGoal == g,
                onSelected: (v) async {
                   if (v) {
                     await _repo.updateCourseStat(_currentSemester!, summary.code, goal: g);
                     if (context.mounted) Navigator.pop(context);
                     setState(() {});
                   }
                },
                backgroundColor: Colors.white10,
                selectedColor: Colors.cyanAccent,
                labelStyle: TextStyle(color: summary.gradeGoal == g ? Colors.black : Colors.white),
              )).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksInput(CourseSummary s) {
    final controller = TextEditingController(text: s.marksObtained.toInt().toString());
    return Row(
      children: [
        const Expanded(child: Text("Current Marks (0-60%)", style: TextStyle(color: Colors.white70))),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixText: "%",
              suffixStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
            onSubmitted: (v) async {
              final val = double.tryParse(v);
              if (val != null) {
                await _repo.updateCourseStat(_currentSemester!, s.code, marks: val);
                Navigator.pop(context);
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white12),
              ),
            );
          }),
        );
      },
    );
  }
}
