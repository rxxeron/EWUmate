import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/widgets/glass_kit.dart';
import '../../features/results/results_repository.dart';
import '../../core/models/result_models.dart';
import '../../features/results/course_history_editor.dart';

/// Rebuilt Degree Progress Screen - Instant Updates via Stream
class DegreeProgressScreen extends StatefulWidget {
  const DegreeProgressScreen({super.key});

  @override
  State<DegreeProgressScreen> createState() => _DegreeProgressScreenState();
}

class _DegreeProgressScreenState extends State<DegreeProgressScreen>
    with TickerProviderStateMixin {
  final ResultsRepository _repo = ResultsRepository();

  double _totalRequiredCredits = 140.0; // Default fallback

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnim = CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: const Text(
          "Degree Progress",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.cyanAccent),
            tooltip: 'Edit Course History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourseHistoryEditor()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.cyanAccent),
            tooltip: 'Download Grade Sheet',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("PDF Download coming soon!"),
                  backgroundColor: Colors.cyanAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AcademicProfile>(
        stream: _repo.streamAcademicProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final profile = snapshot.data!;

          // Update Animation Trigger
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              double calculatedTotal =
                  profile.totalCreditsEarned + profile.remainedCredits;
              if (calculatedTotal > 0) {
                _totalRequiredCredits = calculatedTotal;
              }
              _progressAnimController.animateTo(1.0);
            }
          });

          return _buildBody(profile);
        },
      ),
    );
  }

  Widget _buildBody(AcademicProfile p) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _buildProgressCard(p),
          const SizedBox(height: 24),
          _buildStatsGrid(p),
          const SizedBox(height: 24),
          _buildCGPASection(p),
          if (p.scholarshipStatus.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildScholarshipCard(p),
          ],
          const SizedBox(height: 24),
          _buildSemesterSection(p),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.redAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            "Error loading data: $error",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(AcademicProfile p) {
    final progress = (p.totalCreditsEarned / _totalRequiredCredits).clamp(
      0.0,
      1.0,
    );

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        final animatedProgress = progress * _progressAnim.value;

        return GlassContainer(
          padding: const EdgeInsets.all(28),
          borderRadius: 24,
          borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: animatedProgress,
                        strokeWidth: 12,
                        bgColor: Colors.white.withValues(alpha: 0.1),
                        progressColor: _getProgressColor(progress),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(animatedProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Complete",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  p.program.isNotEmpty ? p.program : "Unknown Program",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${p.totalCreditsEarned.toStringAsFixed(0)} / ${_totalRequiredCredits.toStringAsFixed(0)} credits earned",
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(AcademicProfile p) {
    return Row(
      children: [
        _buildStatCard(
          Icons.calendar_month,
          "${p.semesters.length}",
          "Semesters",
          Colors.purpleAccent,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          Icons.menu_book,
          "${p.totalCoursesCompleted}",
          "Courses",
          Colors.orangeAccent,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          Icons.stars,
          p.totalCreditsEarned.toStringAsFixed(0),
          "Credits",
          Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderRadius: 16,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCGPASection(AcademicProfile p) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      borderColor: _getCGPAColor(p.cgpa).withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCGPAColor(p.cgpa),
                  _getCGPAColor(p.cgpa).withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Center(
              child: Text(
                p.cgpa.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CGPA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCGPALabel(p.cgpa),
                  style: TextStyle(color: _getCGPAColor(p.cgpa), fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(_getCGPAIcon(p.cgpa), color: _getCGPAColor(p.cgpa), size: 28),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard(AcademicProfile p) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      borderColor: Colors.amberAccent.withValues(alpha: 0.8),
      color: Colors.amber.withValues(alpha: 0.1),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.school,
              size: 100,
              color: Colors.amberAccent.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amberAccent, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Scholarship Awarded!",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                p.scholarshipStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Based on your last 3 consecutive semesters performance.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSection(AcademicProfile p) {
    if (p.semesters.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(40),
        borderRadius: 16,
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              "No semester data yet",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.timeline, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              "Semester History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...p.semesters.asMap().entries.map((entry) {
          return _buildSemesterTile(entry.value, entry.key);
        }),
      ],
    );
  }

  Widget _buildSemesterTile(SemesterResult semester, int index) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 14,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getGPAColor(semester.termGPA),
                  _getGPAColor(semester.termGPA).withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Center(
              child: Text(
                semester.termGPA.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(
            semester.semesterName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TGPA: ${semester.termGPA.toStringAsFixed(2)} | CGPA: ${semester.cumulativeGPA.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${semester.courses.length} courses • ${semester.totalCredits.toStringAsFixed(1)} credits",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          children: semester.courses.map((c) => _buildCourseRow(c)).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseRow(CourseResult course) {
    final isOngoing = course.grade.isEmpty || course.grade == 'Ongoing';
    final color = isOngoing ? Colors.blue : _getGradeColor(course.grade);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                isOngoing ? "..." : course.grade,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildCourseInfoColumn(course)),
          Text(
            "${course.credits} cr",
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoColumn(CourseResult course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseCode,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (course.courseTitle.isNotEmpty &&
            course.courseTitle != course.courseCode)
          Text(
            course.courseTitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.75) return Colors.greenAccent;
    if (progress >= 0.5) return Colors.cyanAccent;
    if (progress >= 0.25) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 3.5) return Colors.greenAccent;
    if (gpa >= 3.0) return Colors.cyanAccent;
    if (gpa >= 2.5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getCGPAColor(double cgpa) => _getGPAColor(cgpa);

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.greenAccent;
    if (grade.startsWith('B')) return Colors.cyanAccent;
    if (grade.startsWith('C')) return Colors.orangeAccent;
    if (grade == 'D') return Colors.orange;
    if (grade == 'F') return Colors.redAccent;
    return Colors.white38;
  }

  String _getCGPALabel(double cgpa) {
    if (cgpa >= 3.9) return "🏆 Outstanding";
    if (cgpa >= 3.75) return "⭐ Excellent";
    if (cgpa >= 3.5) return "👍 Very Good";
    if (cgpa >= 3.0) return "👍 Good";
    if (cgpa >= 2.5) return "📈 Satisfactory";
    if (cgpa >= 2.0) return "⚠️ Needs Improvement";
    return "🚨 Academic Warning";
  }

  IconData _getCGPAIcon(double cgpa) {
    if (cgpa >= 3.5) return Icons.emoji_events;
    if (cgpa >= 3.0) return Icons.thumb_up_alt;
    if (cgpa >= 2.5) return Icons.trending_up;
    return Icons.warning_amber;
  }
}

// Custom circular progress painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color bgColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.bgColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress;
}
