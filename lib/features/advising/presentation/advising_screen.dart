import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/schedule_repository.dart';
import '../../../core/models/active_semester.dart';
import '../../../core/widgets/glass_kit.dart';
import 'user_academic_providers.dart';
import 'advising_notifier.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/providers/feature_flag_provider.dart';

class AdvisingScreen extends ConsumerStatefulWidget {
  const AdvisingScreen({super.key});

  @override
  ConsumerState<AdvisingScreen> createState() => _AdvisingScreenState();
}

class _AdvisingScreenState extends ConsumerState<AdvisingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Set<String> _hiddenFaculties = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(activeSemesterProvider);
        ref.invalidate(availableAdvisingCoursesProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSemAsync = ref.watch(activeSemesterProvider);
    final advisingState = ref.watch(advisingNotifierProvider);
    final isFeatureOpenAsync = ref.watch(isAdvisingOpenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        title: const Text(
          'Pre-Advising',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeSemesterProvider);
          ref.invalidate(availableAdvisingCoursesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.cyan,
        backgroundColor: const Color(0xFF1E2836),
        child: activeSemAsync.when(
          data: (activeSem) {
            if (activeSem != null) {
              final now = DateTime.now();
              final advStart = activeSem.advisingStartDate;
              final classStart = activeSem.upcomingClassesStartDate;

              // Manual Admin Switch Overrides Automatic Dates
              final isFeatureOpen = isFeatureOpenAsync.value ?? false;
              bool isLocked = !isFeatureOpen;

              if (isLocked) {
                final openDateStr = advStart != null ? DateFormat('MMM dd, yyyy h:mm a').format(advStart.subtract(const Duration(days: 16))) : 'TBA';
                final closeDateStr = classStart != null ? DateFormat('MMM dd, yyyy h:mm a').format(classStart) : 'TBA';
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: _buildLockedView(
                      'Pre-Advising Locked',
                      'The pre-advising section opens on $openDateStr and closes on $closeDateStr.',
                      Icons.lock_clock
                    ),
                  ),
                );
              }
            }

            // If a generation is active, show the tracking view
            if (advisingState.generationId != null) {
              return _buildGenerationOverview(advisingState.generationId!, activeSem);
            }
            return _buildMainPlanningView(activeSem);
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: 500,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Text(
                AuthErrorUtils.getFriendlyMessage(err),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildLockedView(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.cyan.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPlanningView(ActiveSemester? activeSem) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyan,
          labelColor: Colors.cyan,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pick Courses'),
            Tab(text: 'My Drafts'),
            Tab(text: 'Generations'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSelectionTab(activeSem),
              _buildSavedSchedulesTab(),
              _buildGenerationHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionTab(ActiveSemester? activeSem) {
    final availableCoursesAsync = ref.watch(availableAdvisingCoursesProvider);
    final advisingState = ref.watch(advisingNotifierProvider);

    return Column(
      children: [
        // Search & Status Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeSem?.nextSemesterCode != null) ...[
                Text(
                  'Doing Advising for ${activeSem!.nextSemesterCode}',
                  style: const TextStyle(color: Colors.cyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search course code or name...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (advisingState.selectedCourses.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Selected Courses & Faculties',
                  style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: advisingState.selectedCourses.entries.map((entry) {
                      final code = entry.key;
                      final faculties = entry.value;
                      final facultyText = faculties.isEmpty ? 'All' : faculties.join(', ');
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(
                              label: Text(code, style: const TextStyle(fontSize: 12)),
                              onDeleted: () => ref.read(advisingNotifierProvider.notifier).toggleCourse(code),
                              backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                              side: const BorderSide(color: Colors.cyan),
                              labelStyle: const TextStyle(color: Colors.cyan),
                              deleteIconColor: Colors.cyan,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _showFacultySelectionDialog(context, code),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      facultyText, 
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Course List
        Expanded(
          child: availableCoursesAsync.when(
            data: (courses) {
              final queryMatch = _searchQuery.toLowerCase().replaceAll(' ', '');
              final filtered = courses.where((c) {
                final normalizedCode = c.code.toLowerCase().replaceAll(' ', '');
                final normalizedName = c.name.toLowerCase().replaceAll(' ', '');
                return normalizedCode.contains(queryMatch) || normalizedName.contains(queryMatch);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text('No available courses found.', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final course = filtered[index];
                  final isSelected = advisingState.selectedCourses.containsKey(course.code);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      opacity: 0.05,
                      borderRadius: 16,
                      child: ListTile(
                        onTap: () => ref.read(advisingNotifierProvider.notifier).toggleCourse(course.code),
                        title: Text(course.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(course.name, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? Colors.cyan : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  AuthErrorUtils.getFriendlyMessage(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ),

        // Error Display
        if (advisingState.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advisingState.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Action Button
        if (advisingState.selectedCourses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: advisingState.isGenerating ? null : () async {
                  final user = ref.read(currentUserProvider);
                  if (user != null && activeSem != null) {
                    ref.read(advisingNotifierProvider.notifier).startGeneration(
                      userId: user.id,
                      semester: activeSem.nextSemesterCode!,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: advisingState.isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
                label: Text(advisingState.isGenerating ? 'Launching Cloud Task...' : 'Find Best Combinations'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenerationOverview(String genId, ActiveSemester? activeSem) {
    final trackerAsync = ref.watch(generationTrackerProvider(genId));
    final semesterName = activeSem?.nextSemesterCode ?? 'Next Semester';

    return trackerAsync.when(
      data: (data) {
        if (data == null) return const Center(child: Text('Generation session missing.', style: TextStyle(color: Colors.white)));

        final status = data['status'] ?? 'processing';
        final count = data['count'] ?? 0;
        final combinations = data['combinations'] as List? ?? [];

        // If we have some combinations, show them even if still processing
        if (combinations.isNotEmpty) {
           return _buildResultsList(combinations, status, count, semesterName);
        }

        if (status == 'processing') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.cyan),
                  Text(
                  'Doing advising for $semesterName',
                  style: TextStyle(color: Colors.cyan[200], fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Optimizing Schedules...',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have found $count combinations so far.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => ref.read(advisingNotifierProvider.notifier).reset(),
                  child: const Text('Cancel & Start Over', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        }

        if (status == 'failed') {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 24),
                  const Text('No valid combinations found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Try removing one or two courses. This usually happens when time slots overlap heavily.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => ref.read(advisingNotifierProvider.notifier).reset(),
                    style: FilledButton.styleFrom(backgroundColor: Colors.cyan),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Completed View
        return _buildResultsList(combinations, status, count, semesterName);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            AuthErrorUtils.getFriendlyMessage(e),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(List allCombinations, String status, int count, String semesterName) {
    final Set<String> allFaculties = {};
    for (var combo in allCombinations) {
      final sections = combo['sections'] as Map<String, dynamic>? ?? {};
      for (var sec in sections.values) {
        final faculty = (sec['faculty_initials'] ?? sec['faculty'] ?? '').toString();
        if (faculty.isNotEmpty && faculty != 'TBA') {
          allFaculties.add(faculty);
        }
      }
    }

    final filteredCombinations = allCombinations.where((combo) {
      if (_hiddenFaculties.isEmpty) return true;
      final sections = combo['sections'] as Map<String, dynamic>? ?? {};
      for (var sec in sections.values) {
        final faculty = (sec['faculty_initials'] ?? sec['faculty'] ?? '').toString();
        if (_hiddenFaculties.contains(faculty)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    status == 'processing' ? 'Searching...' : '${filteredCombinations.length} Schedules Found',
                    style: const TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Doing advising for $semesterName',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  if (status == 'processing')
                    Text(
                      'Found $count so far...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
              const Spacer(),
              if (status == 'processing')
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan),
                ),
              if (allFaculties.isNotEmpty)
                IconButton(
                  onPressed: () => _showLocalFacultyFilterSheet(context, allFaculties),
                  icon: const Icon(Icons.filter_list, color: Colors.cyan),
                ),
              IconButton(
                onPressed: () {
                  setState(() => _hiddenFaculties.clear());
                  ref.read(advisingNotifierProvider.notifier).reset();
                },
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filteredCombinations.length,
            itemBuilder: (context, index) {
              final combo = filteredCombinations[index];
              final sections = combo['sections'] as Map<String, dynamic>? ?? {};

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GlassContainer(
                  opacity: 0.08,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.cyan,
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            const Text('Schedule Option',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              onPressed: () async {
                                final activeSem = await ref.read(activeSemesterProvider.future);
                                final sem = activeSem?.nextSemesterCode;
                                if (sem == null) return;
                                
                                await ref.read(advisingNotifierProvider.notifier).saveSchedule(
                                  semesterCode: sem,
                                  combination: combo,
                                );
                                
                                // Refresh drafts
                                ref.invalidate(savedSchedulesProvider);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Schedule saved to Drafts!"),
                                      backgroundColor: Colors.cyan,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.bookmark_border,
                                  color: Colors.cyan),
                            ),
                          ],
                        ),
                      ),
                      ...sections.values.map((sec) {
                        // Standardize check for field names (supports multiple variations from scrapers)
                        final code = sec['course_code'] ?? sec['code'] ?? '???';
                        final name = sec['course_name'] ?? sec['name'] ?? '';
                        final faculty = (sec['faculty_initials'] ?? sec['faculty'] ?? 'TBA').toString();

                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Text('$code - ${sec['section']}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(width: 8),
                              _buildCapacityIndicator(sec['capacity']?.toString() ?? ''),
                            ],
                          ),
                          subtitle: Text(_formatSessions(sec['sessions']),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                          trailing: Text(faculty,
                              style: const TextStyle(
                                  color: Colors.cyan, fontSize: 11)),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSessions(dynamic sessions) {
    if (sessions == null || sessions is! List || sessions.isEmpty) return 'No timing available';
    
    final List<String> formatted = [];
    for (final s in sessions) {
      if (s is Map) {
        final day = s['day'] ?? '';
        final start = (s['startTime'] ?? s['start_time'] ?? '').toString();
        final end = (s['endTime'] ?? s['end_time'] ?? '').toString();
        
        if (day.isNotEmpty || start.isNotEmpty) {
          formatted.add('$day $start - $end'.trim());
        }
      }
    }
    
    return formatted.isEmpty ? 'No timing' : formatted.join(' | ');
  }

  Widget _buildSavedSchedulesTab() {
    return ref.watch(savedSchedulesProvider).when(
      data: (saved) {
        if (saved.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text('No drafts saved yet.', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: saved.length,
          itemBuilder: (context, index) {
            final item = saved[index];
            final combo = item['combination_data'] ?? {};
            final sections = combo['sections'] as Map<String, dynamic>? ?? {};
            final sem = item['semester_code'] ?? '???';

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GlassContainer(
                opacity: 0.08,
                borderRadius: 24,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark, color: Colors.cyan, size: 20),
                          const SizedBox(width: 12),
                          Text('Draft for $sem', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final userId = ref.read(currentUserProvider)?.id;
                              if (userId != null) {
                                await ref.read(scheduleRepositoryProvider).deleteDraft(userId, sem);
                                ref.invalidate(savedSchedulesProvider);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          ),
                          Text(
                            (item['created_at'] != null) 
                               ? (item['created_at'] as String).split('T').first 
                               : '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ...sections.values.map((sec) {
                      final code = sec['course_code'] ?? sec['code'] ?? '???';
                      final sessions = sec['sessions'];
                      
                      return ListTile(
                        dense: true,
                        title: Text('$code - ${sec['section']}', style: const TextStyle(color: Colors.white70)),
                        subtitle: Text(_formatSessions(sessions), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AuthErrorUtils.getFriendlyMessage(e),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationHistoryTab() {
    return ref.watch(pastGenerationsProvider).when(
      data: (gens) {
        if (gens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text('No generations found in the last 7 days.', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: gens.length,
          itemBuilder: (context, index) {
            final gen = gens[index];
            final id = gen['id']?.toString() ?? '';
            final status = gen['status']?.toString() ?? 'unknown';
            final count = gen['count'] ?? 0;
            final courses = gen['courses'] as List? ?? [];
            final date = gen['created_at'] != null ? (gen['created_at'] as String).split('T').first : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                opacity: 0.08,
                borderRadius: 16,
                child: ListTile(
                  title: Text(courses.join(', '), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('$date • Status: $status • Found: $count', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.cyan),
                  onTap: () {
                    // Start overview mode using existing functionality
                    ref.read(advisingNotifierProvider.notifier).resumeGeneration(id);
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => const Center(child: Text('Failed to load history', style: TextStyle(color: Colors.red))),
    );
  }

  void _showLocalFacultyFilterSheet(BuildContext context, Set<String> allFaculties) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter by Faculty', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54))
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Deselect faculties to hide their combinations from the results:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: allFaculties.map((faculty) {
                          final isSelected = !_hiddenFaculties.contains(faculty);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(faculty),
                            onSelected: (bool selected) {
                              setSheetState(() {
                                if (selected) {
                                  _hiddenFaculties.remove(faculty);
                                } else {
                                  _hiddenFaculties.add(faculty);
                                }
                              });
                              setState(() {});
                            },
                            selectedColor: Colors.cyan.withValues(alpha: 0.2),
                            checkmarkColor: Colors.cyan,
                            labelStyle: TextStyle(color: isSelected ? Colors.cyan : Colors.white70),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: isSelected ? Colors.cyan : Colors.grey.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showFacultySelectionDialog(BuildContext context, String courseCode) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _FacultySelectionSheet(courseCode: courseCode);
      },
    );
  }

  Widget _buildCapacityIndicator(String capacity) {
    if (capacity.isEmpty || !capacity.contains('/')) {
      return const SizedBox.shrink();
    }
    try {
      final parts = capacity.split('/');
      final enrolled = int.parse(parts[0].trim());
      final total = int.parse(parts[1].trim());
      final bool isFull = (total > 0 && enrolled >= total) || (total == 0 && enrolled > 0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0.5),
        decoration: BoxDecoration(
          color: (isFull ? Colors.redAccent : Colors.cyan).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: (isFull ? Colors.redAccent : Colors.cyan).withOpacity(0.3), width: 0.5),
        ),
        child: Text(
          isFull ? 'Full' : '${total - enrolled} Left',
          style: TextStyle(color: isFull ? Colors.redAccent : Colors.cyan, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}

class _FacultySelectionSheet extends ConsumerWidget {
  final String courseCode;
  
  const _FacultySelectionSheet({required this.courseCode});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultiesAsync = ref.watch(courseFacultiesProvider(courseCode));
    final advisingState = ref.watch(advisingNotifierProvider);
    final selectedFaculties = advisingState.selectedCourses[courseCode] ?? [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Faculty for $courseCode',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54))
            ],
          ),
          const SizedBox(height: 16),
          facultiesAsync.when(
            data: (faculties) {
               if (faculties.isEmpty) {
                 return const Center(child: Text('No faculty options available.', style: TextStyle(color: Colors.grey)));
               }
               return Flexible(
                 child: SingleChildScrollView(
                   child: Wrap(
                     spacing: 8.0,
                     runSpacing: 8.0,
                     children: faculties.map((faculty) {
                       final isSelected = selectedFaculties.contains(faculty);
                       return FilterChip(
                         selected: isSelected,
                         label: Text(faculty),
                         onSelected: (bool selected) {
                           ref.read(advisingNotifierProvider.notifier).toggleFaculty(courseCode, faculty);
                         },
                         selectedColor: Colors.cyan.withValues(alpha: 0.2),
                         checkmarkColor: Colors.cyan,
                         labelStyle: TextStyle(color: isSelected ? Colors.cyan : Colors.white70),
                         backgroundColor: Colors.white.withValues(alpha: 0.05),
                         side: BorderSide(
                           color: isSelected ? Colors.cyan : Colors.grey.withValues(alpha: 0.3),
                         ),
                       );
                     }).toList(),
                   ),
                 ),
               );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
            error: (e, st) => Center(child: Text('Error loading faculties', style: const TextStyle(color: Colors.red))),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


