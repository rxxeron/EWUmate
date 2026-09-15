import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
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
        SnackBar(
          content: Text('Please select a grade for all courses.', style: GoogleFonts.sora()),
        ),
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
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora())),
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

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Update Results',
          style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Auto-Fetch from Portal",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryCyan, size: 20),
            ),
            onPressed: () async {
              await context.push('/portal-sync');
              ref.invalidate(pendingGradesProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingGradesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primaryCyan,
        backgroundColor: AppColors.surfaceNavyBlue,
        child: scaleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AuthErrorUtils.getFriendlyMessage(e),
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: Colors.redAccent),
              ),
            ),
          ),
          data: (scale) => pendingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
            error: (e, st) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: 500,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Text(
                  AuthErrorUtils.getFriendlyMessage(e),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(color: Colors.white70),
                ),
              ),
            ),
            data: (pending) {
              if (pending.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25), width: 1.5),
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, size: 34, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'All Grades Updated!',
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No courses currently require grade submission.',
                            style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice banner
                      GlassContainer(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Final grade submission deadline has passed. Please record your course grades or auto-sync from the portal to continue.',
                                style: GoogleFonts.sora(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Auto-sync button banner
                      GestureDetector(
                        onTap: () async {
                          await context.push('/portal-sync');
                          ref.invalidate(pendingGradesProvider);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryCyan.withValues(alpha: 0.15),
                                AppColors.secondarySoftBlue.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primaryCyan, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Auto-Fetch Results from Portal',
                                      style: GoogleFonts.sora(
                                        color: AppColors.primaryCyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Automatically import grades with one tap',
                                      style: GoogleFonts.sora(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primaryCyan),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(Icons.pending_actions_rounded, color: AppColors.primaryCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'PENDING COURSES (${pending.length})',
                            style: GoogleFonts.sora(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final item = pending[index];
                            final courseCode = item['course_code'];
                            final eid = item['id'];
                            final isSelected = _selectedGrades[eid] != null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.surfaceNavyBlue.withValues(alpha: 0.85)
                                    : AppColors.surfaceNavyBlue.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryCyan.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryCyan.withValues(alpha: 0.15)
                                                : Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primaryCyan.withValues(alpha: 0.3)
                                                  : Colors.white.withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: Icon(
                                            isSelected ? Icons.check_rounded : Icons.menu_book_rounded,
                                            color: isSelected ? AppColors.primaryCyan : Colors.white54,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              courseCode,
                                              style: GoogleFonts.sora(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              item['semester_code'] ?? 'Semester',
                                              style: GoogleFonts.sora(
                                                color: AppColors.secondaryText,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceNavyBlue,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryCyan
                                              : Colors.white.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedGrades[eid],
                                          hint: Text(
                                            'Select Grade',
                                            style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                                          ),
                                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryCyan),
                                          dropdownColor: AppColors.surfaceNavyBlue,
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
                                                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCyan.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isSaving ? null : () => _submitGrades(pending, scale), 
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Confirm & Unlock Dashboard',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
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
