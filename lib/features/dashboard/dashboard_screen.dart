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
import 'hero_card.dart';
import 'schedule_card.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/widgets/animations/skeleton_loader.dart';
import '../../core/widgets/animations/fade_in_slide.dart';
import '../../core/widgets/onboarding_overlay.dart';
import '../../core/widgets/playstore_review_dialog.dart';

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
  bool _isPlayStoreUser = false;
  String _customApkUrl = "";
  
  // Track tasks currently showing the "Reschedule?" prompt after being marked missed
  final Set<String> _reschedulePromptIds = {};
  
  Map<String, dynamic>? _lastValidScheduleData;
  bool _isSavingAttendance = false;
  List<Map<String, dynamic>> _pendingAttendanceItems = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _showDashboardTutorial();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PlayStoreReviewDialog.checkAndShow(context);
      }
    });

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
        // [4] Course progress marks
        ref.read(semesterProgressRepositoryProvider).getSemesterProgressData(user.id, _semesterCode),
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
                final rawType = c['type']?.toString();
                final String type;
                if (rawType != null && rawType.isNotEmpty && rawType != 'null') {
                  type = rawType;
                } else {
                  final isLab = CourseUtils.isLab(startTime, endTime, code);
                  type = isLab ? 'Lab' : 'Theory';
                }
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
          final String? status = datesMap[key]?.toString() ?? datesMap[dateStr]?.toString();
          
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Dashboard")));
  }
}
