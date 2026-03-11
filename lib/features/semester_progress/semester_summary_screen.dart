import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/models/result_models.dart';
import '../../core/models/task_model.dart';
import '../calendar/academic_repository.dart';
import 'semester_repository.dart';
import '../../core/repositories/app_config_repository.dart';

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
        ]).then((data) async {
          final profile = data[1] as AcademicProfile;
          // Derive admitted semester string from student ID (YYYY-T-...)
          final parts = profile.studentId.split('-');
          final admitYear = parts.isNotEmpty ? (parts[0]) : '2024';
          final admitTermNum = parts.length >= 2 ? int.tryParse(parts[1]) ?? 2 : 2;
          String admitTermName;
          if (admitTermNum == 1) {
            admitTermName = 'Spring';
          } else if (admitTermNum == 3) {
            admitTermName = 'Fall';
          } else {
            admitTermName = 'Summer';
          }
          final admitSemester = '$admitTermName $admitYear';
          final rule = await _repo.fetchScholarshipRule(profile.programId, admitSemester);
          return [...data, rule];
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildEmptyState();
          }

          final summaries = snapshot.data![0] as List<CourseSummary>;
          final profile = snapshot.data![1] as AcademicProfile;
          final rule = snapshot.data!.length > 2 ? snapshot.data![2] : null;

          if (summaries.isEmpty) return _buildEmptyState();

          final projection = _repo.getScholarshipProjection(profile, summaries, rule: rule);

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
                    if (AppConfigRepository().isFeatureEnabled('scholarship_projection'))
                      _buildScholarshipCard(projection)
                    else 
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Scholarship projection is temporarily unavailable.",
                            style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    const Text(
                      "Course Performance",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 270, // Enough for ring + info + exam chips
                      ),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) => _buildCourseCard(summaries[index]),
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
              Row(
                children: [
                  if (projection.currentTier.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        projection.currentTier,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      projection.cycleName,
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Yearly Progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Current CGPA", style: TextStyle(color: Colors.white54, fontSize: 11)),
                   Text(projection.currentCGPA.toStringAsFixed(2), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Live Yearly GPA", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(projection.liveYearlyGPA.toStringAsFixed(2), 
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Goal Yearly GPA", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(projection.projectedYearlyGPA.toStringAsFixed(2), 
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text("Live CGPA", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(projection.liveCGPA.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text("↑ Based on marks", style: TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic)),
                ],
              ),
              Container(width: 1, height: 36, color: Colors.white10),
              Column(
                children: [
                  const Text("If Goals Hit", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(projection.goalCGPA.toStringAsFixed(2),
                    style: TextStyle(
                      color: projection.goalCGPA > projection.currentCGPA ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text("↑ Based on grade goals", style: TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
          
          const Divider(height: 30, color: Colors.white10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _creditInfo("Annual Goal", projection.cycleCreditsGoal, Colors.white54),
              _creditInfo("✓ Done", projection.cycleCreditsCompleted, Colors.greenAccent),
              _creditInfo("This Sem", projection.cycleCreditsThisSemester, Colors.cyanAccent),
              _creditInfo("Remaining", projection.cycleCreditsRemaining - projection.cycleCreditsThisSemester, Colors.amberAccent),
            ],
          ),

          const Divider(height: 30, color: Colors.white10),
          
          Text(
            projection.cycleSemestersCount >= 3
              ? "SGPA needed this semester to achieve:"
              : "Avg SGPA needed in remaining ${3 - projection.cycleSemestersCount} semester(s):", 
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ...projection.tierRequirements.map((req) => _buildRequirementRow(req)),
        ],
      ),
    );
  }

  Widget _creditInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1), 
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }

  Widget _buildRequirementRow(TierRequirement req) {
    Color color;
    if (req.isAchieved) {
      color = Colors.greenAccent;
    } else if (req.isImpossible) {
      color = Colors.redAccent;
    } else {
      color = Colors.cyanAccent;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getRequirementIcon(req), 
            color: color.withValues(alpha: 0.7), 
            size: 16
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(req.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          if (req.isAchieved)
            const Text("✓ Achieved", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))
          else if (req.isImpossible)
            const Text("Impossible", style: TextStyle(color: Colors.redAccent, fontSize: 11))
          else
            Text("Need: ${req.requiredSGPA?.toStringAsFixed(2) ?? '--'}", 
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getRequirementIcon(TierRequirement req) {
    if (req.isAchieved) return Icons.check_circle;
    if (req.isImpossible) return Icons.cancel_outlined;
    return Icons.radio_button_unchecked;
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
    final activeColor = isHampered ? Colors.redAccent : const Color(0xFF2BD8D5);
    
    return GestureDetector(
      onTap: () => _showGoalManager(summary),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141927),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF29314F), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFFE5B585)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    summary.title, 
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.edit, size: 11, color: Colors.white24),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Centered ring
            _buildSmallRing(summary.marksObtained, activeColor),
            
            const SizedBox(height: 10),
            
            // Course code
            Text(summary.code, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
            
            const SizedBox(height: 8),

            // Info rows below ring
            _buildCompactRow("Goal", summary.gradeGoal ?? "—"),
            if (summary.gradeGoal != null)
              _buildCompactRow(
                "Need Final", 
                "${summary.targetFinalScore.toStringAsFixed(1)}%",
                color: summary.targetFinalScore > 100 ? Colors.redAccent : Colors.white70,
              ),
            _buildCompactRow(
              "Status", 
              isHampered ? "⚠ Danger" : "✓ Healthy",
              color: isHampered ? Colors.redAccent : activeColor,
            ),

            // Exam chips
            if (summary.midExam != null || summary.finalExam != null) ...[
              const SizedBox(height: 8),
              const _DashedDivider(),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 4,
                children: [
                  if (summary.midExam != null)
                    _buildChip("Mid: ${_formatDate(summary.midExam!['date'])}", small: true),
                  if (summary.finalExam != null)
                    _buildChip("Final: ${_formatDate(summary.finalExam!['exam_date'])}", small: true),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallRing(double marks, Color activeColor) {
    final progress = (marks / 100).clamp(0.0, 1.0);
    const size = 72.0;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: CircularProgressIndicator(
              value: 1.0, strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1B2236)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: size, height: size,
              child: CircularProgressIndicator(
                value: value, strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Text(
            "${marks.toStringAsFixed(1)}%",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(value, style: TextStyle(color: color ?? Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildChip(String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 14, vertical: small ? 3 : 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF2B3A70)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: const Color(0xFF7B8DD8), fontSize: small ? 9 : 11, fontWeight: FontWeight.w500)),
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
