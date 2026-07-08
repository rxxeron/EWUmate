import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/version_utils.dart';
import '../../core/utils/refresh_utils.dart';
import '../../core/services/fcm_service.dart';
import '../../core/utils/course_utils.dart';
import '../semester_progress/semester_progress_repository.dart';



import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/sky_animation.dart';





import 'dashboard_repository.dart';
import 'dashboard_logic.dart';
import '../../core/utils/date_utils.dart' as date_util;





import '../../core/utils/time_utils.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/tutorial_service.dart';
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
import '../../core/providers/feature_flag_provider.dart';
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
  bool _isPlayStoreUser = false;
  String _customApkUrl = "";
  
  // Track tasks currently showing the "Reschedule?" prompt after being marked missed
  final Set<String> _reschedulePromptIds = {};
  
  Map<String, dynamic>? _lastValidScheduleData;
  bool _isSavingAttendance = false;
  List<Map<String, dynamic>> _pendingAttendanceItems = [];
  bool _showAllPendingOnDashboard = false;
  bool _promoBannerDismissed = false;
  Timer? _refreshTimer;
  
  
  
  

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _showDashboardTutorial();
    _checkAndShowDonationPopup();

    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _refreshDashboard(isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _checkAndShowPendingNotifications() {
    if (_loadingInit) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final fcmService = ref.read(fcmServiceProvider);
        fcmService.isDashboardStable = true;
        
        final pending = fcmService.pendingAction;
        if (pending != null) {
          debugPrint("[FCM] Executing pending notification click inside stable Dashboard Screen");
          fcmService.showNotificationPopup(pending.title, pending.body, pending.url);
          fcmService.clearPendingAction();
        }
      }
    });
  }

  Future<void> _refreshDashboard({bool isSilent = false}) async {
    final lastUserId = ref.read(cacheServiceProvider).getLastUserId();
    final effectiveUserId = user?.id ?? lastUserId;
    if (effectiveUserId == null) return;
    
    if (!isSilent && _lastValidScheduleData != null) {
        // Manual refresh: invalidate academic data
        RefreshUtils.refreshAcademicData(ref);
    }

    // PHASE 0: Instant Cache Load (User Request: Show cache first)
    if (_lastValidScheduleData == null) {
       Map<String, dynamic>? cached;
       String? detectedSem;
       
       try {
         final box = Hive.box('dashboard_box');
         for (final key in box.keys) {
           if (key is String && key.startsWith('${effectiveUserId}_') && key.endsWith('_schedule')) {
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

      final lastUserId = ref.read(cacheServiceProvider).getLastUserId();
      final effectiveUserId = user?.id ?? lastUserId;
      if (effectiveUserId == null) {
        if (mounted) setState(() => _loadingInit = false);
        return;
      }

      final profile = ref.read(profileProvider).value;
      final cachedProfile = ref.read(cacheServiceProvider).getCachedProfile(effectiveUserId);
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
                .eq('user_id', effectiveUserId)
                .eq('semester_code', code);
          } catch (_) {
            return [];
          }
        }),
        Future<Map<String, dynamic>?>(() async {
          try {
            return await _supabase
                .from('app_config')
                .select('value, latest_version, download_url')
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
            'enrollment_codes_${effectiveUserId}_$code', 
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
        _checkAndShowPendingNotifications();
        _loadPendingAttendance();
      }
      
      // 4. Check for app updates and show a soft Play Store redirection banner
      try {
        final currentVersion = versionInfo.version;
        if (updateRes != null) {
          // Extract the update_available toggle from the value map (admin config)
          bool isPromptEnabled = true;
          try {
            final val = updateRes['value'];
            if (val is Map) {
              isPromptEnabled = val['update_available'] as bool? ?? true;
            } else if (val is String) {
              final decoded = jsonDecode(val);
              if (decoded is Map) {
                isPromptEnabled = decoded['update_available'] as bool? ?? true;
              }
            }
          } catch (_) {}

          final latestVersion = updateRes['latest_version']?.toString() ?? "";
          if (isPromptEnabled && VersionUtils.isUpdateAvailable(currentVersion, latestVersion)) {
            // Determine if they are a Play Store user
            final installer = versionInfo.installerStore;
            final isPlayStore = installer == 'com.android.vending';
            
            // Extract the download_url from the root level column or value map
            String apkUrl = updateRes['download_url']?.toString() ?? "";
            if (apkUrl.isEmpty) {
              try {
                final val = updateRes['value'];
                if (val is Map) {
                  apkUrl = val['download_url']?.toString() ?? "";
                } else if (val is String) {
                  final decoded = jsonDecode(val);
                  if (decoded is Map) {
                    apkUrl = decoded['download_url']?.toString() ?? "";
                  }
                }
              } catch (_) {}
            }

            if (mounted) {
              setState(() {
                _showUpdateBanner = true;
                _isPlayStoreUser = isPlayStore;
                _customApkUrl = apkUrl;
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
      if (mounted) {
        setState(() => _loadingInit = false);
        _checkAndShowPendingNotifications();
      }
    } catch (e, stack) {
      debugPrint('[Dashboard] Refresh Error: $e\n$stack');
      if (mounted) {
        setState(() => _loadingInit = false);
        _checkAndShowPendingNotifications();
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

  void _checkAndShowDonationPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final hasSeenDashboardTutorial = await TutorialService().hasSeen('dashboard_main');
      if (!hasSeenDashboardTutorial) return; // Wait until onboarding is finished/seen
      
      final cache = ref.read(cacheServiceProvider);
      
      // Load current state
      final Map<String, dynamic> popupState = cache.getMapData('profile_box', 'donation_popup_state') ?? {
        'count': 0,
        'last_shown': '',
      };
      
      final int count = popupState['count'] as int? ?? 0;
      final String lastShown = popupState['last_shown']?.toString() ?? '';
      
      if (count >= 3) return; // Shown exactly 3 times already
      
      final currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (lastShown == currentDateStr) return; // Already shown once today
      
      // Update state in cache
      await cache.setMapData('profile_box', 'donation_popup_state', {
        'count': count + 1,
        'last_shown': currentDateStr,
      });
      
      if (!mounted) return;
      
      // Display premium dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFEC4899),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Support EWUmate's Server",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "EWUmate runs on dedicated servers to keep schedules, grades, and notifications synced. To keep it 100% ad-free and open for everyone, consider contributing a small amount to support hosting costs. Even a tiny cup of tea helps!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Maybe Later",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        context.push('/support-developer'); // Route to support page
                      },
                      child: const Text(
                        "Support",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Future<void> _loadPendingAttendance() async {
    final user = this.user;
    if (user == null || _semesterCode.isEmpty) return;
    
    try {
      final profile = ref.read(profileProvider).value;
      final bool isBiSemester = profile?.track == 'bi';
      
      // Fetch parallel metadata needed
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        // [0] Weekly grid cache
        _supabase
            .from('user_semester_states')
            .select('weekly_grid_cache')
            .eq('user_id', user.id)
            .eq('semester_code', _semesterCode)
            .maybeSingle(),
        // [1] Active semester start/end dates
        _supabase
            .from('active_semester')
            .select('classes_start_date, classes_end_date')
            .eq('track', isBiSemester ? 'bi_semester' : 'tri_semester')
            .maybeSingle(),
        // [2] Academic calendar holidays
        _supabase
            .from(CourseUtils.semesterTable(
              'calendar',
              _semesterCode,
              cycleType: isBiSemester ? 'bi_semester' : 'tri_semester',
            ))
            .select()
            .catchError((_) => []),
        // [3] Exceptions
        _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id),
        // [4] Course progress marks — use fresh network data to avoid stale cache
        ref.read(semesterProgressRepositoryProvider).getFreshProgressData(user.id, _semesterCode),
      ]);
      
      final grid = (results[0] as Map<String, dynamic>?)?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
      final activeSem = results[1] as Map<String, dynamic>?;
      final holidays = results[2] as List;
      final exceptions = results[3] as List;
      final progressData = results[4] as List<Map<String, dynamic>>;
      
      DateTime? startDate = DateTime.tryParse(activeSem?['classes_start_date']?.toString() ?? '');
      DateTime? endDate = DateTime.tryParse(activeSem?['classes_end_date']?.toString() ?? '');
      startDate ??= DateTime.now().subtract(const Duration(days: 45));
      endDate ??= DateTime.now().add(const Duration(days: 45));
      
      // Resolve holiday and cancellation dates
      final Set<String> holidayDates = {};
      for (final ev in holidays) {
        final dateStr = (ev['event_date'] ?? ev['date'] ?? '').toString();
        final title = (ev['title'] ?? ev['name'] ?? '').toString().toLowerCase();
        final isHoliday = ev['is_holiday'] == true ||
            ev['type']?.toString().toLowerCase() == 'holiday' ||
            title.contains('holiday') ||
            title.contains('vacation') ||
            title.contains('break') ||
            title.contains('leave') ||
            title.contains('off day') ||
            title.contains('no classes');
        if (isHoliday && dateStr.isNotEmpty) {
          holidayDates.add(dateStr);
        }
      }
      
      // Map courseCode to their exceptions
      final Map<String, List<Map<String, dynamic>>> exceptionsByCourse = {};
      for (final ex in exceptions) {
        final course = (ex['course_code'] ?? ex['courseCode'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        exceptionsByCourse.putIfAbsent(course, () => []).add(Map<String, dynamic>.from(ex));
      }
      
      // Build weekday mapping
      final Map<String, int> weekdayMap = {
        'Monday': DateTime.monday,
        'Tuesday': DateTime.tuesday,
        'Wednesday': DateTime.wednesday,
        'Thursday': DateTime.thursday,
        'Friday': DateTime.friday,
        'Saturday': DateTime.saturday,
        'Sunday': DateTime.sunday,
      };
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final DateTime endLimit = endDate.isAfter(today) ? today : endDate;
      
      final List<Map<String, dynamic>> pendingItems = [];
      
      // Loop over each enrolled course progress record
      for (final courseMap in progressData) {
        final rawCode = courseMap['course_code']?.toString() ?? '';
        final courseCode = rawCode.toUpperCase().replaceAll(' ', '');
        if (courseCode.isEmpty) continue;
        
        final courseName = courseMap['course_name']?.toString() ?? 'Course';
        
        // Extract schedule template details for this course
        final List<Map<String, String>> scheduledTemplates = [];
        
        for (final entry in grid.entries) {
          final day = entry.key;
          final dayClasses = entry.value;
          if (dayClasses is List) {
            for (final c in dayClasses) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase().replaceAll(' ', '');
              if (code == courseCode) {
                final startTime = (c['startTime'] ?? c['start_time'] ?? '').toString();
                final endTime = (c['endTime'] ?? c['end_time'] ?? '').toString();
                final isLab = CourseUtils.isLab(startTime, endTime, code);
                final type = c['type']?.toString() ?? (isLab ? 'Lab' : 'Theory');
                scheduledTemplates.add({
                  'day': day,
                  'type': type,
                });
              }
            }
          }
        }
        
        if (scheduledTemplates.isEmpty) continue;
        
        // Extract exception cancellations and makeups for this course
        final courseExceptions = exceptionsByCourse[courseCode] ?? [];
        final Set<String> cancelledDates = {};
        final List<Map<String, dynamic>> makeups = [];
        for (final ex in courseExceptions) {
          final dateStr = ex['date']?.toString() ?? '';
          final type = ex['type']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            if (type == 'cancel') {
              cancelledDates.add(dateStr);
            } else if (type == 'makeup' || type == 'manual') {
              makeups.add(ex);
            }
          }
        }
        
        // Generate all scheduled class sessions for this course
        final List<Map<String, dynamic>> classSessions = [];
        final List<int> weekdaysInt = scheduledTemplates.map((t) => weekdayMap[t['day']!]!).toSet().toList();
        
        for (DateTime d = startDate; d.isBefore(endLimit) || d.isAtSameMomentAs(endLimit); d = d.add(const Duration(days: 1))) {
          if (weekdaysInt.contains(d.weekday)) {
            final dayName = DateFormat('EEEE').format(d);
            final dayTemplates = scheduledTemplates.where((t) => t['day'] == dayName).toList();
            for (final temp in dayTemplates) {
              classSessions.add({
                'date': DateTime(d.year, d.month, d.day),
                'type': temp['type'] ?? 'Theory',
              });
            }
          }
        }
        
        final Map<String, dynamic> marksData = courseMap['marks_data'] ?? {};
        final Map<String, dynamic> attendance = marksData['attendance'] ?? {};
        final Map<String, dynamic> datesMap = attendance['dates'] ?? {};
        final Map<String, dynamic> typesMap = attendance['types'] ?? {};
        
        // Insert makeups
        for (final makeup in makeups) {
          final dateStr = makeup['date']?.toString() ?? '';
          final mDate = DateTime.tryParse(dateStr);
          if (mDate != null && (mDate.isBefore(endLimit) || mDate.isAtSameMomentAs(endLimit))) {
            final normalizedDate = DateTime(mDate.year, mDate.month, mDate.day);
            final sessionType = makeup['session_type']?.toString() ?? makeup['sessionType']?.toString() ?? 'Theory';
            
            final exists = classSessions.any((s) => s['date'] == normalizedDate && s['type'] == sessionType);
            if (!exists) {
              classSessions.add({
                'date': normalizedDate,
                'type': sessionType,
              });
            }
          }
        }
        
        // Check if sessions are unmarked
        for (final session in classSessions) {
          final date = session['date'] as DateTime;
          final type = session['type'] as String;
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          
          if (holidayDates.contains(dateStr) || cancelledDates.contains(dateStr)) {
            continue;
          }
          
          final key = '${dateStr}_$type';
          final hasTypedKey = datesMap.containsKey('${dateStr}_Theory') || datesMap.containsKey('${dateStr}_Lab');
          final String? status = datesMap[key]?.toString() ?? (hasTypedKey ? null : datesMap[dateStr]?.toString());
          
          if (status == null || (status != 'joined' && status != 'missed' && status != 'holiday' && status != 'cancelled')) {
            pendingItems.add({
              'course_code': rawCode,
              'course_name': courseName,
              'date': date,
              'dateStr': dateStr,
              'session_type': type,
              'course_map': courseMap,
            });
          }
        }
      }
      
      pendingItems.sort((a, b) {
        final DateTime dateA = a['date'] as DateTime;
        final DateTime dateB = b['date'] as DateTime;
        return dateB.compareTo(dateA);
      });
      
      if (mounted) {
        setState(() {
          _pendingAttendanceItems = pendingItems;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Error loading pending attendance: $e');
    }
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

  Map<String, List<Map<String, dynamic>>> _groupPendingByDate() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in _pendingAttendanceItems) {
      final dateStr = item['dateStr'] as String;
      groups.putIfAbsent(dateStr, () => []).add(item);
    }
    return groups;
  }

  Future<void> _markSingleAttendance(Map<String, dynamic> item, String status) async {
    final user = this.user;
    if (user == null || _semesterCode.isEmpty) return;
    
    setState(() => _isSavingAttendance = true);
    
    try {
      final courseMap = item['course_map'] as Map<String, dynamic>;
      final dateStr = item['dateStr'] as String;
      final sessionType = item['session_type'] as String;
      
      final updatedMap = Map<String, dynamic>.from(courseMap);
      final marksData = Map<String, dynamic>.from(updatedMap['marks_data'] ?? {});
      final attendance = Map<String, dynamic>.from(marksData['attendance'] ?? {});
      final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
      final types = Map<String, dynamic>.from(attendance['types'] ?? {});
      
      final key = '${dateStr}_$sessionType';
      dates[key] = status;
      types[key] = sessionType;
      
      // Legacy fallback
      dates[dateStr] = status;
      types[dateStr] = sessionType;
      
      attendance['dates'] = dates;
      attendance['types'] = types;
      marksData['attendance'] = attendance;
      updatedMap['marks_data'] = marksData;
      
      await ref.read(semesterProgressRepositoryProvider).saveCourseMarks(user.id, _semesterCode, updatedMap);
      
      setState(() {
        _pendingAttendanceItems.removeWhere((i) => 
            i['course_code'] == item['course_code'] && 
            i['dateStr'] == dateStr && 
            i['session_type'] == sessionType);
        _isSavingAttendance = false;
      });
      
      ref.invalidate(semesterProgressDataProvider(_semesterCode));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['course_code']} ($sessionType) marked as ${status == 'joined' ? 'attended' : 'missed'}!'),
          backgroundColor: status == 'joined' ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint('[Dashboard] Error saving single attendance: $e');
      setState(() => _isSavingAttendance = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markMultipleAttendance(List<Map<String, dynamic>> items, String status) async {
    final user = this.user;
    if (user == null || _semesterCode.isEmpty) return;
    
    setState(() => _isSavingAttendance = true);
    
    try {
      final List<Future<void>> saveFutures = [];
      final List<String> codesDatesAndTypes = [];
      
      final progressData = await ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(user.id, _semesterCode);
      
      // Accumulate all modifications by course code to avoid concurrent overwrites
      final Map<String, Map<String, dynamic>> accumulatedCourseUpdates = {};
      
      for (final item in items) {
        final courseCode = (item['course_code'] as String).toUpperCase().replaceAll(' ', '');
        final dateStr = item['dateStr'] as String;
        final sessionType = item['session_type'] as String;
        
        if (!accumulatedCourseUpdates.containsKey(courseCode)) {
          final courseMap = progressData.firstWhere(
            (c) => CourseUtils.areEquivalent(c['course_code'], courseCode),
            orElse: () => <String, dynamic>{},
          );
          if (courseMap.isEmpty) continue;
          accumulatedCourseUpdates[courseCode] = Map<String, dynamic>.from(courseMap);
        }
        
        final updatedMap = accumulatedCourseUpdates[courseCode]!;
        if (updatedMap['marks_data'] == null) {
          updatedMap['marks_data'] = <String, dynamic>{};
        } else {
          updatedMap['marks_data'] = Map<String, dynamic>.from(updatedMap['marks_data']);
        }
        
        final marksData = updatedMap['marks_data'] as Map<String, dynamic>;
        if (marksData['attendance'] == null) {
          marksData['attendance'] = <String, dynamic>{};
        } else {
          marksData['attendance'] = Map<String, dynamic>.from(marksData['attendance']);
        }
        
        final attendance = marksData['attendance'] as Map<String, dynamic>;
        final dates = Map<String, dynamic>.from(attendance['dates'] ?? {});
        final types = Map<String, dynamic>.from(attendance['types'] ?? {});
        
        final key = '${dateStr}_$sessionType';
        dates[key] = status;
        types[key] = sessionType;
        
        // Legacy fallback
        dates[dateStr] = status;
        types[dateStr] = sessionType;
        
        attendance['dates'] = dates;
        attendance['types'] = types;
        marksData['attendance'] = attendance;
        
        codesDatesAndTypes.add('${courseCode}_${dateStr}_$sessionType');
      }
      
      // Save the accumulated updates (one save future per course)
      for (final entry in accumulatedCourseUpdates.entries) {
        saveFutures.add(
          ref.read(semesterProgressRepositoryProvider).saveCourseMarks(user.id, _semesterCode, entry.value)
        );
      }
      
      if (saveFutures.isNotEmpty) {
        await Future.wait(saveFutures);
        
        setState(() {
          _pendingAttendanceItems.removeWhere((i) {
            final key = '${(i['course_code'] as String).toUpperCase().replaceAll(' ', '')}_${i['dateStr']}_${i['session_type']}';
            return codesDatesAndTypes.contains(key);
          });
          _isSavingAttendance = false;
        });
        
        ref.invalidate(semesterProgressDataProvider(_semesterCode));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${codesDatesAndTypes.length} session(s) marked as ${status == 'joined' ? 'attended' : 'missed'}!'),
            backgroundColor: status == 'joined' ? Colors.green : Colors.redAccent,
          ),
        );
      } else {
        setState(() => _isSavingAttendance = false);
      }
    } catch (e) {
      debugPrint('[Dashboard] Error saving multiple attendance: $e');
      setState(() => _isSavingAttendance = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPendingAttendanceWidget(List<Map<String, dynamic>> progressData) {
    if (_pendingAttendanceItems.isEmpty) return const SizedBox.shrink();
    
    final groups = _groupPendingByDate();
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      borderColor: Colors.amberAccent.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fact_check_rounded, color: Colors.amberAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pending Attendance Check",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Mark your attendance for previously held classes.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSavingAttendance)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            )
          else ...[
            ...(() {
              final visibleEntries = _showAllPendingOnDashboard
                  ? groups.entries.toList()
                  : groups.entries.take(2).toList();
              final remainingGroups = groups.length - visibleEntries.length;

              return [
                ...visibleEntries.map((entry) {
                  final items = entry.value;
                  final dateVal = items.first['date'] as DateTime;
                  final formattedDate = DateFormat('EEEE - MMMM d').format(dateVal);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _markMultipleAttendance(items, 'joined'),
                              icon: const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF10B981)),
                              label: const Text(
                                "Tick All",
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.map((item) {
                          final courseCode = item['course_code'] as String;
                          final courseName = item['course_name'] as String;
                          final type = item['session_type'] as String;
                          final isLab = type == 'Lab';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            courseCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isLab ? Colors.orange : const Color(0xFF22D3EE)).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: (isLab ? Colors.orange : const Color(0xFF22D3EE)).withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              type.toUpperCase(),
                                              style: TextStyle(
                                                color: isLab ? Colors.orangeAccent : const Color(0xFF22D3EE),
                                                fontSize: 7,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        courseName,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _markSingleAttendance(item, 'joined'),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _markSingleAttendance(item, 'missed'),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                                        ),
                                        child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                if (remainingGroups > 0)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _showAllPendingOnDashboard = true);
                      },
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.amberAccent, size: 18),
                      label: Text(
                        "Show $remainingGroups more days...",
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else if (_showAllPendingOnDashboard && groups.length > 2)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _showAllPendingOnDashboard = false);
                      },
                      icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.amberAccent, size: 18),
                      label: const Text(
                        "Collapse list",
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (groups.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _markMultipleAttendance(_pendingAttendanceItems, 'joined'),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text(
                        "Mark All as Attended",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ];
            })(),
          ],
        ],
      ),
    );
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

    final progressData = ref.watch(semesterProgressDataProvider(_semesterCode)).valueOrNull ?? [];

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
                          FadeInSlide(delay: const Duration(milliseconds: 50), child: _buildPromoBanner()),
                          FadeInSlide(delay: const Duration(milliseconds: 100), child: _buildAppUpdateBanner()),
                          FadeInSlide(delay: const Duration(milliseconds: 150), child: _buildTransitionBanner()),
                        FadeInSlide(delay: const Duration(milliseconds: 200), child: _buildAdvisingBanner()),
                        FadeInSlide(delay: const Duration(milliseconds: 300), child: _buildExamTimeline()),
                        FadeInSlide(delay: const Duration(milliseconds: 400), child: _buildOverdueDecisionSection()),
                        FadeInSlide(delay: const Duration(milliseconds: 500), child: _buildPendingAttendanceWidget(progressData)),
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

    final String updateUrl = _isPlayStoreUser 
        ? 'https://play.google.com/store/apps/details?id=com.rxxeron.ewumate'
        : (_customApkUrl.isNotEmpty ? _customApkUrl : 'https://play.google.com/store/apps/details?id=com.rxxeron.ewumate');

    final String bannerTitle = _isPlayStoreUser ? 'Update EWUmate!' : 'New APK Update!';
    final String bannerBody = _isPlayStoreUser 
        ? 'A new app version is ready on the Play Store. Tap to update now.'
        : 'A new manual installation APK is ready. Tap to download now.';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      borderColor: Colors.greenAccent.withValues(alpha: 0.4),
      onTap: () => url_launcher.launchUrl(
        Uri.parse(updateUrl),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(bannerBody, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    if (_promoBannerDismissed) return const SizedBox.shrink();

    final bannerAsync = ref.watch(promoBannerProvider);
    return bannerAsync.maybeWhen(
      data: (config) {
        if (config == null) return const SizedBox.shrink();
        final isActive = config['is_active'] == true;
        if (!isActive) return const SizedBox.shrink();

        final imageUrl = config['image_url']?.toString() ?? '';
        final linkUrl = config['link_url']?.toString() ?? '';
        if (imageUrl.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Stack(
            children: [
              GestureDetector(
                onTap: linkUrl.isNotEmpty
                    ? () async {
                        final uri = Uri.tryParse(linkUrl);
                        if (uri != null) {
                          await url_launcher.launchUrl(
                            uri,
                            mode: url_launcher.LaunchMode.externalApplication,
                          );
                        }
                      }
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22D3EE),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              // Dismiss button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _promoBannerDismissed = true),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
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
      child: Material(
        color: Colors.transparent,
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


