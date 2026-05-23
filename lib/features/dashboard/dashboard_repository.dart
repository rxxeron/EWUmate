import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/course_utils.dart';
import '../../core/services/cache_service.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return DashboardRepository(supabase: Supabase.instance.client, cache: cache);
});

class DashboardRepository {
  final SupabaseClient _supabase;
  final CacheService? _cache;

  DashboardRepository({SupabaseClient? supabase, CacheService? cache})
    : _supabase = supabase ?? Supabase.instance.client,
      _cache = cache;

  /// The New Simplified Dashboard Fetch
  /// 1. Weekly Grid (user_semester_states)
  /// 2. Schedule Exceptions (schedule_exceptions)
  /// 3. Holiday (calendar_[semester])
  /// 4. Top 3 Upcoming Tasks (tasks)
  Future<Map<String, dynamic>> getSimplifiedDashboardData(
    String semesterCode,
    DateTime date, {
    String? track,
    DateTime? profileUpdatedAt,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEEE').format(date);

    // Determine student track (PHRM/LAW vs Standard)
    final programName = track?.toUpperCase() ?? '';
    final bool isBiSemester = programName.contains('PHRM') || programName.contains('LAW') || programName.contains('LLB');

    // Smart Invalidation Cache Check
    if (_cache != null) {
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      final cached = _cache.getCachedDashboardSchedule(user.id, safeSem);
      if (cached != null) {
        final cacheDateStr = cached['dateStr'] as String?;
        if (cacheDateStr == dateStr) {
          final cacheUpdatedAtStr = cached['_cache_updated_at'] as String?;
          if (cacheUpdatedAtStr != null) {
            final cacheUpdatedAt = DateTime.tryParse(cacheUpdatedAtStr);
            if (cacheUpdatedAt != null) {
              bool isStale = false;
              // 24-hour baseline
              if (DateTime.now().difference(cacheUpdatedAt).inHours >= 24) {
                isStale = true;
              }
              // Profile-linked invalidation
              else if (profileUpdatedAt != null && profileUpdatedAt.isAfter(cacheUpdatedAt)) {
                isStale = true;
              }
              
              if (!isStale) {
                debugPrint('[DashboardRepository] Serving strictly from Smart Cache');
                if (cached['date'] != null && cached['date'] is String) {
                  cached['date'] = DateTime.tryParse(cached['date']) ?? date;
                }
                return cached;
              }
            }
          }
        }
      }
    }

    try {
      // 1. Fetch relevant track configuration
      final standardTable = CourseUtils.semesterTable(
        'calendar',
        semesterCode,
        cycleType: 'tri_semester',
      );
      
      // Professional calendar is ONLY needed for PHRM/LLB students (who can take hybrid courses)
      final phrmTable = isBiSemester 
          ? CourseUtils.semesterTable('calendar', semesterCode, cycleType: 'bi_semester')
          : null;

      final results = await Future.wait<dynamic>([
        // [0] Weekly grid cache
        _supabase
            .from('user_semester_states')
            .select('weekly_grid_cache')
            .eq('user_id', user.id)
            .eq('semester_code', semesterCode)
            .maybeSingle(),
        // [1] Date-specific exceptions
        _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id)
            .eq('date', dateStr),
        // [2] Standard (Tri) holiday/swap
        (standardTable != null)
            ? _supabase
                .from(standardTable)
                .select()
                .eq('event_date', dateStr)
                .maybeSingle()
                .catchError((_) => null)
            : Future.value(null),
        // [3] Professional (Bi) holiday/swap
        (phrmTable != null)
            ? _supabase
                .from(phrmTable)
                .select()
                .eq('event_date', dateStr)
                .maybeSingle()
                .catchError((_) => null)
            : Future.value(null),
        // [4] Tasks
        _supabase
            .from('tasks')
            .select()
            .eq('user_id', user.id)
            .or('semester_code.eq.$semesterCode,semester_code.is.null')
            .eq('is_completed', false)
            .gte(
              'due_date',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toUtc()
                  .toIso8601String(),
            )
            .order('due_date', ascending: true)
            .limit(10),
        // [5, 6] Classes End/Start Dates
        _supabase
            .from('active_semester')
            .select('classes_end_date, classes_start_date')
            .eq('track', 'tri_semester')
            .maybeSingle(),
        _supabase
            .from('active_semester')
            .select('classes_end_date, classes_start_date')
            .eq('track', 'bi_semester')
            .maybeSingle(),
      ]);

      var weeklyGrid =
          (results[0] as Map<String, dynamic>?)?['weekly_grid_cache']
              as Map<String, dynamic>? ??
          {};
      final exceptions = List<Map<String, dynamic>>.from(
        results[1] as List? ?? [],
      );
      final standardEvent = results[2] as Map<String, dynamic>?;
      final phrmEvent = results[3] as Map<String, dynamic>?;
      final tasksRaw = List<Map<String, dynamic>>.from(
        results[4] as List? ?? [],
      );

      final stdEndDateStr =
          (results[5] as Map<String, dynamic>?)?['classes_end_date']
              ?.toString();
      final stdStartDateStr =
          (results[5] as Map<String, dynamic>?)?['classes_start_date']
              ?.toString();
      final phrmEndDateStr =
          (results[6] as Map<String, dynamic>?)?['classes_end_date']
              ?.toString();
      final phrmStartDateStr =
          (results[6] as Map<String, dynamic>?)?['classes_start_date']
              ?.toString();

      if (weeklyGrid.isEmpty) {
        try {
          // Normalize the semester code before sync call
          final safeCode = semesterCode.replaceAll(' ', '').replaceAll('_', '');
          debugPrint('[Dashboard] Triggering sync-schedule (No-JWT) for: $safeCode');
          
          try {
            // Manual HTTP call to bypass the automatic JWT/Authorization header injection
            // which was triggering 401 Invalid JWT errors.
            final functionsUrl = '${dotenv.env['SUPABASE_URL']!}/functions/v1';
            final uri = Uri.parse('$functionsUrl/sync-schedule');
            await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
              },
              body: jsonEncode({
                'user_id': user.id,
                'semester_code': safeCode,
              }),
            );
          } catch (e) {
             debugPrint('[Dashboard] Manual sync call failed: $e');
          }
          
          // Wait for the edge function to finish writing to the database
          await Future.delayed(const Duration(seconds: 4));
          
          // Re-fetch with a slight delay if needed, though await should handle it
          final freshState = await _supabase
              .from('user_semester_states')
              .select('weekly_grid_cache')
              .eq('user_id', user.id)
              .eq('semester_code', semesterCode)
              .maybeSingle();
              
          if (freshState != null && freshState['weekly_grid_cache'] != null) {
            weeklyGrid =
                freshState['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
          }
        } catch (e) {
          debugPrint('DashboardRepository: sync-schedule error: $e');
        }
      }

      // 2. Evaluate Standard (Tri) Track Local State
      String stdDay = dayName;
      bool stdIsHoliday = false;
      String stdReason = '';
      if (standardEvent != null) {
        String title = (standardEvent['title'] ?? standardEvent['name'] ?? '')
            .toString()
            .toLowerCase();
        if (title.contains('regular sunday')) {
          stdDay = 'Sunday';
        } else if (title.contains('regular monday'))
          stdDay = 'Monday';
        else if (title.contains('regular tuesday'))
          stdDay = 'Tuesday';
        else if (title.contains('regular wednesday'))
          stdDay = 'Wednesday';
        else if (title.contains('regular thursday'))
          stdDay = 'Thursday';
        else if (_isActualHoliday(standardEvent, title)) {
          stdIsHoliday = true;
          stdReason =
              (standardEvent['title'] ?? standardEvent['name'] ?? 'Holiday')
                  .toString();
        }
      }

      // 3. Evaluate Professional (Bi) Track Local State
      String phrmDay = dayName;
      bool phrmIsHoliday = false;
      String phrmReason = '';
      if (phrmEvent != null) {
        String title = (phrmEvent['title'] ?? phrmEvent['name'] ?? '')
            .toString()
            .toLowerCase();
        if (title.contains('regular sunday')) {
          phrmDay = 'Sunday';
        } else if (title.contains('regular monday'))
          phrmDay = 'Monday';
        else if (title.contains('regular tuesday'))
          phrmDay = 'Tuesday';
        else if (title.contains('regular wednesday'))
          phrmDay = 'Wednesday';
        else if (title.contains('regular thursday'))
          phrmDay = 'Thursday';
        else if (_isActualHoliday(phrmEvent, title)) {
          phrmIsHoliday = true;
          phrmReason = (phrmEvent['title'] ?? phrmEvent['name'] ?? 'Holiday')
              .toString();
        }
      }

      // 4. Build combined classes with Independent Tracking
      List<Map<String, dynamic>> hybridClasses = [];

      bool isStdOver =
          stdEndDateStr != null && dateStr.compareTo(stdEndDateStr) > 0;
      bool isStdNotStarted =
          stdStartDateStr != null && dateStr.compareTo(stdStartDateStr) < 0;
      bool isPhrmOver =
          phrmEndDateStr != null && dateStr.compareTo(phrmEndDateStr) > 0;
      bool isPhrmNotStarted =
          phrmStartDateStr != null && dateStr.compareTo(phrmStartDateStr) < 0;

      // Pull Standard Courses (Non-PHRM/LAW)
      if (!stdIsHoliday && !isStdOver && !isStdNotStarted) {
        final stdClasses = List<Map<String, dynamic>>.from(
          weeklyGrid[stdDay] ?? [],
        );
        hybridClasses.addAll(
          stdClasses.where((c) {
            final code = (c['courseCode'] ?? c['course_code'] ?? '')
                .toString()
                .toUpperCase();
            return !code.startsWith('PHRM') && !code.startsWith('LAW');
          }),
        );
      }

      // Pull Professional Courses (PHRM/LAW)
      if (!phrmIsHoliday && !isPhrmOver && !isPhrmNotStarted) {
        final phClasses = List<Map<String, dynamic>>.from(
          weeklyGrid[phrmDay] ?? [],
        );
        hybridClasses.addAll(
          phClasses.where((c) {
            final code = (c['courseCode'] ?? c['course_code'] ?? '')
                .toString()
                .toUpperCase();
            return code.startsWith('PHRM') || code.startsWith('LAW');
          }),
        );
      }

      hybridClasses.sort(
        (a, b) => (a['startTime'] ?? a['start_time'] ?? '')
            .toString()
            .compareTo((b['startTime'] ?? b['start_time'] ?? '').toString()),
      );

      // 5. Status Calculation: Holiday only if ALL relevant tracks are on holiday
      // Status shown to user in the Banner
      String status = (hybridClasses.isEmpty && exceptions.isEmpty)
          ? 'chill'
          : 'normal';
      String reason = '';

      // If there are NO template classes and the day is a holiday for one of the tracks
      if (hybridClasses.isEmpty) {
        if (phrmIsHoliday && phrmReason.isNotEmpty) {
          status = 'holiday';
          reason = phrmReason;
        } else if (stdIsHoliday && stdReason.isNotEmpty) {
          status = 'holiday';
          reason = stdReason;
        } else if (isPhrmOver && isStdOver) {
          status = 'chill';
          reason = 'The semester classes have officially concluded.';
        } else if (isPhrmNotStarted && isStdNotStarted) {
          status = 'chill';
          reason = 'The semester classes haven\'t officially started yet.';
        }
      }

      final payload = {
        'status': status,
        'reason': reason,
        'template': hybridClasses,
        'exceptions': exceptions,
        'tasks': tasksRaw,
        'date': date,
        'dateStr': dateStr,
      };

      if (_cache != null && weeklyGrid.isNotEmpty) {
        final cachePayload = {...payload, 'date': date.toIso8601String()};
        final safeSem = CourseUtils.cleanSemester(semesterCode);
        _cache.cacheDashboardSchedule(user.id, safeSem, cachePayload);
      }

      return payload;
    } catch (e) {
      if (_cache != null) {
        final safeSem = CourseUtils.cleanSemester(semesterCode);
        final cached = _cache.getCachedDashboardSchedule(user.id, safeSem);
        if (cached != null) {
          debugPrint('[DashboardRepository] Network error, serving from offline cache: $e');
          if (cached['date'] != null && cached['date'] is String) {
            cached['date'] = DateTime.tryParse(cached['date']) ?? date;
          }
          return cached;
        }
      }
      rethrow;
    }
  }

  /// Triggers the sync-schedule Edge Function to regenerate the weekly_grid_cache.
  Future<void> syncWeeklySchedule(String userId) async {
    try {
      debugPrint('[Dashboard] Proactively triggering sync-schedule (No-JWT) for: $userId');
      final functionsUrl = '${dotenv.env['SUPABASE_URL']!}/functions/v1';
      final uri = Uri.parse('$functionsUrl/sync-schedule');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );
    } catch (e) {
      debugPrint('[Dashboard] Proactive sync error: $e');
    }
  }

  bool _isActualHoliday(Map<String, dynamic> event, String lowerTitle) {
    if (event['is_holiday'] == true ||
        event['type']?.toString().toLowerCase() == 'holiday') {
      return true;
    }
    if (lowerTitle.contains('holiday') ||
        lowerTitle.contains('vacation') ||
        lowerTitle.contains('break') ||
        lowerTitle.contains('leave') ||
        lowerTitle.contains('off day') ||
        lowerTitle.contains('no classes')) {
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> _fetchHolidayDirect(
    String semesterCode,
    String dateStr, {
    String? track,
  }) async {
    try {
      String resolvedTrack = track ?? 'tri_semester';
      if (track == null) {
        final config = await _supabase
            .from('active_semester')
            .select('track')
            .eq('current_semester_code', semesterCode)
            .limit(1)
            .maybeSingle();
        if (config != null) resolvedTrack = config['track'];
      }

      final tableName = CourseUtils.semesterTable(
        'calendar',
        semesterCode,
        cycleType: resolvedTrack,
      );
      final res = await _supabase.from(tableName).select();

      if ((res as List).isNotEmpty) {
        final matches = (res as List).where((d) {
          final dDate = (d['event_date'] ?? d['date'] ?? d['date_string'] ?? '')
              .toString();
          return dDate == dateStr;
        }).toList();

        if (matches.isNotEmpty) {
          return matches.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Preserve existing methods for backward compatibility but mark them as potentially cache-heavy/deprecated if needed
  Stream<Map<String, dynamic>> getDashboardDataStream(
    String semesterCode,
    DateTime date, {
    String? track,
  }) {
    // Actually, let's keep it but make it just call the simplified future one-time if user wants no cache
    final controller = StreamController<Map<String, dynamic>>();
    getSimplifiedDashboardData(semesterCode, date, track: track)
        .then((data) {
          if (!controller.isClosed) controller.add(data);
        })
        .catchError((e) {
          if (!controller.isClosed) controller.addError(e);
        });
    return controller.stream;
  }

  /// Legacy compat or direct fetch
  Future<Map<String, dynamic>> getDashboardDataFuture(
    String semesterCode,
    DateTime date, {
    String? track,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEEE').format(date);

    final results = await Future.wait<dynamic>([
      _supabase
          .from('user_semester_states')
          .select('weekly_grid_cache')
          .eq('user_id', user.id)
          .eq('semester_code', semesterCode)
          .maybeSingle(),
      _supabase
          .from('schedule_exceptions')
          .select()
          .eq('user_id', user.id)
          .eq('date', dateStr),
      _fetchHolidayDirect(semesterCode, dateStr, track: track),
    ]);

    final templateData = results[0] as Map<String, dynamic>?;
    final exceptions = List<Map<String, dynamic>>.from(
      results[1] as List? ?? [],
    );
    final holidayData = results[2] as Map<String, dynamic>?;

    String effectiveDayName = dayName;
    bool isHoliday = false;
    String reason = '';

    if (holidayData != null) {
      String title = (holidayData['title'] ?? holidayData['name'] ?? '')
          .toString()
          .toLowerCase();
      if (title.contains('regular sunday classes')) {
        effectiveDayName = 'Sunday';
      } else if (title.contains('regular monday classes')) {
        effectiveDayName = 'Monday';
      } else if (title.contains('regular tuesday classes')) {
        effectiveDayName = 'Tuesday';
      } else if (title.contains('regular wednesday classes')) {
        effectiveDayName = 'Wednesday';
      } else if (title.contains('regular thursday classes')) {
        effectiveDayName = 'Thursday';
      } else if (_isActualHoliday(holidayData, title)) {
        isHoliday = true;
        reason = (holidayData['title'] ?? holidayData['name'] ?? 'Holiday')
            .toString();
      }
    }

    final weeklyGrid =
        templateData?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
    final dayClasses = List<Map<String, dynamic>>.from(
      weeklyGrid[effectiveDayName] ?? [],
    );

    return {
      'status': isHoliday
          ? 'holiday'
          : (dayClasses.isEmpty && exceptions.isEmpty ? 'chill' : 'normal'),
      'reason': reason,
      'template': dayClasses,
      'exceptions': exceptions,
      'date': date,
      'dateStr': dateStr,
    };
  }

  Future<Map<String, dynamic>> getScheduleFuture(String semesterCode) async {
    return getDashboardDataFuture(semesterCode, DateTime.now());
  }

  Future<List<Map<String, dynamic>>> getTwoWeekSchedule(
    String semesterCode, {
    String? track,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final twoWeeksLater = today.add(const Duration(days: 14));
    final startDateStr = DateFormat('yyyy-MM-dd').format(today);
    final endDateStr = DateFormat('yyyy-MM-dd').format(twoWeeksLater);

    try {
      // Determine track
      final programName = track?.toUpperCase() ?? '';
      final bool isBiSemester = programName.contains('PHRM') ||
          programName.contains('LAW') ||
          programName.contains('LLB');

      String? standardTable;
      String? phrmTable;

      if (!isBiSemester) {
        standardTable = CourseUtils.semesterTable(
          'calendar',
          semesterCode,
          cycleType: 'tri_semester',
        );
      } else {
        phrmTable = CourseUtils.semesterTable(
          'calendar',
          semesterCode,
          cycleType: 'bi_semester',
        );
      }

      final results = await Future.wait<dynamic>([
        _supabase
            .from('user_semester_states')
            .select('weekly_grid_cache')
            .eq('user_id', user.id)
            .eq('semester_code', semesterCode)
            .maybeSingle()
            .catchError((e) { debugPrint('Error in state fetch: $e'); return null; }),
        _supabase
            .from('schedule_exceptions')
            .select()
            .eq('user_id', user.id)
            .gte('date', startDateStr)
            .lte('date', endDateStr)
            .catchError((e) { debugPrint('Error in exceptions fetch: $e'); return []; }),
        (standardTable != null)
            ? _supabase
                .from(standardTable)
                .select()
                .gte('event_date', startDateStr)
                .lte('event_date', endDateStr)
                .catchError((e) {
                debugPrint('Error in standardTable fetch: $e');
                return [];
              })
            : Future.value([]),
        (phrmTable != null)
            ? _supabase
                .from(phrmTable)
                .select()
                .gte('event_date', startDateStr)
                .lte('event_date', endDateStr)
                .catchError((e) {
                debugPrint('Error in phrmTable fetch: $e');
                return [];
              })
            : Future.value([]),
        _supabase
            .from('active_semester')
            .select('classes_end_date, classes_start_date')
            .eq('track', 'tri_semester')
            .maybeSingle()
            .catchError((e) { debugPrint('Error in tri end_date fetch: $e'); return null; }),
        _supabase
            .from('active_semester')
            .select('classes_end_date, classes_start_date')
            .eq('track', 'bi_semester')
            .maybeSingle()
            .catchError((e) { debugPrint('Error in bi end_date fetch: $e'); return null; }),
      ]);

      var weeklyGrid =
          (results[0] as Map<String, dynamic>?)?['weekly_grid_cache']
              as Map<String, dynamic>? ??
          {};

      if (weeklyGrid.isEmpty) {
        try {
          final functionsUrl = '${dotenv.env['SUPABASE_URL']!}/functions/v1';
          final uri = Uri.parse('$functionsUrl/sync-schedule');
          await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
            },
            body: jsonEncode({
              'user_id': user.id,
              'semester_code': CourseUtils.cleanSemester(semesterCode),
            }),
          );
          
          final freshState = await _supabase
              .from('user_semester_states')
              .select('weekly_grid_cache')
              .eq('user_id', user.id)
              .eq('semester_code', semesterCode)
              .maybeSingle();
          if (freshState != null && freshState['weekly_grid_cache'] != null) {
            weeklyGrid =
                freshState['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
          }
        } catch (e) {
          debugPrint('[Dashboard] Two-week sync error: $e');
        }
      }

      bool isOverallPhrmUser = false;
      for (var dayClasses in weeklyGrid.values) {
        if (dayClasses is List) {
          for (var c in dayClasses) {
            final code = (c['courseCode'] ?? c['course_code'] ?? '')
                .toString()
                .toUpperCase();
            if (code.startsWith('PHRM') || code.startsWith('LAW')) {
              isOverallPhrmUser = true;
              break;
            }
          }
        }
        if (isOverallPhrmUser) break;
      }

      final exceptionsAll = List<Map<String, dynamic>>.from(
        results[1] as List? ?? [],
      );
      final stdHolidays = List<Map<String, dynamic>>.from(
        results[2] as List? ?? [],
      );
      final phrmHolidays = List<Map<String, dynamic>>.from(
        results[3] as List? ?? [],
      );

      final stdEndDateStr =
          (results[4] as Map<String, dynamic>?)?['classes_end_date']
              ?.toString();
      final stdStartDateStr =
          (results[4] as Map<String, dynamic>?)?['classes_start_date']
              ?.toString();
      final phrmEndDateStr =
          (results[5] as Map<String, dynamic>?)?['classes_end_date']
              ?.toString();
      final phrmStartDateStr =
          (results[5] as Map<String, dynamic>?)?['classes_start_date']
              ?.toString();

      List<Map<String, dynamic>> finalDays = [];

      for (int i = 0; i < 14; i++) {
        final date = today.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayName = DateFormat('EEEE').format(date);

        final dateExceptions = exceptionsAll
            .where((e) => e['date'] == dateStr)
            .toList();
        final stdHolMatches = stdHolidays.where((h) {
          final dDate = (h['event_date'] ?? h['date'] ?? h['date_string'] ?? '')
              .toString();
          return dDate == dateStr;
        }).toList();
        final stdHol = stdHolMatches.isNotEmpty ? stdHolMatches.first : null;

        final phrmHolMatches = phrmHolidays.where((h) {
          final dDate = (h['event_date'] ?? h['date'] ?? h['date_string'] ?? '')
              .toString();
          return dDate == dateStr;
        }).toList();
        final phrmHol = phrmHolMatches.isNotEmpty ? phrmHolMatches.first : null;

        String stdDay = dayName;
        bool stdIsHoliday = false;
        String stdReason = '';
        if (stdHol != null) {
          String title = (stdHol['title'] ?? stdHol['name'] ?? '')
              .toString()
              .toLowerCase();
          if (title.contains('regular sunday')) {
            stdDay = 'Sunday';
          } else if (title.contains('regular monday'))
            stdDay = 'Monday';
          else if (title.contains('regular tuesday'))
            stdDay = 'Tuesday';
          else if (title.contains('regular wednesday'))
            stdDay = 'Wednesday';
          else if (title.contains('regular thursday'))
            stdDay = 'Thursday';
          else if (_isActualHoliday(stdHol, title)) {
            stdIsHoliday = true;
            stdReason = (stdHol['title'] ?? stdHol['name'] ?? 'Holiday')
                .toString();
          }
        }

        String phrmDay = dayName;
        bool phrmIsHoliday = false;
        String phrmReason = '';
        if (phrmHol != null) {
          String title = (phrmHol['title'] ?? phrmHol['name'] ?? '')
              .toString()
              .toLowerCase();
          if (title.contains('regular sunday')) {
            phrmDay = 'Sunday';
          } else if (title.contains('regular monday'))
            phrmDay = 'Monday';
          else if (title.contains('regular tuesday'))
            phrmDay = 'Tuesday';
          else if (title.contains('regular wednesday'))
            phrmDay = 'Wednesday';
          else if (title.contains('regular thursday'))
            phrmDay = 'Thursday';
          else if (_isActualHoliday(phrmHol, title)) {
            phrmIsHoliday = true;
            phrmReason = (phrmHol['title'] ?? phrmHol['name'] ?? 'Holiday')
                .toString();
          }
        } else if (stdHol != null) {
          String title = (stdHol['title'] ?? stdHol['name'] ?? '')
              .toString()
              .toLowerCase();
          bool isSwap =
              title.contains('regular sunday') ||
              title.contains('regular monday') ||
              title.contains('regular tuesday') ||
              title.contains('regular wednesday') ||
              title.contains('regular thursday');
          if (isSwap || _isActualHoliday(stdHol, title)) {
            if (title.contains('regular sunday')) {
              phrmDay = 'Sunday';
            } else if (title.contains('regular monday'))
              phrmDay = 'Monday';
            else if (title.contains('regular tuesday'))
              phrmDay = 'Tuesday';
            else if (title.contains('regular wednesday'))
              phrmDay = 'Wednesday';
            else if (title.contains('regular thursday'))
              phrmDay = 'Thursday';
            else {
              phrmIsHoliday = true;
              phrmReason = (stdHol['title'] ?? stdHol['name'] ?? 'Holiday')
                  .toString();
            }
          }
        }

        List<Map<String, dynamic>> combinedClasses = [];
        bool isStdOver =
            stdEndDateStr != null && dateStr.compareTo(stdEndDateStr) > 0;
        bool isStdNotStarted =
            stdStartDateStr != null && dateStr.compareTo(stdStartDateStr) < 0;
        bool isPhrmOver =
            phrmEndDateStr != null && dateStr.compareTo(phrmEndDateStr) > 0;
        bool isPhrmNotStarted =
            phrmStartDateStr != null && dateStr.compareTo(phrmStartDateStr) < 0;

        List<Map<String, dynamic>> hybridClasses = [];
        if (!stdIsHoliday && !isStdOver && !isStdNotStarted) {
          final stdClasses = List<Map<String, dynamic>>.from(
            weeklyGrid[stdDay] ?? [],
          );
          combinedClasses.addAll(
            stdClasses.where((c) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '')
                  .toString()
                  .toUpperCase();
              return !code.startsWith('PHRM') && !code.startsWith('LAW');
            }),
          );
        }
        if (!phrmIsHoliday && !isPhrmOver && !isPhrmNotStarted) {
          final phClasses = List<Map<String, dynamic>>.from(
            weeklyGrid[phrmDay] ?? [],
          );
          combinedClasses.addAll(
            phClasses.where((c) {
              final code = (c['courseCode'] ?? c['course_code'] ?? '')
                  .toString()
                  .toUpperCase();
              return code.startsWith('PHRM') || code.startsWith('LAW');
            }),
          );
        }

        combinedClasses.sort(
          (a, b) => (a['startTime'] ?? a['start_time'] ?? '')
              .toString()
              .compareTo((b['startTime'] ?? b['start_time'] ?? '').toString()),
        );
        bool isUserPhrmTrack = combinedClasses.any(
          (c) =>
              (c['courseCode'] ?? c['course_code'] ?? '')
                  .toString()
                  .toUpperCase()
                  .startsWith('PHRM') ||
              (c['courseCode'] ?? c['course_code'] ?? '')
                  .toString()
                  .toUpperCase()
                  .startsWith('LAW'),
        );
        bool primaryHoliday = isUserPhrmTrack ? phrmIsHoliday : stdIsHoliday;
        // Apply fallback standard holiday overrides to UI if both are empty
        if (isUserPhrmTrack && !primaryHoliday && stdIsHoliday) {
          bool stdIsActual = _isActualHoliday(
            stdHol!,
            (stdHol['title'] ?? stdHol['name'] ?? '').toString().toLowerCase(),
          );
          if (stdIsActual) {
            primaryHoliday = true;
            phrmReason = (stdHol['title'] ?? stdHol['name'] ?? 'Holiday')
                .toString();
          }
        }
        String primaryReason = isUserPhrmTrack ? phrmReason : stdReason;

        List<Map<String, dynamic>> dailyEvents = [];
        if (stdHol != null) {
          if (isOverallPhrmUser) {
            String title = (stdHol['title'] ?? stdHol['name'] ?? '')
                .toString()
                .toLowerCase();
            bool isSwap =
                title.contains('regular sunday') ||
                title.contains('regular monday') ||
                title.contains('regular tuesday') ||
                title.contains('regular wednesday') ||
                title.contains('regular thursday');
            if (stdIsHoliday || isSwap) {
              dailyEvents.add(stdHol);
            }
          } else {
            dailyEvents.add(stdHol);
          }
        }
        if (phrmHol != null && isOverallPhrmUser) {
          dailyEvents.add(phrmHol);
        }

        finalDays.add({
          'date': date,
          'dateStr': dateStr,
          'isHoliday': primaryHoliday,
          'holidayReason': primaryReason,
          'events': dailyEvents,
          'status': (combinedClasses.isEmpty && dateExceptions.isEmpty)
              ? (primaryHoliday ? 'holiday' : 'chill')
              : 'normal',
          'template': combinedClasses,
          'exceptions': dateExceptions,
        });
      }
      return finalDays;
    } catch (e) {
      return [];
    }
  }
}
