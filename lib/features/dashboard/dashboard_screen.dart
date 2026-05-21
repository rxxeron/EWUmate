import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/version_utils.dart';
import '../../core/utils/refresh_utils.dart';



import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/sky_animation.dart';





import 'dashboard_repository.dart';
import 'dashboard_logic.dart';
import '../../core/utils/date_utils.dart' as date_util;





import '../../core/utils/time_utils.dart';
import '../../core/services/cache_service.dart';
import 'hero_card.dart';
import 'schedule_card.dart';
import 'package:home_widget/home_widget.dart';


import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/skeleton_loader.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/onboarding_overlay.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import '../../core/models/task.dart';
import '../tasks/presentation/widgets/add_task_bottom_sheet.dart';
import '../../core/repositories/task_repository.dart';
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
  
  // Track tasks currently showing the "Reschedule?" prompt after being marked missed
  final Set<String> _reschedulePromptIds = {};
  
  Map<String, dynamic>? _lastValidScheduleData;
  
  
  
  

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _showDashboardTutorial();

    final refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _refreshDashboard(isSilent: true);
    });
  }

  Future<void> _refreshDashboard({bool isSilent = false}) async {
    if (user == null) return;
    
    if (!isSilent && _lastValidScheduleData != null) {
       // Manual refresh: invalidate academic data
       RefreshUtils.refreshAcademicData(ref);
    }

    // PHASE 0: Instant Cache Load (User Request: Show cache first)
    if (_lastValidScheduleData == null) {
      final user = this.user;

      if (user != null) {
         Map<String, dynamic>? cached;
         String? detectedSem;
         
         try {
           final box = Hive.box('dashboard_box');
           for (final key in box.keys) {
             if (key is String && key.startsWith('${user.id}_') && key.endsWith('_schedule')) {
               final data = box.get(key);
               if (data != null) {
                 cached = Map<String, dynamic>.from(jsonDecode(data as String) as Map);
                 // Extract semester code from key (e.g. "bd73b4d7..._summer2026_schedule")
                 final parts = key.split('_');
                 if (parts.length >= 3) {
                   detectedSem = parts[1];
                 }
                 break;
               }
             }
           }
         } catch (e) {
           debugPrint('[Dashboard] Error scanning schedule keys: $e');
         }

         if (cached != null && mounted) {
           setState(() {
             _lastValidScheduleData = cached;
             if (detectedSem != null && _semesterCode.isEmpty) {
               _semesterCode = detectedSem;
             }
             _loadingInit = false; // Show the UI immediately
           });
         } else {
           setState(() => _loadingInit = true);
         }
      }
    }

    try {
      // 1. First ensure we have academic state (needed for the other queries)
      final academicState = await ref.read(academicStateProvider.future);
      if (academicState == null) {
        if (mounted) setState(() => _loadingInit = false);
        return;
      }
      
      final code = academicState.currentSemesterCode;
      final track = academicState.track;
      final nextSemesterCode = academicState.nextSemesterCode;

      final profile = ref.read(profileProvider).value;
      final cachedProfile = ref.read(cacheServiceProvider).getCachedProfile(user!.id);
      final profileUpdatedAt = profile?.updatedAt ?? (cachedProfile != null ? cachedProfile['updated_at'] : null);

      // 2. Fetch Dashboard data, Enrollments, and Update Info in parallel
      final results = await Future.wait<dynamic>([
        ref.read(dashboardRepositoryProvider).getSimplifiedDashboardData(
          code, 
          _effectiveDate, 
          track: track,
          profileUpdatedAt: profileUpdatedAt,
        ),
        Future<List<dynamic>>(() async {
          try {
            return await _supabase
                .from('enrollments')
                .select('course_code')
                .eq('user_id', user!.id)
                .eq('semester_code', code);
          } catch (_) {
            return [];
          }
        }),
        Future<Map<String, dynamic>?>(() async {
          try {
            return await _supabase
                .from('app_config')
                .select('value, latest_version')
                .eq('key', 'update_info')
                .maybeSingle();
          } catch (_) {
            return null;
          }
        }),
        PackageInfo.fromPlatform().catchError(
          (_) => PackageInfo(
            appName: '',
            packageName: '',
            version: '',
            buildNumber: '',
          ),
        ),
      ]);
      
      final dashboardData = results[0] as Map<String, dynamic>;
      final enrollments = results[1] as List;
      try {
        final codes = enrollments.map((e) => e['course_code']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
        if (codes.isNotEmpty) {
          ref.read(cacheServiceProvider).setMapData(
            'dashboard_box', 
            'enrollment_codes_${user!.id}_$code', 
            {'codes': codes}
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[Dashboard] Failed to cache enrollments: $e');
      }
      final updateRes = results[2] as Map<String, dynamic>?;
      final versionInfo = results[3] as PackageInfo;

      if (mounted) {
        setState(() {
          _semesterCode = code;
          _semConfig = academicState.toJson();
          _lastValidScheduleData = dashboardData;
          _tasks = (dashboardData['tasks'] as List? ?? [])
              .map((t) => t as Map<String, dynamic>)
              .toList();
          _loadingInit = false;
        });
        
        _updateHomeWidget(dashboardData);
      }
      
      // 4. Check for app updates and show a soft Play Store redirection banner
      try {
        final currentVersion = versionInfo.version;
        if (updateRes != null) {
          final latestVersion = updateRes['latest_version']?.toString() ?? "";
          if (VersionUtils.isUpdateAvailable(currentVersion, latestVersion)) {
            if (mounted) {
              setState(() {
                _showUpdateBanner = true;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _showUpdateBanner = false;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[Dashboard] Update Banner Check Error: $e');
      }

      // 5. Check Advising Banner for NEXT semester
      _checkAdvisingBanner(nextSemesterCode.toString(), academicState.advisingEndDate);
    } on PostgrestException catch (e) {
      if (e.code == '401' || e.message.contains('JWT expired')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Session refresh delayed. Please check your connection and try again.")),
          );
        }
      }
      if (mounted) setState(() => _loadingInit = false);
    } catch (e, stack) {
      debugPrint('[Dashboard] Refresh Error: $e\n$stack');
      if (mounted) {
        setState(() => _loadingInit = false);
        // Only show snackbar if we do not have any cached data active
        if (_lastValidScheduleData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
          );
        }
      }
    }
  }

  Future<void> _updateHomeWidget(Map<String, dynamic> rawData) async {
    try {
      final processedData = DashboardLogic.processDashboardData(rawData);
      
      final Map<String, dynamic> encodableData = {
        'status': processedData['status'],
        'reason': processedData['reason'],
        'displayDate': processedData['displayDate'],
        'schedule': (processedData['schedule'] as List).map((item) {
          if (item is ScheduleItem) {
            return {
              'courseCode': item.courseCode,
              'courseName': item.courseName,
              'sessionType': item.sessionType,
              'startTime': item.startTime,
              'endTime': item.endTime,
              'room': item.room,
              'faculty': item.faculty,
              'isCancelled': item.isCancelled,
              'isMakeup': item.isMakeup,
            };
          }
          return item;
        }).toList(),
      };

      await HomeWidget.saveWidgetData('schedule_json', jsonEncode(encodableData));
      await HomeWidget.updateWidget(
        androidName: 'ScheduleWidgetProvider',
      );
    } catch (e, stack) {
      debugPrint('[Dashboard] HomeWidget Update Error: $e\n$stack');
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
                onPressed: () => _refreshDashboard(isSilent: false),
              ),
            ],
          ),
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshDashboard(isSilent: false),
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF1A1A2E),
              child: _lastValidScheduleData == null 
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Unable to connect to EWUmate.\nNo offline data found. Pull to refresh.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  )
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
                        FadeInSlide(delay: const Duration(milliseconds: 400), child: _buildOverdueDecisionSection()),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 600), 
                                                    child: _buildScheduleSection(
                            DashboardLogic.processDashboardData(_lastValidScheduleData!),
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

  Widget _buildExamTimeline() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final fiveDaysFromNow = todayStart.add(const Duration(days: 5));

    final upcomingExams = _tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      final type = t['type'] ?? '';
      if (type != 'Mid Exam' && type != 'Final Exam') return false;
      
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
    final dueDate = (DateTime.tryParse(exam['due_date']?.toString() ?? '') ?? DateTime.now()).toLocal();
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

    final isFinal = exam['type'] == 'Final Exam';
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
    final start = startStr is DateTime ? startStr : DateTime.parse(startStr.toString());
    final end = endStr is DateTime ? endStr : DateTime.parse(endStr.toString());

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
      onTap: () => url_launcher.launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=com.rxxeron.ewumate'),
        mode: url_launcher.LaunchMode.externalApplication,
      ),
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
                Text('A new app version is ready on the Play Store. Tap to update now.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
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
                          ? NetworkImage(photoUrl.toString())
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
                      Text(
                        "$greeting,",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.6),
                        ),
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
    final targetDateRaw = data['targetDate'] ?? data['date'];
    final DateTime? targetDate = targetDateRaw is String
        ? DateTime.tryParse(targetDateRaw)
        : targetDateRaw as DateTime?;

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

  Widget _buildOverdueDecisionSection() {
    final now = DateTime.now();
    final overdueTasks = _tasks.where((t) {
      if ((t['is_completed'] ?? false) || (t['is_missed'] ?? false)) return false;
      final dueDate = DateTime.tryParse(t['due_date']?.toString() ?? '');
      return dueDate != null && dueDate.isBefore(now);
    }).toList();

    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text(
                "Task Checkpoint",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...overdueTasks.map((task) => _buildDecisionCard(task)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> task) {
    final taskId = task['id']?.toString() ?? '';
    final isPromptingReschedule = _reschedulePromptIds.contains(taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPromptingReschedule 
              ? Colors.orangeAccent.withOpacity(0.3) 
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isPromptingReschedule
            ? Column(
                key: ValueKey('prompt_$taskId'),
                children: [
                  const Text(
                    "Want to reschedule this task for another time?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _handleFinalMissed(taskId),
                        child: Text(
                          "No, hide it",
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showTaskEditor(task),
                        child: const Text("Yes, Reschedule", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                key: ValueKey('decision_$taskId'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: Colors.orangeAccent, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title']?.toString() ?? 'Untitled Task',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Deadline has passed. What happened?",
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() => _reschedulePromptIds.add(taskId));
                          },
                          child: const Text("Missed", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _markTaskCompleted(taskId),
                          child: const Text("Completed", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _markTaskCompleted(String taskId) async {
    if (user == null) return;
    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(user!.id, taskId, true);
      _refreshDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    }
  }

  void _handleFinalMissed(String taskId) async {
    if (user == null) return;
    try {
      await ref.read(taskRepositoryProvider).updateTaskMissedStatus(user!.id, taskId, true);
      setState(() => _reschedulePromptIds.remove(taskId));
      _refreshDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    }
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


