import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';



import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/sky_animation.dart';





import 'dashboard_repository.dart';
import 'dashboard_logic.dart';
import '../../core/utils/date_utils.dart' as date_util;





import '../../core/utils/time_utils.dart';
import 'hero_card.dart';
import 'schedule_card.dart';

import '../../core/services/cache_service.dart';

import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/skeleton_loader.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/onboarding_overlay.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import '../../core/models/task.dart';
import '../tasks/presentation/widgets/add_task_bottom_sheet.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/repositories/course_repository.dart';
import '../../core/providers/scaffold_provider.dart';
import '../../core/providers/academic_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllTasks;

  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  User? get user => _supabase.auth.currentUser;
  String _semesterCode = "";
  bool _loadingInit = true;
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _semConfig;
  bool _showAdvisingBanner = false;
  bool _showUpdateBanner = false;
  
  Map<String, dynamic>? _lastValidScheduleData;
  
  
  
  

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _showDashboardTutorial();

    Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted) _refreshDashboard();
    });
  }

  Future<void> _refreshDashboard() async {
    if (user == null) return;
    
    // 0. Hydrate Instantly from Cache
    final cacheService = ref.read(cacheServiceProvider);
    final cachedData = cacheService.getCachedDashboardSchedule(user!.id);
    
    if (cachedData != null && mounted) {
      setState(() {
        _lastValidScheduleData = Map<String, dynamic>.from(cachedData);
        if (_lastValidScheduleData!['date'] is String) {
          _lastValidScheduleData!['date'] = DateTime.tryParse(_lastValidScheduleData!['date']);
        }
        if (_lastValidScheduleData!['targetDate'] is String) {
          _lastValidScheduleData!['targetDate'] = DateTime.tryParse(_lastValidScheduleData!['targetDate']);
        }
        _tasks = (_lastValidScheduleData!['tasks'] as List? ?? [])
            .map((t) => t as Map<String, dynamic>)
            .toList();
        _loadingInit = false; // Turn off skeleton instantly
      });
    } else {
      if (mounted) setState(() => _loadingInit = true);
    }
    
    try {
      // 1. Get the current active semester & track
      final academicState = await ref.read(academicStateProvider.future);
      if (academicState == null) {
        if (mounted && cachedData == null) setState(() => _loadingInit = false);
        return;
      }
      
      final code = academicState.currentSemesterCode;
      final track = academicState.track;
      final nextSemesterCode = academicState.nextSemesterCode;

      // 2. Fetch the Unified Dashboard Data (LIVE)
      final dashboardData = await ref.read(dashboardRepositoryProvider).getSimplifiedDashboardData(code, _effectiveDate, track: track);
      
      // 3. Save to cache with serialized dates
      final dataToCache = Map<String, dynamic>.from(dashboardData);
      if (dataToCache['date'] is DateTime) {
        dataToCache['date'] = (dataToCache['date'] as DateTime).toIso8601String();
      }
      if (dataToCache['targetDate'] is DateTime) {
        dataToCache['targetDate'] = (dataToCache['targetDate'] as DateTime).toIso8601String();
      }
      cacheService.cacheDashboardSchedule(user!.id, dataToCache);

      // 4. Fetch Enrolled courses
      final enrollments = await _supabase
          .from('enrollments')
          .select('course_code')
          .eq('user_id', user!.id)
          .eq('semester_code', code);
      
      if (mounted) {
        setState(() {
          _semesterCode = code;
          _semConfig = academicState.toJson();
          _lastValidScheduleData = dashboardData;
          _tasks = (dashboardData['tasks'] as List? ?? [])
              .map((t) => t as Map<String, dynamic>)
              .toList();
          _loadingInit = false;
          _isOffline = false;
        });
      }
      
      // 5. Check App Update Config
      try {
        final updateRes = await _supabase.from('app_config').select('value').eq('key', 'update_info').maybeSingle();
        if (updateRes != null) {
          final val = updateRes['value'] as Map<String, dynamic>?;
          if (val != null && val['update_available'] == true) {
             if (mounted) setState(() => _showUpdateBanner = true);
          }
        }
      } catch (e) {
        debugPrint('Update check error: $e');
      }

      // 6. Check Advising Banner for NEXT semester
      if (nextSemesterCode != null) {
        _checkAdvisingBanner(nextSemesterCode.toString(), academicState.advisingEndDate);
      }
    } catch (e, stack) {
      debugPrint("[Dashboard] Background Refresh Offline/Error: $e");
      if (mounted) {
        setState(() {
          _loadingInit = false;
          _isOffline = true;
        });
      }
    }
  }

  void _showDashboardTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingOverlay.show(
        context: context,
        featureKey: 'dashboard_main',
        steps: [
          const OnboardingStep(
            title: "Your Academic Hub",
            description: "Welcome to your new dashboard! Here you'll find your classes, deadlines, and important university updates.",
            icon: Icons.dashboard_rounded,
          ),
          const OnboardingStep(
            title: "Live Schedule",
            description: "Your daily classes appear here automatically. We'll even remind you 15 minutes before they start!",
            icon: Icons.calendar_today_rounded,
          ),
          const OnboardingStep(
            title: "The Floating Pulse",
            description: "Check the sidebar for quick access to your tasks, CGPA projections, and the Advising Planner.",
            icon: Icons.bubble_chart_rounded,
          ),
        ],
      );
    });
  }

  DateTime get _effectiveDate {
    final now = DateTime.now();
    if (now.hour >= 20) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _checkAdvisingBanner(String nextSemCode, dynamic advisingEndObj) async {
    try {
        final prefs = await SharedPreferences.getInstance();
      final dismissKey = 'advising_banner_dismissed_$nextSemCode';
      if (prefs.getBool(dismissKey) == true) {
        return;
      }

      final advisingDate = advisingEndObj != null 
          ? DateTime.tryParse(advisingEndObj.toString())
          : null;
          
      if (advisingDate == null) {
        return;
      }

      final now = DateTime.now();
      if (now.isAfter(advisingDate)) {
        final user = _supabase.auth.currentUser;
        if (user == null) return;
        
        List dynamicRes = [];
        try {
          dynamicRes = await _supabase
              .from('enrollments')
              .select('id')
              .eq('user_id', user.id)
              .eq('semester_code', nextSemCode)
              .eq('status', 'upcoming')
              .limit(1);
        } catch (_) {
          // Fallback if issues
          dynamicRes = [];
        }

        if (dynamicRes.isEmpty && mounted) {
          setState(() => _showAdvisingBanner = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking advising banner: $e');
    }
  }

  void _dismissAdvisingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final nextSem = _semConfig?['next_semester_code'] ?? _semesterCode;
    await prefs.setBool('advising_banner_dismissed_$nextSem', true);
    if (mounted) setState(() => _showAdvisingBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in"));
    }

    if (_loadingInit) {
      return Container(
        color: Colors.transparent,
        child: Column(
          children: [
            const EWUmateAppBar(title: "EWUmate", showMenu: true),
            const SkeletonLoader(width: double.infinity, height: 100, margin: EdgeInsets.all(20), borderRadius: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(width: 150, height: 24),
                  SkeletonLoader(width: 100, height: 18),
                ],
              ),
            ),
            const SkeletonLoader(width: double.infinity, height: 140, margin: EdgeInsets.all(20), borderRadius: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SkeletonLoader(width: 150, height: 24),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: const [
                    SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                    SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                    SkeletonLoader(width: double.infinity, height: 80, margin: EdgeInsets.only(bottom: 12), borderRadius: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          EWUmateAppBar(
            title: "EWUmate",
            showMenu: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _refreshDashboard,
              ),
            ],
          ),
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF1A1A2E),
              child: _lastValidScheduleData == null 
                ? const Center(child: SkeletonLoader(width: double.infinity, height: 200))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          FadeInSlide(delay: const Duration(milliseconds: 100), child: _buildAppUpdateBanner()),
                          FadeInSlide(delay: const Duration(milliseconds: 150), child: _buildTransitionBanner()),
                        FadeInSlide(delay: const Duration(milliseconds: 200), child: _buildAdvisingBanner()),
                        FadeInSlide(delay: const Duration(milliseconds: 300), child: _buildExamTimeline()),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 600), 
                                                    child: _buildScheduleSection(
                            DashboardLogic.processDashboardData(
                              _lastValidScheduleData!,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        FadeInSlide(delay: const Duration(milliseconds: 700), child: _buildTasksSection()),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }



  // Removed manual _buildAppBar as it's replaced by EWUmateAppBar

  Widget _buildExamTimeline() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final fiveDaysFromNow = todayStart.add(const Duration(days: 5));

    final upcomingExams = _tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      final type = t['type'] ?? '';
      if (type != 'midTerm' && type != 'finalExam') return false;
      
      final dueDate = DateTime.tryParse(t['due_date']?.toString() ?? '');
      if (dueDate == null) return false;
      
      return dueDate.isAfter(todayStart.subtract(const Duration(days: 1))) && 
             dueDate.isBefore(fiveDaysFromNow.add(const Duration(days: 1)));
    }).toList();

    if (upcomingExams.isEmpty) return const SizedBox.shrink();

    upcomingExams.sort((a, b) {
      final dateA = DateTime.tryParse(a['due_date']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['due_date']?.toString() ?? '') ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.av_timer_rounded, color: Color(0xFFF43F5E)),
            const SizedBox(width: 12),
            const Text(
              "Exam Timeline",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...upcomingExams.map((exam) => _buildExamCard(exam)),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final dueDate = DateTime.tryParse(exam['due_date']?.toString() ?? '') ?? DateTime.now();
    final diff = dueDate.difference(DateTime.now());
    final String countdown;
    if (diff.inDays > 0) {
      countdown = "In ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}";
    } else if (diff.inHours > 0) {
      countdown = "In ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}";
    } else if (diff.inMinutes > 0) {
      countdown = "In ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}";
    } else {
      countdown = "Today";
    }

    final isFinal = exam['type'] == 'finalExam';
    final color = isFinal ? Colors.pinkAccent : Colors.orangeAccent;
    final label = isFinal ? "FINAL EXAM" : "MIDTERM";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTaskEditor(exam),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.assignment_late_rounded, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam['course_code']?.toString() ?? 'Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, h:mm a').format(dueDate),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  countdown,
                  style: TextStyle(
                    color: countdown == "Today" ? const Color(0xFFF43F5E) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionBanner() {
    if (_semConfig == null) {
      return const SizedBox.shrink();
    }

    final startStr = _semConfig!['grade_submission_start'];
    final endStr = _semConfig!['grade_submission_deadline'];
    if (startStr == null || endStr == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final start = DateTime.parse(startStr);
    final end = DateTime.parse(endStr);

    // Only show IF we are past the start of the submission window
    if (now.isBefore(start) || now.isAfter(end.add(const Duration(days: 1)))) {
      return const SizedBox.shrink();
    }

    final deadlineFormat = DateFormat('MMMM d, yyyy').format(end);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      borderColor: Colors.blueAccent.withValues(alpha: 0.3),
      onTap: () => context.push('/gatekeeper'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Semester Hand-off",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Grade submission deadline is $deadlineFormat. Submit now to switch semester.",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildAppUpdateBanner() {
    if (!_showUpdateBanner) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      borderColor: Colors.greenAccent.withValues(alpha: 0.4),
      onTap: () => context.push('/feedback'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_alt_rounded, color: Colors.greenAccent, size: 28),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update EWUmate!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('A new app version is ready. Tap to download now.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildAdvisingBanner() {
    if (!_showAdvisingBanner) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      borderColor: Colors.orangeAccent.withValues(alpha: 0.3),
      onTap: () => context.push('/next-semester'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.orangeAccent, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Next Semester Classes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Put in the sections you successfully advised into.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            onPressed: _dismissAdvisingBanner,
          ),
        ],
      ),
    );
  }




  Widget _buildHeader() {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final greeting = TimeUtils.getGreeting();

    String displayName = profile?.nickname ?? "";
    if (displayName.isEmpty) {
      displayName = profile?.fullName?.split(' ').first ?? "";
    }
    if (displayName.isEmpty) {
      displayName = user?.userMetadata?['full_name']?.toString().split(' ').first ?? "Student";
    }

    final photoUrl = profile?.photoUrl ?? user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['photoURL'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF22D3EE).withOpacity(0.5),
                          const Color(0xFF0891B2).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF0F172A),
                      backgroundImage: photoUrl != null && photoUrl.toString().isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl.toString())
                          : null,
                      child: (photoUrl == null || photoUrl.toString().isEmpty)
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF22D3EE),
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "$greeting,",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isOffline) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 10),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "OFFLINE",
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 75, height: 75, child: SkyAnimationWidget()),
        ],
      ),
    );
  }


  Widget _buildScheduleSection(Map<String, dynamic> data) {
    final status = data['status'];
    final reason = data['reason'] ?? "";
    final schedule = (data['schedule'] as List?)?.cast<ScheduleItem>() ?? [];
    final targetDate = data['targetDate'] as DateTime?;
 
    final isToday = targetDate != null && date_util.DateUtils.isToday(targetDate);
    final isTomorrow = targetDate != null && date_util.DateUtils.isTomorrow(targetDate);
    
    String title = targetDate != null ? DateFormat('EEEE').format(targetDate) : "Schedule";
    if (isToday) title = "Today's Schedule";
    if (isTomorrow) title = "Tomorrow's Schedule";
    
    final displayDate = targetDate != null ? DateFormat('EEEE, MMM d').format(targetDate) : "";
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayDate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (status == 'holiday')
          HeroCard(
            iconInfo: "🎉",
            title: "Holiday",
            subtitle: reason.isNotEmpty ? reason : "It's a holiday! Enjoy your day off.",
            color: Colors.amberAccent,
          )
        else if (status == 'chill')
          HeroCard(
            iconInfo: "☕",
            title: "Chill Mode",
            subtitle: reason.isNotEmpty ? reason : "No classes scheduled.",
            color: Colors.purpleAccent,
          )
        else if (schedule.isEmpty)
          HeroCard(
            iconInfo: "✨",
            title: isToday ? "All Clear" : "Nothing Found",
            subtitle: isToday ? "No more classes for today." : "No classes scheduled for this day.",
            color: Colors.greenAccent,
          )
        else
          ...schedule.map((item) => ScheduleCard(item: item)),
      ],
    );
  }

  Widget _buildTasksSection() {
    final allPending = _tasks.where((task) {
      if ((task['is_completed'] ?? false) || (task['is_missed'] ?? false)) return false;
      return true;
    }).take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming Tasks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: widget.onSeeAllTasks ?? () => context.push('/tasks'),
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (allPending.isEmpty)
          const HeroCard(
            iconInfo: Icons.task_alt,
            title: "All Done!",
            subtitle: "No pending tasks.",
            color: Colors.blueAccent,
            iconMode: true,
          )
        else ...[
          // Simply render the tasks fetched during refresh
          ...allPending.take(3).map((t) => _buildCard(t)),
        ],
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final dueDateStr = t['due_date']?.toString();
    final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
    final formattedDue = dueDate != null
        ? DateFormat('MMM d, h:mm a').format(dueDate.toLocal())
        : 'No due date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assignment_rounded, color: Color(0xFF22D3EE), size: 20),
        ),
        title: Text(
          t['title']?.toString() ?? 'Untitled Task', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
        ),
        subtitle: Text(
          "${t['course_code']?.toString() ?? 'General'} • $formattedDue",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () => _showTaskEditor(t),
      ),
    );
  }



  void _showTaskEditor(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaskBottomSheet(
          existingTask: Task.fromJson(item),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshDashboard();
      }
    });
  }
}
