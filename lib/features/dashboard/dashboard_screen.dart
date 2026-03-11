import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/task_model.dart';
import '../../core/models/course_model.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/sky_animation.dart';
import '../tasks/task_repository.dart';
import '../tasks/task_card.dart';
import '../tasks/task_editor_modal.dart';
import '../course_browser/course_repository.dart';
import '../calendar/academic_repository.dart';
import 'dashboard_repository.dart';
import 'dashboard_logic.dart';
import '../../core/utils/date_utils.dart' as date_util;
import '../../core/services/ramadan_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/repositories/app_config_repository.dart';
import '../../core/utils/time_utils.dart';
import 'hero_card.dart';
import 'schedule_card.dart';
import '../results/results_repository.dart';
import '../../core/models/result_models.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/loading_shimmer.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/onboarding_overlay.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllTasks;

  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  final AcademicRepository _academicRepo = AcademicRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final ResultsRepository _resultsRepo = ResultsRepository();

  static const String _timeTba = "Time TBA";
  static const String _venueTba = "Venue TBA";

  User? get user => _supabase.auth.currentUser;
  String _semesterCode = "";
  bool _loadingInit = true;
  List<Task> _tasks = [];
  List<Course> _enrolledCourses = [];
  DateTime? _firstDayOfClasses;
  Map<String, dynamic>? _semConfig;
  Map<String, DateTime> _lastClassDates = {};
  List<Map<String, dynamic>> _userExamSchedules = [];
  bool _showAdvisingBanner = false;
  Map<String, dynamic>? _lastValidScheduleData;
  Object? _lastStreamError;
  Timer? _refreshTimer;

  StreamSubscription? _taskSub;
  StreamSubscription? _profileSub;
  StreamSubscription? _configSub;

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Fast initial load
    _setupStreams(); // Realtime listeners
    SyncService().performFullSync(); // Proactive Sync
    _showDashboardTutorial();

    // FAIL-SAFE: Ensure we stop loading after 5 seconds no matter what
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loadingInit) {
        debugPrint("Dashboard: Fail-safe loader timeout triggered.");
        setState(() => _loadingInit = false);
      }
    });

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _taskSub?.cancel();
    _profileSub?.cancel();
    _configSub?.cancel();
    super.dispose();
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

  Future<void> _loadCachedData() async {
    final cached = OfflineCacheService().getCachedDashboardData();
    if (cached != null && mounted) {
      setState(() {
        _semesterCode = cached['semester_code'] ?? "";
        _loadingInit = false; // Show something ASAP
      });
    }
  }

  void _setupStreams() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Config Stream
    _configSub?.cancel();
    _configSub = _academicRepo.streamActiveSemesterConfig().listen((config) {
      if (mounted) {
        setState(() {
          _semConfig = config;
          _semesterCode = config['current_semester_code'] ?? 'Spring2026';
          _firstDayOfClasses = config['current_semester_start_date'] != null 
              ? DateTime.parse(config['current_semester_start_date']) 
              : null;
        });
        _checkAdvisingBanner(_semesterCode, config);
      }
    });

    // 2. Task Stream
    _taskSub?.cancel();
    _taskSub = _taskRepo.getTasksStream().listen((tasks) {
      if (mounted) {
        setState(() {
          _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        });
      }
    });

    // 3. Profile/Enrollment Stream
    _profileSub?.cancel();
    _profileSub = _courseRepo.streamUserData().listen((userData) async {
       if (!mounted) return;
       
       final enrolledIds = List<String>.from(userData['enrolled_sections'] ?? []);
       List<Course> enrolled = [];
       if (enrolledIds.isNotEmpty) {
          enrolled = await _courseRepo.fetchCoursesByIds(_semesterCode, enrolledIds);
       }

       // Parse Exam Schedules
       final examCacheRaw = userData['exam_dates_cache'];
       final Map<String, dynamic> examCache = examCacheRaw is Map ? Map<String, dynamic>.from(examCacheRaw) : {};
       final List<Map<String, dynamic>> examSchedules = [];
       
       for (var course in enrolled) {
         if (examCache.containsKey(course.code)) {
           final matchData = Map<String, dynamic>.from(examCache[course.code] ?? {});
           examSchedules.add({
             'course_code': course.code,
             'course_name': course.courseName,
             'section': course.section,
             'class_time': matchData['class_time'] ?? (course.startTime != null ? "${course.startTime} - ${course.endTime}" : _timeTba),
             'class_venue': matchData['class_venue'] ?? course.room ?? _venueTba,
             'exam_match': matchData,
           });
         }
       }

       if (mounted) {
         setState(() {
           _enrolledCourses = enrolled;
           _userExamSchedules = examSchedules;
           _loadingInit = false;
         });
       }

       if (enrolledIds.isNotEmpty && await ConnectivityService().isOnline()) {
         ScheduleService().syncUserSchedule(_semesterCode, enrolledIds);
       }
    });
  }

  Future<void> _initDashboard() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      // Parallelize independent data fetching
      final results = await Future.wait<dynamic>([
        _academicRepo.getActiveSemesterConfig().timeout(const Duration(seconds: 4)),
        _taskRepo.fetchTasks().timeout(const Duration(seconds: 4)),
        _courseRepo.fetchUserData().timeout(const Duration(seconds: 4)),
      ]);

      final config = results[0] as Map<String, dynamic>;
      final tasks = results[1] as List<Task>;
      final userData = results[2] as Map<String, dynamic>;

      final code = (config['current_semester_code'] ?? 'Spring2026').toString();

      final enrolledIds =
          List<String>.from(userData['enrolled_sections'] ?? []);
      List<Course> enrolled = [];
      if (enrolledIds.isNotEmpty) {
        enrolled = await _courseRepo.fetchCoursesByIds(
            code, enrolledIds).timeout(const Duration(seconds: 4));
      }

      final startDateStr = config['current_semester_start_date'];
      final startDate = startDateStr != null ? DateTime.parse(startDateStr) : await _academicRepo.getFirstDayOfClasses(code);

      // Parse Exam Schedules & Last Class Dates from Cache
      final examCacheRaw = userData['exam_dates_cache'];
      final Map<String, dynamic> examCache = examCacheRaw is Map ? Map<String, dynamic>.from(examCacheRaw) : {};
      final List<Map<String, dynamic>> examSchedules = [];
      final Map<String, DateTime> lastClassDates = {};
      
      for (var course in enrolled) {
        if (examCache.containsKey(course.code)) {
          final matchDataRaw = examCache[course.code];
          final matchData = matchDataRaw is Map ? Map<String, dynamic>.from(matchDataRaw) : <String, dynamic>{};
          
          String classTime = (course.startTime != null && course.endTime != null && course.startTime!.isNotEmpty) 
              ? "${course.startTime} - ${course.endTime}" 
              : _timeTba;
          String classVenue = (course.room != null && course.room!.isNotEmpty) 
              ? course.room! 
              : _venueTba;

          examSchedules.add({
            'course_code': course.code,
            'course_name': course.courseName,
            'section': course.section,
            'class_time': matchData['class_time'] ?? classTime,
            'class_venue': matchData['class_venue'] ?? classVenue,
            'exam_match': {
              'exam_date': matchData['exam_date'],
              'exam_day': matchData['exam_day'],
              'type': 'Final Exam',
            }
          });
          
          // Optionally parse last_class_date if we added it to cache (we didn't, but that's ok)
        }
      }

      if (mounted) {
        setState(() {
          _semesterCode = code;
          _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          _enrolledCourses = enrolled;
          _firstDayOfClasses = startDate;
          _semConfig = config;
          _userExamSchedules = examSchedules;
          _lastClassDates = lastClassDates;
          _loadingInit = false;
        });
      }

      // Cache for next time
      await OfflineCacheService().cacheDashboardData({
        'semester_code': code,
        // (Other summary info could go here)
      });

      // Background: Re-sync schedule (including holidays) 
      if (enrolledIds.isNotEmpty && await ConnectivityService().isOnline()) {
        ScheduleService().syncUserSchedule(code, enrolledIds);
      }

      // Check if advising banner should be shown (one-time per semester)
      await _checkAdvisingBanner(_semesterCode, _semConfig ?? {});
    } catch (e) {
      debugPrint("Error initializing dashboard: $e");
      try {
        if (mounted) {
          setState(() => _loadingInit = false);
        }
      } catch (_) {}
    }
  }

  Future<void> _refreshTasks() async {
    final tasks = await _taskRepo.fetchTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in"));
    }

    if (_loadingInit) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const LoadingShimmer(width: double.infinity, height: 60, margin: EdgeInsets.only(bottom: 16)),
            const LoadingShimmer(width: double.infinity, height: 40, margin: EdgeInsets.only(top: 20, bottom: 20)),
            const LoadingShimmer(width: double.infinity, height: 180, margin: EdgeInsets.only(bottom: 16)),
            const LoadingShimmer(width: double.infinity, height: 120),
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
                onPressed: _initDashboard,
              ),
            ],
          ),
          _buildHeader(),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _dashboardRepo.getScheduleStream(_semesterCode),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  _lastStreamError = snapshot.error;
                } else if (snapshot.hasData) {
                  _lastValidScheduleData = snapshot.data;
                  _lastStreamError = null;
                }

                if (_lastValidScheduleData == null) {
                  // If we don't have data yet, we wait up to 10 seconds (handled by initState timer)
                  // If SNAPSHOT has error, show it
                  if (snapshot.hasError) {
                    return _buildErrorState("Sync Error: ${snapshot.error}");
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const LoadingShimmer(width: double.infinity, height: 180, margin: EdgeInsets.only(bottom: 16)),
                        const LoadingShimmer(width: double.infinity, height: 180, margin: EdgeInsets.only(bottom: 16)),
                        const LoadingShimmer(width: double.infinity, height: 120),
                        const SizedBox(height: 20),
                        const Text("Syncing your schedule...", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  );
                }

                final processed = DashboardLogic.getScheduleFromCloud(
                  _lastValidScheduleData, 
                  startDate: _firstDayOfClasses,
                  lastClassDates: _lastClassDates,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    await _initDashboard();
                  },
                  color: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeInSlide(delay: const Duration(milliseconds: 50), child: _buildEmergencyNotice()),
                            FadeInSlide(delay: const Duration(milliseconds: 100), child: _buildTransitionBanner()),
                            FadeInSlide(delay: const Duration(milliseconds: 200), child: _buildAdvisingBanner()),
                            FadeInSlide(delay: const Duration(milliseconds: 300), child: _buildRamadanWidget()),
                            FadeInSlide(delay: const Duration(milliseconds: 400), child: _buildMidExamTimelineSection()),
                            FadeInSlide(delay: const Duration(milliseconds: 500), child: _buildExamTimelineSection()),
                            FadeInSlide(delay: const Duration(milliseconds: 600), child: _buildScheduleSection(processed)),
                            const SizedBox(height: 30),
                            FadeInSlide(delay: const Duration(milliseconds: 700), child: _buildTasksSection()),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      if (_lastStreamError != null)
                        Positioned(
                          top: 10,
                          left: 20,
                          right: 20,
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 12,
                            borderColor: Colors.redAccent.withValues(alpha: 0.3),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_problem, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Updating offline... check connection",
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => _lastStreamError = null),
                                  child: const Text("Dismiss", style: TextStyle(fontSize: 10)),
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidExamTimelineSection() {
    // 1. Gather all incomplete midTerm tasks
    final midExams = _tasks.where((t) => t.type == TaskType.midTerm && !t.isCompleted).toList();
    
    if (midExams.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. Sort by due date
    midExams.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 3. Find the very first mid exam date
    final firstExamDate = midExams.first.dueDate;
    
    // 4. Check if we are within the visibility window (3 days before first exam)
    final now = DateTime.now();
    final windowStart = firstExamDate.subtract(const Duration(days: 3));
    
    // Condition: Now must be AFTER the window start, AND we still have incomplete exams in the list
    if (now.isBefore(windowStart) || midExams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Mid Exam Timeline",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...midExams.map((exam) {
          final now = DateTime.now();
          final isToday = date_util.DateUtils.isToday(exam.dueDate);
          final inPast = now.isAfter(exam.dueDate) && !isToday;
          
          // --- EXTRACT VENUE AND TIME FROM SESSIONS ---
          String classTime = _timeTba;
          String classVenue = _venueTba;
          
          final courseNameMatch = exam.courseName.isNotEmpty ? exam.courseName : exam.courseCode;
          
          // Find the corresponding course from enrolled courses
          final course = _enrolledCourses.where((c) => c.code == exam.courseCode).firstOrNull;
          
          if (course != null && course.sessions.isNotEmpty) {
             // 1. Get the Day Character (S, M, T, W, R, F, A) for the exam date
             final dayName = DateFormat('EEEE').format(exam.dueDate).toLowerCase();
             String dayChar = '';
             switch (dayName) {
               case 'sunday':    dayChar = 'S'; break;
               case 'monday':    dayChar = 'M'; break;
               case 'tuesday':   dayChar = 'T'; break;
               case 'wednesday': dayChar = 'W'; break;
               case 'thursday':  dayChar = 'R'; break;
               case 'friday':    dayChar = 'F'; break;
               case 'saturday':  dayChar = 'A'; break;
             }
             
             // 2. Find matching session for that day
             if (dayChar.isNotEmpty) {
                for (var sess in course.sessions) {
                   final sessionType = (sess.type ?? '').toLowerCase();
                   if (sessionType.contains('lab') || sessionType.contains('tutorial')) continue;
                   
                   if (sess.day != null && sess.day!.contains(dayChar)) {
                      if (sess.startTime != null && sess.endTime != null) {
                         classTime = "${sess.startTime} - ${sess.endTime}";
                      }
                      if (sess.room != null) {
                         classVenue = sess.room!;
                      }
                      break;
                   }
                }
             }
             
             // 3. Fallback: if specific day not found, use any available lecture session info
             if (classVenue == _venueTba) {
                 for (var sess in course.sessions) {
                   final sessionType = (sess.type ?? '').toLowerCase();
                   if (sessionType.contains('lab') || sessionType.contains('tutorial')) continue;
                   
                   if (sess.startTime != null && sess.endTime != null && classTime == _timeTba) {
                       classTime = "${sess.startTime} - ${sess.endTime}";
                   }
                   if (sess.room != null && classVenue == _venueTba) {
                       classVenue = sess.room!;
                   }
                   if (classVenue != _venueTba && classTime != _timeTba) break;
                 }
             }
          }
          // ----------------------------------------------

          return GlassContainer(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            borderColor: isToday ? Colors.redAccent.withValues(alpha: 0.4) : Colors.amberAccent.withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.redAccent.withValues(alpha: 0.2) : Colors.amberAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_late, 
                    color: isToday ? Colors.redAccent : Colors.amberAccent
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseNameMatch,
                        style: TextStyle(
                          color: inPast ? Colors.white60 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: inPast ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${DateFormat('d MMMM yyyy').format(exam.dueDate)} • ${DateFormat('EEEE').format(exam.dueDate)}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      classVenue,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      classTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildExamTimelineSection() {
    if (!_isFinalExamSeason() || _userExamSchedules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Final Exam Timeline",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ... _userExamSchedules.map((exam) {
          final match = exam['exam_match'] ?? {};
          return GlassContainer(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            borderColor: Colors.amberAccent.withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment, color: Colors.amberAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['course_name'] ?? exam['course_code'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${match['exam_date']} • ${match['exam_day']}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                    exam['class_venue'] ?? _venueTba,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    exam['class_time'] ?? _timeTba,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 25),
      ],
    );
  }

  // Removed manual _buildAppBar as it's replaced by EWUmateAppBar

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

  Widget _buildEmergencyNotice() {
    final notice = AppConfigRepository().getEmergencyNotice();
    if (notice == null) return const SizedBox.shrink();

    final title = notice['title'] ?? "Important Notice";
    final message = notice['message'] ?? "";
    final type = notice['type'] ?? "info";

    Color bgColor = Colors.blueAccent.withOpacity(0.1);
    Color iconColor = Colors.blueAccent;
    IconData icon = Icons.info_outline_rounded;

    if (type == 'warning') {
      bgColor = Colors.orangeAccent.withOpacity(0.1);
      iconColor = Colors.orangeAccent;
      icon = Icons.warning_amber_rounded;
    } else if (type == 'danger') {
      bgColor = Colors.redAccent.withOpacity(0.1);
      iconColor = Colors.redAccent;
      icon = Icons.error_outline_rounded;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      borderColor: iconColor.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAdvisingBanner(String semCode, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissKey = 'advising_banner_dismissed_$semCode';
      if (prefs.getBool(dismissKey) == true) {
        return;
      }

      final advisingDate = await _academicRepo.getOnlineAdvisingDate(semCode);
      if (advisingDate == null) {
        return;
      }

      final now = DateTime.now();
      if (now.isAfter(advisingDate)) {
        final nextEnrollment = List<String>.from(userData['enrolled_sections_next'] ?? []);
        if (nextEnrollment.isEmpty && mounted) {
          setState(() => _showAdvisingBanner = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking advising banner: $e');
    }
  }

  void _dismissAdvisingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advising_banner_dismissed_$_semesterCode', true);
    if (mounted) setState(() => _showAdvisingBanner = false);
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
                  "Advising Period Open",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Set up your next semester enrollment now.",
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

  bool _isMidExamSeason() {
    final midExams = _tasks.where((t) => t.type == TaskType.midTerm && !t.isCompleted).toList();
    if (midExams.isEmpty) {
      return false;
    }
    
    midExams.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final windowStart = midExams.first.dueDate.subtract(const Duration(days: 3));
    return DateTime.now().isAfter(windowStart);
  }

  bool _isFinalExamSeason() {
    if (_userExamSchedules.isEmpty || _lastClassDates.isEmpty) {
      return false;
    }
    final earliestLastClass = _lastClassDates.values.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().isAfter(earliestLastClass);
  }

  Widget _buildRamadanWidget() {
    return FutureBuilder<RamadanDay?>(
      future: RamadanService.getTodayTimings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final today = snapshot.data!;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 25),
          padding: const EdgeInsets.all(18),
          borderRadius: 22,
          borderColor: Colors.amberAccent.withValues(alpha: 0.3),
          onTap: () => context.push('/ramadan'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mosque, color: Colors.amberAccent, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ramadan Kareem",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Day ${today.day} • Dhaka Timings",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Sehri: ${today.sehri}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Iftar: ${today.iftar}",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<AcademicProfile>(
      stream: ResultsRepository().streamAcademicProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final greeting = TimeUtils.getGreeting();
        
        // Fallback hierarchy: Nickname -> First Name -> Student
        String displayName = profile?.nickname ?? "";
        if (displayName.isEmpty) {
          displayName = profile?.studentName.split(' ').first ?? "";
        }
        if (displayName.isEmpty) {
          displayName = user?.userMetadata?['full_name']?.toString().split(' ').first ?? "Student";
        }

        final photoUrl = profile?.photoUrl ?? user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['photoURL'];

        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          MainShell.scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withValues(alpha: 0.5),
                              Colors.blue.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF1A1A2E),
                          backgroundImage: photoUrl != null && photoUrl.toString().isNotEmpty
                              ? NetworkImage(photoUrl.toString())
                              : null,
                          child: (photoUrl == null || photoUrl.toString().isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.cyanAccent,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$greeting,",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
      },
    );
  }

  Widget _buildScheduleSection(Map<String, dynamic> data) {
    final status = data['status'];
    final reason = data['reason'] ?? "";
    final schedule = data['schedule'] as List<ScheduleItem>? ?? [];
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
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              displayDate,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
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
    return StreamBuilder<List<Task>>(
      stream: _taskRepo.getTasksStream(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? _tasks;
        
        // Refactored logic to reduce cognitive complexity of this section
        final allPending = tasks.where((task) => !task.isCompleted && !task.isMissed).toList();
        final now = DateTime.now();
        final overdue = allPending.where((t) => t.dueDate.isBefore(now)).toList();
        final upcoming = allPending.where((t) => !t.dueDate.isBefore(now)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Tasks",
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
              if (overdue.isNotEmpty) ...[
                 const Padding(
                   padding: EdgeInsets.only(left: 4, bottom: 8),
                   child: Text("Overdue", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                 ),
                 ...overdue.take(3).map((t) => _buildTaskCard(t)),
                 const SizedBox(height: 10),
              ],
              if (upcoming.isNotEmpty) ...[
                 if (overdue.isNotEmpty) const Padding(
                   padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                   child: Text("Upcoming", style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                 ),
                 ...upcoming.take(overdue.isNotEmpty ? 2 : 3).map((t) => _buildTaskCard(t)),
              ],
            ],
          ],
        );
      }
    );
  }

  Widget _buildTaskCard(Task t) {
    return TaskCard(
      task: t,
      onTap: () => _showTaskEditor(t),
      onStatusChange: (comp, miss) async {
        await _taskRepo.updateTaskStatus(t.id, isCompleted: comp, isMissed: miss);
        _refreshTasks();
      },
    );
  }



  void _showTaskEditor(Task item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorModal(
        availableCourses: _enrolledCourses,
        taskToEdit: item,
        onTaskSaved: (t) => _refreshTasks(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync_problem, color: Colors.amberAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Sync Issue",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry Sync"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
