import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate_v2/core/models/profile.dart';
import 'package:ewumate_v2/core/models/semester_summary.dart';
import 'package:ewumate_v2/core/repositories/profile_repository.dart';
import 'package:ewumate_v2/core/repositories/progress_repository.dart';
import 'package:ewumate_v2/core/utils/grade_helper.dart';
import 'package:ewumate_v2/core/repositories/course_repository.dart';
import 'package:ewumate_v2/core/repositories/dashboard_repository.dart';
import 'package:ewumate_v2/core/models/semester_analytics.dart';
import 'semester_summary_providers.dart';

class SemesterSummaryScreen extends ConsumerStatefulWidget {
  const SemesterSummaryScreen({super.key});

  @override
  ConsumerState<SemesterSummaryScreen> createState() => _SemesterSummaryScreenState();
}

class _SemesterSummaryScreenState extends ConsumerState<SemesterSummaryScreen> {
  @override
  Widget build(BuildContext context) {
    final policyAsync = ref.watch(userScholarshipPolicyProvider);
    final academicYearsAsync = ref.watch(academicYearsFutureProvider);
    final currentMarksAsync = ref.watch(currentSemesterMarksProvider);
    final analyticsAsync = ref.watch(currentAnalyticsProvider);
    final targetTier = ref.watch(scholarshipTargetProvider);
    final awardsAsync = ref.watch(awardedScholarshipProvider);

      final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(currentProfileFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Semester Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, st) => Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                analyticsAsync.when(
                  data: (analytics) => _buildRigorousSummaryBox(profile, policyAsync, analytics, currentMarksAsync, awardsAsync),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 36),

                _buildSectionTitle('Scholarship Target', Icons.emoji_events_rounded, Colors.amberAccent),
                const SizedBox(height: 16),
                _buildScholarshipSelector(policyAsync, targetTier),
                const SizedBox(height: 36),

                _buildSectionTitle('Running Goals', Icons.track_changes_rounded, Colors.cyanAccent),
                const SizedBox(height: 16),
                _buildGoalInputGrid(currentMarksAsync),

                const SizedBox(height: 36),
                _buildSectionTitle('Academic Journey', Icons.timeline_rounded, Colors.purpleAccent),
                const SizedBox(height: 16),
                _buildAcademicYearsTimeline(academicYearsAsync, awardsAsync),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRigorousSummaryBox(Profile? profile, AsyncValue policyAsync, SemesterAnalytics? analytics, AsyncValue currentMarksAsync, AsyncValue<List<ScholarshipAward>> awardsAsync) {
    final policy = policyAsync.valueOrNull;
    final predictedSgpa = analytics?.liveSgpa ?? ref.watch(projectedSGPAProvider);
    final predictedCgpa = analytics?.liveCgpa ?? ref.watch(projectedCGPAProvider).valueOrNull ?? profile?.cgpa ?? 0.0;
    final currentYearEarned = analytics?.completedCredit ?? ref.watch(currentYearEarnedCreditsProvider).valueOrNull ?? 0.0;
    
    // Calculate fallback enrolled credits from currently loaded marks
    final currentMarks = currentMarksAsync.valueOrNull ?? [];
    final allMeta = ref.watch(allCoursesProvider).valueOrNull ?? [];
    double enrolledCreditsFromMarks = 0.0;
    for (var m in currentMarks) {
      final meta = allMeta.where((c) => c.code == m.courseCode).firstOrNull;
      enrolledCreditsFromMarks += meta?.creditVal ?? 3.0;
    }

    // Check if on track for target
    final targetTier = ref.watch(scholarshipTargetProvider);
    double targetThreshold = 3.50; // default
    if (targetTier == "Dean's List") targetThreshold = policy?.tierDeansListMin ?? 3.75;
    if (targetTier == "Merit 100%") targetThreshold = policy?.tierMerit100Min ?? 3.90;
    if (targetTier == "Medha Lalon") targetThreshold = policy?.tierMedhaLalonMin ?? 3.50;
    
    final isOnTrack = predictedCgpa >= targetThreshold;

    final awards = awardsAsync.valueOrNull ?? [];
    // Find if there's an award active for the current/next year
    // We determine the "Current Year" by the length of the academic journey
    final journeyLength = ref.watch(academicYearsFutureProvider).valueOrNull?.length ?? 1;
    final activeAward = awards.where((a) => a.forYear == journeyLength || a.forYear == journeyLength + 1).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnTrack 
            ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
            : [const Color(0xFF451A03), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isOnTrack ? const Color(0xFF1E3A8A) : Colors.orangeAccent).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('LIVE PROJECTION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              if (targetTier != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnTrack ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isOnTrack ? Colors.green : Colors.amber, width: 1),
                  ),
                  child: Text(
                    activeAward != null 
                      ? 'AWARDED ${activeAward.waiver.toStringAsFixed(0)}%' 
                      : (isOnTrack ? 'ON TRACK' : 'AT RISK'),
                    style: TextStyle(
                      color: activeAward != null ? Colors.cyanAccent : (isOnTrack ? Colors.greenAccent : Colors.amberAccent), 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900
                    ),
                  ),
                ),
            ],
          ),
          if (activeAward != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${activeAward.tier}: ${activeAward.reason}',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 24),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            children: [
              _buildStatItem('Predicted\nSGPA', (predictedSgpa ?? 0.0).toStringAsFixed(2), const Color(0xFF10B981), Icons.trending_up_rounded),
              _buildStatItem('Projected\nCGPA', (predictedCgpa ?? 0.0).toStringAsFixed(2), const Color(0xFF06B6D4), Icons.speed_rounded),
              _buildStatItem('Last\nCGPA', (profile?.cgpa ?? 0.0).toStringAsFixed(2), Colors.white, Icons.history_rounded),

              _buildStatItem('Total\nEarned', (analytics?.completedCredit ?? profile?.totalCreditsEarned ?? 0.0).toStringAsFixed(1), const Color(0xFFF59E0B), Icons.stars_rounded, suffix: ' Cr'),
              _buildStatItem('Curr\nEnrolled', (analytics?.takenInThisSem ?? enrolledCreditsFromMarks).toStringAsFixed(1), const Color(0xFFF43F5E), Icons.school_rounded, suffix: ' Cr'),
              _buildStatItem('Year\nEarned', (currentYearEarned ?? 0.0).toStringAsFixed(1), const Color(0xFF8B5CF6), Icons.military_tech_rounded, suffix: ' / ${(analytics?.requiredCredit ?? policy?.annualCreditsRequired ?? 30.0).toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, {String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.9), size: 26),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                if (suffix.isNotEmpty) TextSpan(text: suffix, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildScholarshipSelector(AsyncValue policyAsync, String? targetTier) {
    return policyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => const Text('Error loading policies', style: TextStyle(color: Colors.red)),
      data: (policy) {
        if (policy == null) return const Text('No scholarship policy mapped for your program yet.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic));

        return Row(
          children: [
            _buildTierCard('Medha Lalon', policy.tierMedhaLalonMin, targetTier, const Color(0xFF10B981)),
            const SizedBox(width: 12),
            _buildTierCard('Dean\'s List', policy.tierDeansListMin, targetTier, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _buildTierCard('Merit 100%', policy.tierMerit100Min, targetTier, const Color(0xFF8B5CF6)),
          ],
        );
      },
    );
  }

  Widget _buildTierCard(String name, double cgpaReq, String? currentTarget, Color brandColor) {
    final isSelected = currentTarget == name || (currentTarget == null && name == 'Medha Lalon');
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(scholarshipTargetProvider.notifier).updateTarget(name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [brandColor.withOpacity(0.4), brandColor.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? brandColor : Colors.white12, width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [BoxShadow(color: brandColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              Text(name, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: Text('${cgpaReq.toStringAsFixed(2)} CGPA', style: TextStyle(color: isSelected ? brandColor : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInputGrid(AsyncValue currentMarksAsync) {
    return currentMarksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => const Text('Error loading courses', style: TextStyle(color: Colors.red)),
      data: (marks) {
        if (marks.isEmpty) {
          return const Text('No active courses found for dynamic goals.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: marks.length,
          itemBuilder: (context, index) {
            final course = marks[index];
            final goals = ref.watch(goalGradesProvider);
            final currentGoal = goals[course.courseCode] ?? 'A';
            final gradeScaleMap = ref.watch(gradeScaleMapProvider).valueOrNull ?? {};

            double evaluatedMarks = 0.0;
            double obtained = 0.0;

            if (course.obtMid != null) { evaluatedMarks += course.distMid; obtained += course.obtMid!; }
            if (course.obtFinal != null) { evaluatedMarks += course.distFinal; obtained += course.obtFinal!; }
            if (course.obtAssignment != null) { evaluatedMarks += (course.distAssignment ?? 0); obtained += course.obtAssignment!; }
            if (course.obtPresentation != null) { evaluatedMarks += (course.distPresentation ?? 0); obtained += course.obtPresentation!; }
            if (course.obtAttendance != null) { evaluatedMarks += (course.distAttendance ?? 0); obtained += course.obtAttendance!; }
            if (course.obtClassPerformance != null) { evaluatedMarks += (course.distClassPerformance ?? 0); obtained += course.obtClassPerformance!; }
            if (course.obtQuizzes.isNotEmpty) {
              evaluatedMarks += course.distQuiz;
              obtained += course.obtQuizzes.fold(0.0, (a, b) => a + b);
            }
            if (course.obtShortQuizzes.isNotEmpty) {
              evaluatedMarks += (course.distShortQuiz ?? 0.0);
              obtained += course.obtShortQuizzes.fold(0.0, (a, b) => a + b);
            }

            double reqMarks = gradeScaleMap[currentGoal] ?? _getRequiredMarksFallback(currentGoal);
            
            double lostMarks = evaluatedMarks - obtained;
            double maxPossibleFinalScore = 100.0 - lostMarks;
            double remainingRequired = reqMarks - obtained;

            bool achievable = maxPossibleFinalScore >= reqMarks;
            String statusText = achievable
                ? 'Need ${remainingRequired > 0 ? remainingRequired.toStringAsFixed(1) : "0"}'
                : 'Mathematically unlikely';
            Color statusColor = achievable ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
            IconData statusIcon = achievable ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;

            if (obtained == 0) {
              statusText = 'No evaluation';
              statusColor = Colors.grey[500]!;
              statusIcon = Icons.hourglass_empty_rounded;
            }

            // Cleanup messy UUIDs for clean display
            String displayCode = course.courseCode;
            if (displayCode.length > 15) displayCode = 'Course';
            String displayName = course.courseName ?? '';
            if (displayName.length > 15 && displayName == course.courseCode) displayName = 'Unknown Subject';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(displayCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                      Icon(statusIcon, color: statusColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500)),

                  const SizedBox(height: 16),
                  
                  // Half-Circle Gauge
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CustomPaint(
                            size: const Size(120, 60), 
                            painter: HalfCircleProgressPainter(
                              progress: (obtained / reqMarks).clamp(0.0, 1.0),
                              color: statusColor,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Text(
                              '${((obtained / reqMarks).clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF0F172A),
                        value: currentGoal,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 16),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.cyanAccent),
                        items: ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D'].map((g) {
                          return DropdownMenuItem(value: g, child: Text("Goal: $g"));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(goalGradesProvider.notifier).updateGoal(course.courseCode, val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Obtained', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600)),
                          Text(obtained.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _getRequiredMarksFallback(String grade) {
    switch (grade) {
      case 'A+': return 90;
      case 'A': return 80;
      case 'A-': return 75;
      case 'B+': return 70;
      case 'B': return 65;
      case 'B-': return 60;
      case 'C+': return 55;
      case 'C': return 50;
      case 'D': return 45;
      default: return 0;
    }
  }

  Widget _buildAcademicYearsTimeline(AsyncValue<List<AcademicYear>> asyncYears, AsyncValue<List<ScholarshipAward>> awardsAsync) {
    return asyncYears.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => const Text('Error loading timeline', style: TextStyle(color: Colors.red)),
      data: (years) {
        if (years.isEmpty) return const Text('No academic history found.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic));

        return Column(
          children: years.map((ay) {
            final awards = awardsAsync.valueOrNull ?? [];
            final ayAward = awards.where((a) => a.forYear == ay.yearNumber + 1).firstOrNull;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, color: Colors.purpleAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Year ${ay.yearNumber}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text('${ay.totalCreditsEarned.toStringAsFixed(1)} Cr Earned', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      if (ayAward != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.cyanAccent, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ay.semesters.isEmpty
                    ? Center(
                        child: Text(
                          'Upcoming Year',
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      )
                    : Row(
                        children: ay.semesters.map((SemesterSummary s) {
                          return Expanded(
                            child: Column(
                              children: [
                                Text(
                                  (s as dynamic).semesterCode.toString().toUpperCase().replaceAll('_', '').replaceAllMapped(RegExp(r'(\d{4})$'), (m) => " '${m.group(1)!.substring(2)}"), 
                                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                                  child: Text((s.tgpa ?? 0.0).toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class HalfCircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  HalfCircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Rect rect = Rect.fromCenter(center: Offset(size.width / 2, size.height), width: size.width, height: size.width);
    
    // Draw background arc
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);
    
    // Draw progress arc
    double sweepAngle = (progress.clamp(0.0, 1.0)) * math.pi;
    canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant HalfCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
