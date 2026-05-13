import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_summary.dart';

class DegreeProgressScreen extends ConsumerStatefulWidget {
  const DegreeProgressScreen({super.key});

  @override
  ConsumerState<DegreeProgressScreen> createState() => _DegreeProgressScreenState();
}

class _DegreeProgressScreenState extends ConsumerState<DegreeProgressScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(profileRepositoryProvider);
        ref.invalidate(allSemesterSummariesProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  String _formatSemester(String? semester) {
    if (semester == null || semester.isEmpty) return "Unknown";
    return semester.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  int _getSemesterWeight(String semester) {
    final lower = semester.toLowerCase();
    if (lower.contains('spring')) return 1;
    if (lower.contains('summer')) return 2;
    if (lower.contains('fall')) return 3;
    return 0;
  }

  int _getYear(String semester) {
    final match = RegExp(r'\d{4}').firstMatch(semester);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    // Rely strictly on synchronous cached state
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(backgroundColor: Color(0xFF16202A), body: Center(child: Text('User not found.', style: TextStyle(color: Colors.white))));
    }

    final profileStream = ref.watch(profileRepositoryProvider).streamProfile(userId);
    final semesterSummariesAsync = ref.watch(allSemesterSummariesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        title: const Text('Degree Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.cyan),
            onPressed: () async {
              await context.push('/onboarding/course-history', extra: {'isEditMode': true});
              ref.invalidate(allSemesterSummariesProvider);
              ref.invalidate(academicStateProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileRepositoryProvider);
          ref.invalidate(allSemesterSummariesProvider);
          ref.invalidate(academicStateProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.cyan,
        backgroundColor: const Color(0xFF1E2836),
        child: StreamBuilder<Profile?>(
          stream: profileStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: Center(child: Text('Profile not found.', style: TextStyle(color: Colors.white))),
                ),
              );
            }

          final summariesRaw = (semesterSummariesAsync is AsyncData) 
              ? (semesterSummariesAsync as AsyncData<List<SemesterSummary>>).value 
              : <SemesterSummary>[];

          final int semestersCount = summariesRaw.length;
          final double earnedCredits = profile.totalCreditsEarned ?? 0.0;
          final int coursesDone = profile.totalCoursesCompleted;
          
          final programDetailsAsync = profile.programCode != null 
              ? ref.watch(programDetailsProvider(profile.programCode!))
              : const AsyncData<Map<String, dynamic>?>(null);
          
          final double requiredCredits = (programDetailsAsync.value?['total_degree_credits'] as num?)?.toDouble() ?? 140.0;
          final String programName = programDetailsAsync.value?['name'] ?? profile.programCode ?? 'Unknown Program';
          
          final academicState = ref.watch(academicStateProvider).value;
          final String currentTrack = academicState?.track == 'bi_semester' ? 'Bi-Semester Track' : 'Tri-Semester Track';
          final String? runningSemesterCode = academicState?.currentSemesterCode;
          final String? upcomingSemesterCode = academicState?.nextSemesterCode;

          // Simple chronological sort for display, filtering out both running and upcoming semesters
          final summaries = summariesRaw
              .where((s) => s.semesterCode != runningSemesterCode && s.semesterCode != upcomingSemesterCode)
              .toList();
              
          summaries.sort((a, b) {
            final yearA = _getYear(a.semesterCode);
            final yearB = _getYear(b.semesterCode);
            if (yearA != yearB) return yearA.compareTo(yearB);
            return _getSemesterWeight(a.semesterCode).compareTo(_getSemesterWeight(b.semesterCode));
          });

          final double progressPercent = (earnedCredits / requiredCredits).clamp(0.0, 1.0);
          final int displayPercent = (progressPercent * 100).toInt();

          final double actualCgpa = profile.cgpa ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressCard(profile, earnedCredits, requiredCredits, displayPercent, programName, currentTrack),
                const SizedBox(height: 16),
                _buildStatsGrid(semestersCount, earnedCredits, coursesDone, profile),
                const SizedBox(height: 16),
                _buildCgpaCard(actualCgpa),
                const SizedBox(height: 16),
                _buildSemesterSummaryCard(context),
                const SizedBox(height: 32),
                _buildSemesterListState(summaries),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildProgressCard(Profile profile, double earnedCredits, double requiredCredits, int percent, String programName, String currentTrack) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFF2A364B),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                  strokeAlign: CircularProgressIndicator.strokeAlignCenter,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$percent%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Complete', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                ),
                child: Text(
                  programName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentTrack,
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${earnedCredits.toStringAsFixed(1)} / ${requiredCredits.toStringAsFixed(0)} credits earned',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int semestersCount, double credits, int completed, Profile profile) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      children: [
        _buildGridItem(Icons.calendar_month, Colors.purpleAccent, semestersCount.toString(), 'Semesters'),
        _buildGridItem(Icons.star, Colors.greenAccent, credits.toStringAsFixed(1), 'Credits'),
        _buildGridItem(Icons.check_circle_outline, Colors.orangeAccent, completed.toString(), 'Completed'),
        _buildGridItem(Icons.phone_android, Colors.cyanAccent, profile.enrolledCredits.toStringAsFixed(1), 'Doing Now'),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, Color iconColor, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
      ),
    );
  }

  Widget _buildCgpaCard(double cgpa) {
    String cgpaLabel = "Good";
    Color labelColor = Colors.greenAccent;
    if (cgpa >= 3.8) {
      cgpaLabel = "Outstanding";
      labelColor = Colors.greenAccent; // Can use gold if preferred
    } else if (cgpa >= 3.5) {
      cgpaLabel = "Excellent";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              cgpa.toStringAsFixed(2),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CGPA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(cgpaLabel, style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.emoji_events, color: Colors.greenAccent.withOpacity(0.8), size: 32),
        ],
      ),
    );
  }

  Widget _buildSemesterSummaryCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/semester-summary'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2836),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.cyan, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Semester Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Set goals & track scholarships', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterListState(List<SemesterSummary> summaries) {
    if (summaries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Previous Semesters'),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2836),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: ExpansionTile(
                  iconColor: Colors.cyan,
                  collapsedIconColor: Colors.grey,
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatSemester(summary.semesterCode), 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${summary.courses.length} Courses • ${(summary.creditsEarned ?? 0.0).toStringAsFixed(1)} Cr', 
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMiniStat('TGPA', (summary.tgpa ?? 0.0).toStringAsFixed(2)),
                          const SizedBox(width: 8),
                          _buildMiniStat('CGPA', (summary.cgpa ?? 0.0).toStringAsFixed(2)),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(flex: 3, child: Text('Course Name', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Cr', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Grade', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(summary.courses).map((course) {
                            final data = course as Map<String, dynamic>;
                            final double courseCredits = (data['credits'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(data['code'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 13))),
                                  Expanded(flex: 1, child: Text(courseCredits.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                  Expanded(flex: 1, child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(data['grade'] ?? 'N/A', textAlign: TextAlign.center, style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(Icons.school, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No semester data yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
      ],
    );
  }
}
