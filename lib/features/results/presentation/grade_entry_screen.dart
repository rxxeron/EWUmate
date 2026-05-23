import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/grade_helper.dart';
import '../../semester_progress/semester_summary_providers.dart';
import '../../../core/models/grade_scale.dart';
import '../../../core/utils/error_utils.dart';
import '../../auth/auth_providers.dart';

// Provides the list of enrollments needing grades (filtered by blocking logic)
final pendingGradesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final cache = ref.read(cacheServiceProvider);
  final cacheKey = 'pending_grades_${user.id}';

  try {
    // 1. Fetch Active Semester configuration
    String track = profile.track ?? profile.semesterType;
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    final client = Supabase.instance.client;
    final activeSemRes = await client
        .from('active_semester')
        .select()
        .eq('track', track)
        .maybeSingle();

    final activeCode = activeSemRes?['current_semester_code'];
    final submissionStartStr = activeSemRes?['grade_submission_start'];

    bool isPhase2Active = false;
    if (submissionStartStr != null) {
      final submissionStart = DateTime.tryParse(submissionStartStr.toString());
      if (submissionStart != null && DateTime.now().isAfter(submissionStart.add(const Duration(days: 1)))) {
        isPhase2Active = true;
      }
    }

    // 2. Query ALL enrollments with 'enrolled' status that have no grade
    final res = await client
        .from('enrollments')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'enrolled')
        .isFilter('grade', null);

    final allData = List<Map<String, dynamic>>.from(res);

    // 3. Filter: Only show those that are actually blocking
    // - Past courses (Phase 1)
    // - Current courses if submission window is open (Phase 2)
    final filteredData = allData.where((enrollment) {
      final semCode = enrollment['semester_code'];
      if (activeCode == null) return true; // Fallback if no active sem config
      if (semCode != activeCode) return true; // Past hanging course
      return isPhase2Active; // Current course only if deadline passed
    }).toList();

    cache.setMapData('dashboard_box', cacheKey, {'data': filteredData});
    return filteredData;
  } catch (e) {
    if (kDebugMode) debugPrint('[GradeEntry] Pending grades fallback: $e');
    final cached = cache.getMapData('dashboard_box', cacheKey);
    if (cached != null && cached['data'] != null) {
      return List<Map<String, dynamic>>.from(cached['data']);
    }
    return [];
  }
});


class GradeEntryScreen extends ConsumerStatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen> {
  final Map<String, String> _selectedGrades = {};
  bool _isSaving = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(pendingGradesProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  double _getDynamicGradePoint(String grade, List<GradeScale> scale, String semesterCode) {
    final policy = GradeHelper.getPolicyForSemester(semesterCode);
    final entry = scale.where((s) => s.grade == grade && s.policy == policy).firstOrNull 
               ?? scale.where((s) => s.grade == grade).firstOrNull;
    
    if (entry != null) return entry.point;
    
    // Fallback to GradeHelper if not found in DB list
    return GradeHelper.getGradePoint(grade, semesterCode: semesterCode);
  }

  Future<void> _submitGrades(List<Map<String, dynamic>> pendingGrades, List<GradeScale> scale) async {
    if (_selectedGrades.length < pendingGrades.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a grade for all courses.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (final enrollment in pendingGrades) {
        final eid = enrollment['id'];
        final grade = _selectedGrades[eid];
        if (grade == null) continue;

        await Supabase.instance.client
            .from('enrollments')
            .update({
              'grade': grade,
              'grade_points': _getDynamicGradePoint(grade, scale, enrollment['semester_code'] ?? ''),
              'status': 'completed',
            })
            .eq('id', eid);
      }

      ref.invalidate(pendingGradesProvider);
      ref.invalidate(requiresGradeEntryProvider);
      
      if (mounted) {
        // Go back to auth check
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingGradesProvider);
    final scaleAsync = ref.watch(gradeScaleListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Darker slate background
      appBar: AppBar(
        title: const Text('Update Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Force them to stay
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingGradesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF38BDF8),
        backgroundColor: const Color(0xFF1E293B),
        child: scaleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AuthErrorUtils.getFriendlyMessage(e),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
          data: (scale) => pendingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
            error: (e, st) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: 500,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Text(
                  AuthErrorUtils.getFriendlyMessage(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            data: (pending) {
              if (pending.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Text(
                      'No pending grades!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'The absolute deadline for final grades has passed. Please lock in your results to proceed.',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),        
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pending Courses',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final item = pending[index];
                            final courseCode = item['course_code'];
                            final eid = item['id'];
                            final isSelected = _selectedGrades[eid] != null;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF1e293b).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)
                                ] : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : Colors.white12,
                                          child: Icon(
                                            isSelected ? Icons.check_rounded : Icons.menu_book_rounded,
                                            color: isSelected ? const Color(0xFF38BDF8) : Colors.white54,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          courseCode,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedGrades[eid],
                                        hint: Row(
                                          children: const [
                                            Text('Select Grade', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                          ],
                                        ),
                                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF38BDF8)),
                                        dropdownColor: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(12),
                                        items: scale
                                            .where((s) => s.policy == GradeHelper.getPolicyForSemester(item['semester_code'] ?? ''))
                                            .map((s) => s.grade)
                                            .toSet() 
                                            .followedBy(['W', 'I', 'R']) 
                                            .toSet() 
                                            .map((g) {
                                          return DropdownMenuItem(
                                            value: g,
                                            child: Text(
                                              g,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedGrades[eid] = val); 
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isSaving ? null : () => _submitGrades(pending, scale), 
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                )
                              : const Text(
                                  'Confirm & Unlock Dashboard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
