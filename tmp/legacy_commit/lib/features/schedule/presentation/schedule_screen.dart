import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/dashboard_logic.dart';
import '../../dashboard/dashboard_repository.dart';
import '../../dashboard/exception_repository.dart';
import '../../dashboard/schedule_card.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/providers/academic_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // This is a bridge for child-driven refreshes
    final sem = _semesterCode;
    if (sem != null) _loadDataForSemester(sem);
  }

  @override
  Widget build(BuildContext context) {
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);

    return currentSemAsync.when(
      data: (semCode) {
        if (semCode == null) return const Scaffold(backgroundColor: Color(0xFF16202A), body: Center(child: Text('No active semester found.', style: TextStyle(color: Colors.white))));
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFF16202A),
            appBar: EWUmateAppBar(
              title: "Manage Schedule",
              bottom: const TabBar(
                indicatorColor: Color(0xFF00E5FF),
                labelColor: Color(0xFF00E5FF),
                unselectedLabelColor: Colors.white70,
                indicatorWeight: 3,
                tabs: [Tab(text: "Upcoming"), Tab(text: "Pending Events")],
              ),
            ),
            body: FutureBuilder(
              future: _loadDataForSemester(semCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _loading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                }

                return TabBarView(children: [
                   _buildUpcomingTab(semCode), 
                   _buildPendingActionsTab()
                ]);
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddClassModal(semCode),
              backgroundColor: const Color(0xFF00E5FF),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: Color(0xFF16202A), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))),
      error: (e, _) => Scaffold(backgroundColor: Color(0xFF16202A), body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
    );
  }

  Future<void> _loadDataForSemester(String semCode) async {
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
          final enrollments = await supabase
              .from('enrollments')
              .select('course_code')
              .eq('user_id', user.id)
              .eq('semester_code', semCode);
          for (final row in enrollments as List) {
            final code = row['course_code'].toString().toUpperCase();
            if (!seenCodes.contains(code)) {
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

        final weeksRaw = await repo.getTwoWeekSchedule(semCode);
        
        _twoWeekSchedule = weeksRaw.map((dayData) {
           final date = dayData['date'] as DateTime;
           final processed = DashboardLogic.processDashboardData(dayData);
           final upcomingClasses = List<ScheduleItem>.from(processed['schedule'] ?? []).where((c) => !c.isCancelled).toList();

           return {
              'date': date,
              'dateStr': dayData['dateStr'],
              'isHoliday': dayData['isHoliday'] ?? false,
              'holidayReason': dayData['holidayReason'] ?? '',
              'events': dayData['events'] ?? [],
              'classes': upcomingClasses,
           };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error loading schedule: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showCancelDialog(ScheduleItem item, String dateStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Cancel ${item.courseCode} on $dateStr?\nYou can schedule a makeup later from "Pending Events".',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
             onPressed: () async {
                Navigator.pop(ctx);
                await _exceptionRepo.addCancellation(dateStr, item.courseCode, pendingMakeup: true);
                _loadData();
             },
             child: const Text('Confirm (Skip Makeup)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
             onPressed: () {
                Navigator.pop(ctx);
                _showAddClassModal(_semesterCode!,
                  originalCancelCode: item.courseCode,
                  originalCancelDateStr: dateStr,
                  sessionType: item.sessionType,
                );
             },
             child: const Text('Schedule Makeup', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ]
      )
    );
  }

  void _showDeleteDialog(ScheduleItem item, String dateStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Delete ${item.courseCode} on $dateStr?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exceptionRepo.removeException(item.id);
              _loadData();
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _computeEndTime(TimeOfDay start, bool isLab) {
    final durationMinutes = isLab ? 180 : 90;
    final totalMinutes = start.hour * 60 + start.minute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMin = totalMinutes % 60;
    final endTod = TimeOfDay(hour: endHour, minute: endMin);
    return _formatTimeOfDay(endTod);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  void _showAddClassModal(String semesterCode, {
    String? originalCancelCode,
    String? originalCancelDateStr,
    String? resolveExceptionId,
    String? sessionType,
  }) {
    final isMakeup = originalCancelCode != null || resolveExceptionId != null;

    if (originalCancelCode != null && !_enrolledCourses.any((c) => c['code'] == originalCancelCode)) {
      _enrolledCourses.add({'code': originalCancelCode, 'name': 'Course', 'faculty': '', 'room': ''});
      _enrolledCourses.sort((a, b) => a['code']!.compareTo(b['code']!));
    }

    String currentName = '';
    String currentFaculty = '';
    if (originalCancelCode != null) {
      final meta = _enrolledCourses.firstWhere((c) => c['code'] == originalCancelCode, orElse: () => {});
      currentName = meta['name'] ?? '';
      currentFaculty = meta['faculty'] ?? '';
    }

    String? selectedCourse = originalCancelCode;
    final dateCtrl = TextEditingController(text: originalCancelDateStr ?? '');
    final roomCtrl = TextEditingController();
    
    if (originalCancelCode != null) {
       final meta = _enrolledCourses.firstWhere((c) => c['code'] == originalCancelCode, orElse: () => {});
       if (meta['room'] != null) roomCtrl.text = meta['room']!;
    }
    TimeOfDay? selectedStartTime;
    String computedStartStr = '';
    String computedEndStr = '';
    bool isLab = sessionType == 'Lab';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 15),
                  Center(child: Text(
                    isMakeup ? 'Schedule Makeup' : 'Manual Entry',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  )),
                  const SizedBox(height: 20),

                  const Text('Course', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCourse,
                        hint: const Text('Select Course', style: TextStyle(color: Colors.white38)),
                        dropdownColor: const Color(0xFF1A1A2E),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                        items: _enrolledCourses.map((c) => DropdownMenuItem(
                          value: c['code'],
                          child: Text(c['code']!, style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: isMakeup ? null : (val) {
                          setModalState(() {
                            selectedCourse = val;
                            if (val != null) {
                               final meta = _enrolledCourses.firstWhere((c) => c['code'] == val, orElse: () => {});
                               currentName = meta['name'] ?? '';
                               currentFaculty = meta['faculty'] ?? '';
                               if (meta['room'] != null) roomCtrl.text = meta['room']!;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Session Type', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              isLab = false;
                              if (selectedStartTime != null) {
                                computedEndStr = _computeEndTime(selectedStartTime!, false);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLab ? Colors.cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: !isLab ? Colors.cyanAccent : Colors.white24),
                            ),
                            child: Center(child: Text('Theory (90 min)', style: TextStyle(
                              color: !isLab ? Colors.cyanAccent : Colors.white54,
                              fontWeight: FontWeight.bold, fontSize: 13,
                            ))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              isLab = true;
                              if (selectedStartTime != null) {
                                computedEndStr = _computeEndTime(selectedStartTime!, true);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLab ? Colors.orangeAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isLab ? Colors.orangeAccent : Colors.white24),
                            ),
                            child: Center(child: Text('Lab (3 hrs)', style: TextStyle(
                              color: isLab ? Colors.orangeAccent : Colors.white54,
                              fontWeight: FontWeight.bold, fontSize: 13,
                            ))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Date',
                      labelStyle: const TextStyle(color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.white54, size: 20),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setModalState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Start Time', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedStartTime = picked;
                          computedStartStr = _formatTimeOfDay(picked);
                          computedEndStr = _computeEndTime(picked, isLab);
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white54, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            computedStartStr.isNotEmpty ? computedStartStr : 'Tap to pick start time',
                            style: TextStyle(color: computedStartStr.isNotEmpty ? Colors.white : Colors.white38, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (computedEndStr.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isLab ? Colors.orangeAccent : Colors.cyanAccent).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (isLab ? Colors.orangeAccent : Colors.cyanAccent).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: isLab ? Colors.orangeAccent : Colors.cyanAccent, size: 20),
                          const SizedBox(width: 10),
                          Text('End: $computedEndStr', style: TextStyle(color: isLab ? Colors.orangeAccent : Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(isLab ? '3 hrs' : '90 min', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: roomCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Room / Venue',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (selectedCourse == null || dateCtrl.text.isEmpty || computedStartStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in course, date, and start time.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        if (isMakeup) {
                          if (originalCancelDateStr != null) {
                            await _exceptionRepo.addCancellation(originalCancelDateStr, selectedCourse!, pendingMakeup: false);
                          } else if (resolveExceptionId != null) {
                            await _exceptionRepo.resolvePendingMakeup(resolveExceptionId);
                          }
                          await _exceptionRepo.addMakeupClass(
                            date: dateCtrl.text, courseCode: selectedCourse!, courseName: currentName,
                            startTime: computedStartStr, endTime: computedEndStr, room: roomCtrl.text,
                            faculty: currentFaculty,
                          );
                        } else {
                          await _exceptionRepo.addManualClass(
                            date: dateCtrl.text, courseCode: selectedCourse!, courseName: currentName,
                            startTime: computedStartStr, endTime: computedEndStr, room: roomCtrl.text,
                            faculty: currentFaculty,
                          );
                        }
                        _loadDataForSemester(semesterCode);
                      },
                      child: Text(
                        isMakeup ? 'SAVE MAKEUP' : 'SAVE ENTRY',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingTab(String semCode) {
    if (_twoWeekSchedule.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text("No sessions found.", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text("Semester: $semCode", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _twoWeekSchedule.length,
      itemBuilder: (ctx, idx) {
        final day = _twoWeekSchedule[idx];
        final isHoliday = day['isHoliday'] == true;
        final holidayReason = day['holidayReason']?.toString() ?? '';
        final events = List<Map<String, dynamic>>.from(day['events'] ?? []);
        final classes = day['classes'] as List<ScheduleItem>? ?? [];
        final dateStr = day['dateStr'] as String;
        final headerStr = DateFormat('EEEE - MMMM d').format(day['date'] as DateTime);

        List<Widget> children = [
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(headerStr, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ];

        if (isHoliday) {
          children.add(
            GlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              borderColor: Colors.purpleAccent.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(holidayReason, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                ],
              ),
            )
          );
        }

        for (var ev in events) {
          final title = (ev['title'] ?? ev['name'] ?? '').toString();
          if (title.toLowerCase() == holidayReason.toLowerCase()) continue;
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            )
          );
        }

        for (var c in classes) {
          children.add(
            ScheduleCard(
              item: c,
              compact: true,
              trailing: c.isCancelled
                  ? null
                  : (c.isManual || c.isMakeup)
                      ? TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showDeleteDialog(c, dateStr),
                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      : TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showCancelDialog(c, dateStr),
                          child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
            )
          );
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }

  Widget _buildPendingActionsTab() {
    if (_pendingActions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, color: Colors.greenAccent.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text("Everything is on schedule!", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingActions.length,
      itemBuilder: (ctx, idx) {
        final action = _pendingActions[idx];
        final dateStr = action['date']?.toString() ?? 'Pending Date';
        final code = action['course_code']?.toString() ?? 'Unknown';

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          borderColor: Colors.orangeAccent.withOpacity(0.3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cancelled: $code", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Original Date: $dateStr", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    TextButton(
                      onPressed: () async {
                        await _exceptionRepo.removeException(action['id'].toString());
                        _loadDataForSemester(_semesterCode!);
                      },
                      child: const Text("REVERT", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => _showAddClassModal(_semesterCode!,
                        originalCancelCode: code,
                        resolveExceptionId: action['id'].toString(),
                      ),
                      child: const Text("SCHEDULE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          );
      },
    );
  }
}
