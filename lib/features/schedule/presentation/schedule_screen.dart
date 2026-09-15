import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/repositories/task_repository.dart';
import '../../dashboard/dashboard_logic.dart';
import '../../dashboard/dashboard_repository.dart';
import '../../dashboard/exception_repository.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/utils/course_utils.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/services/cache_service.dart';
import 'widgets/pending_events_tab.dart';
import 'widgets/add_manual_class_sheet.dart';
import 'widgets/schedule_upcoming_tab.dart';
import 'widgets/schedule_past_tab.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final ExceptionRepository _exceptionRepo = ExceptionRepository();
  List<Map<String, dynamic>> _twoWeekSchedule = [];
  List<Map<String, dynamic>> _pendingActions = [];
  List<Map<String, String>> _enrolledCourses = [];
  bool _loading = true;
  String? _semesterCode;
  DateTime _selectedScheduleDate = DateTime.now();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) _loadData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.scheduleKey,
          steps: OnboardingSteps.schedule,
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final sem = _semesterCode;
    if (sem != null) _loadDataForSemester(sem);
  }

  Future<void> _invalidateDashboardCache() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _semesterCode != null) {
      final cacheService = ref.read(cacheServiceProvider);
      final repo = ref.read(dashboardRepositoryProvider);
      final profile = ref.read(userProfileProvider).valueOrNull;
      final safeSem = CourseUtils.cleanSemester(_semesterCode!);

      final now = DateTime.now();
      final effectiveDate = now.hour >= 20
          ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
          : DateTime(now.year, now.month, now.day);

      try {
        final freshData = await repo.getSimplifiedDashboardData(
          _semesterCode!,
          effectiveDate,
          track: profile?.track,
          profileUpdatedAt: profile?.updatedAt,
        );

        final cachePayload = {...freshData, 'date': effectiveDate.toIso8601String()};
        await cacheService.cacheDashboardSchedule(user.id, safeSem, cachePayload);

        final processedData = DashboardLogic.processDashboardData(freshData);
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

        if (kDebugMode) {
          debugPrint('[ScheduleScreen] Successfully updated Cache & Home Screen Widget with fresh schedule.');
        }
      } catch (e) {
        await cacheService.invalidateDashboardSchedule(user.id, safeSem);
        if (kDebugMode) {
          debugPrint('[ScheduleScreen] Failed to update cache. Purged cache: $e');
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);
    final userTasks = ref.watch(allTasksStreamProvider).valueOrNull ?? [];
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return currentSemAsync.when(
      data: (semCode) {
        if (semCode == null) {
          return FullGradientScaffold(
            body: Center(
              child: Text(
                'No active semester found.',
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 14),
              ),
            ),
          );
        }
        
        final track = profile?.track; // Use track hint
        
        return DefaultTabController(
          length: 3,
          child: FullGradientScaffold(
            appBar: EWUmateAppBar(
              title: "Manage Schedule",
              actions: [
                IconButton(
                  tooltip: "Sync Routine from Portal",
                  icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryCyan),
                  onPressed: () async {
                    await context.push('/portal-sync');
                    ref.invalidate(currentSemesterCodeProvider);
                    if (_semesterCode != null) {
                      _loadDataForSemester(_semesterCode!);
                    }
                  },
                ),
              ],
              bottom: TabBar(
                indicatorColor: AppColors.primaryCyan,
                indicatorWeight: 3,
                labelColor: AppColors.primaryCyan,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                unselectedLabelStyle: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: "Upcoming"),
                  Tab(text: "Past 7 Days"),
                  Tab(text: "Pending Events"),
                ],
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentSemesterCodeProvider);
                if (_semesterCode != null) {
                  await _loadDataForSemester(_semesterCode!);
                }
              },
              color: AppColors.primaryCyan,
              backgroundColor: AppColors.surfaceNavyBlue,
              child: FutureBuilder(
                future: _loadDataForSemester(semCode, track: track),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _loading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan));
                  }
  
                  return TabBarView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ScheduleUpcomingTab(
                        semCode: semCode,
                        allTasks: userTasks,
                        twoWeekSchedule: _twoWeekSchedule,
                        selectedScheduleDate: _selectedScheduleDate,
                        onDateSelected: (day) {
                          setState(() {
                            _selectedScheduleDate = day;
                          });
                        },
                        onSyncRoutine: () async {
                          await context.push('/portal-sync');
                          ref.invalidate(currentSemesterCodeProvider);
                          if (_semesterCode != null) {
                            _loadDataForSemester(_semesterCode!);
                          }
                        },
                        onDeleteClass: _showDeleteDialog,
                        onCancelClass: _showCancelDialog,
                      ),
                      SchedulePastTab(
                        twoWeekSchedule: _twoWeekSchedule,
                        allTasks: userTasks,
                        onDeleteClass: _showDeleteDialog,
                        onCancelClass: _showCancelDialog,
                      ),
                      _buildPendingActionsTab(),
                    ],
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddClassModal(semCode),
              backgroundColor: AppColors.primaryCyan,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, color: AppColors.primaryNavy, size: 28),
            ),
          ),
        );
      },
      loading: () => const FullGradientScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      ),
      error: (e, _) => FullGradientScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              AuthErrorUtils.getFriendlyMessage(e),
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadDataForSemester(String semCode, {String? track}) async {
    if (!mounted) return;
    _semesterCode = semCode;
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final repo = ref.read(dashboardRepositoryProvider);

        final List<Map<String, String>> courseData = [];
        final Set<String> seenCodes = {};

        final stateData = await supabase
            .from('user_semester_states')
            .select('weekly_grid_cache')
            .eq('user_id', user.id)
            .eq('semester_code', semCode)
            .maybeSingle();
        final grid = stateData?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
        
        for (final dayClasses in grid.values) {
          if (dayClasses is List) {
            for (final c in dayClasses) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '').toString().toUpperCase();
              if (code.isNotEmpty && !seenCodes.contains(code)) {
                seenCodes.add(code);
                courseData.add({
                  'code': code,
                  'name': (c['courseName'] ?? c['course_name'] ?? '').toString(),
                  'faculty': (c['faculty'] ?? '').toString(),
                  'room': (c['room'] ?? c['room_number'] ?? '').toString(),
                });
              }
            }
          }
        }

        if (courseData.isEmpty) {
          final safeSem = CourseUtils.cleanSemester(semCode);
          final spaceSem = semCode.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
          
          final enrollments = await supabase
              .from('enrollments')
              .select('course_code')
              .eq('user_id', user.id)
              .inFilter('semester_code', [semCode, safeSem, spaceSem, semCode.toLowerCase(), semCode.replaceAll(' ', '')]);
          
          final marks = await supabase
              .from('semester_course_marks')
              .select('course_code')
              .eq('user_id', user.id)
              .inFilter('semester_code', [semCode, safeSem, spaceSem, semCode.toLowerCase(), semCode.replaceAll(' ', '')]);

          final Set<String> allCodes = {
            ...(enrollments as List).map((e) => e['course_code'].toString()),
            ...(marks as List).map((e) => e['course_code'].toString()),
          };

          for (final codeRaw in allCodes) {
            final code = codeRaw.toUpperCase().trim();
            if (code.isNotEmpty && !seenCodes.contains(code)) {
              seenCodes.add(code);
              courseData.add({'code': code, 'name': 'Course', 'faculty': '', 'room': ''});
            }
          }
        }
        
        _enrolledCourses = courseData..sort((a, b) => a['code']!.compareTo(b['code']!));
        
        final allExceptions = await _exceptionRepo.fetchExceptions();
        _pendingActions = allExceptions.where((a) {
          final metadata = a['metadata'] as Map<String, dynamic>? ?? {};
          return a['type'] == 'cancel' && metadata['pendingMakeup'] == true;
        }).toList();

        final weeksRaw = await repo.getTwoWeekSchedule(semCode, track: track, daysBack: 7);
        
        _twoWeekSchedule = weeksRaw.map((dayData) {
           final dateRaw = dayData['date'];
           final DateTime date = dateRaw is String 
               ? (DateTime.tryParse(dateRaw) ?? DateTime.now()) 
               : (dateRaw as DateTime? ?? DateTime.now());
             final processed = DashboardLogic.processDashboardData(dayData);
           return {
              'date': date,
              'dateStr': dayData['dateStr'],
              'isHoliday': dayData['isHoliday'] ?? false,
              'holidayReason': dayData['holidayReason'] ?? '',
              'events': dayData['events'] ?? [],
              'classes': processed['schedule'] ?? [],
           };
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading schedule: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showCancelDialog(ScheduleItem item, String dateStr) {
    final colors = context.ewuColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSubtle),
        ),
        title: Text(
          'Cancel Session',
          style: GoogleFonts.sora(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Cancel ${item.courseCode} on $dateStr?\nYou can schedule a makeup later from "Pending Events".',
          style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Back', style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 13)),
          ),
          TextButton(
             onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _exceptionRepo.addCancellation(dateStr, item.courseCode, pendingMakeup: true);
                  await _invalidateDashboardCache();
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                    );
                  }
                }
             },
             child: Text('Confirm (Skip Makeup)', style: GoogleFonts.sora(color: colors.accentAlert, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(
               backgroundColor: colors.primaryCyan,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             ),
             onPressed: () {
                Navigator.pop(ctx);
                _showAddClassModal(_semesterCode!,
                  originalCancelCode: item.courseCode,
                  originalCancelDateStr: dateStr,
                  sessionType: item.sessionType,
                );
             },
             child: Text('Schedule Makeup', style: GoogleFonts.sora(color: colors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]
      )
    );
  }

  void _showDeleteDialog(ScheduleItem item, String dateStr) {
    final colors = context.ewuColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSubtle),
        ),
        title: Text(
          'Delete Entry',
          style: GoogleFonts.sora(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Delete ${item.courseCode} on $dateStr?',
          style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Back', style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _exceptionRepo.removeException(item.id);
                await _invalidateDashboardCache();
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                  );
                }
              }
            },
            child: Text('Confirm Delete', style: GoogleFonts.sora(color: colors.accentAlert, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAddClassModal(String semesterCode, {
    String? originalCancelCode,
    String? originalCancelDateStr,
    String? resolveExceptionId,
    String? sessionType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddManualClassSheet(
        semesterCode: semesterCode,
        enrolledCourses: _enrolledCourses,
        originalCancelCode: originalCancelCode,
        originalCancelDateStr: originalCancelDateStr,
        resolveExceptionId: resolveExceptionId,
        sessionType: sessionType,
        exceptionRepo: _exceptionRepo,
        onSaved: () async {
          await _invalidateDashboardCache();
          _loadDataForSemester(semesterCode);
        },
      ),
    );
  }

  Widget _buildPendingActionsTab() {
    return PendingEventsTab(
      pendingActions: _pendingActions,
      onRevert: (action) async {
        await _exceptionRepo.removeException(action['id'].toString());
        await _invalidateDashboardCache();
        _loadDataForSemester(_semesterCode!);
      },
      onMakeup: (action) {
        final code = action['course_code']?.toString() ?? 'Unknown';
        _showAddClassModal(
          _semesterCode!,
          originalCancelCode: code,
          resolveExceptionId: action['id'].toString(),
        );
      },
    );
  }
}

