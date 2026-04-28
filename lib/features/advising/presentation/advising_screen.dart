import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/schedule_repository.dart';
import '../../../core/models/active_semester.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/providers/supabase_provider.dart';
import 'user_academic_providers.dart';
import 'advising_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSemAsync = ref.watch(activeSemesterProvider);
    final advisingState = ref.watch(advisingNotifierProvider);

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
      body: activeSemAsync.when(
        data: (activeSem) {
          if (activeSem != null) {
            final now = DateTime.now();
            final advStart = activeSem.advisingStartDate;
            final classStart = activeSem.upcomingClassesStartDate;

            bool isLocked = true;
            if (advStart != null && classStart != null) {
              final unlockDate = advStart.subtract(const Duration(days: 16));
              if (now.isAfter(unlockDate) && now.isBefore(classStart)) {
                isLocked = false;
              }
            }

            if (isLocked) {
              final openDateStr = advStart != null ? DateFormat('MMM dd, yyyy h:mm a').format(advStart.subtract(const Duration(days: 16))) : 'TBA';
              final closeDateStr = classStart != null ? DateFormat('MMM dd, yyyy h:mm a').format(classStart) : 'TBA';
              return _buildLockedView(
                'Pre-Advising Locked',
                'The pre-advising section opens on $openDateStr and closes on $closeDateStr.',
                Icons.lock_clock
              );
            }
          }

          // If a generation is active, show the tracking view
          if (advisingState.generationId != null) {
            return _buildGenerationOverview(advisingState.generationId!);
          }
          return _buildMainPlanningView(activeSem);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (err, stack) => Center(child: Text('Error loading configuration', style: const TextStyle(color: Colors.red))),
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
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSelectionTab(activeSem),
              _buildSavedSchedulesTab(),
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
                  'Selected Courses',
                  style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: advisingState.selectedCourses.map((code) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(code, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => ref.read(advisingNotifierProvider.notifier).toggleCourse(code),
                        backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                        side: const BorderSide(color: Colors.cyan),
                        labelStyle: const TextStyle(color: Colors.cyan),
                        deleteIconColor: Colors.cyan,
                      ),
                    )).toList(),
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
              final filtered = courses.where((c) =>
                c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.name.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();

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
                  final isSelected = advisingState.selectedCourses.contains(course.code);

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
            error: (e, _) => Center(child: Text('Error loading courses', style: const TextStyle(color: Colors.red))),
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

  Widget _buildGenerationOverview(String genId) {
    final trackerAsync = ref.watch(generationTrackerProvider(genId));

    return trackerAsync.when(
      data: (data) {
        if (data == null) return const Center(child: Text('Generation session missing.', style: TextStyle(color: Colors.white)));

        final status = data['status'] ?? 'processing';
        final count = data['count'] ?? 0;
        final combinations = data['combinations'] as List? ?? [];

        // If we have some combinations, show them even if still processing
        if (combinations.isNotEmpty) {
           return _buildResultsList(combinations, status, count);
        }

        if (status == 'processing') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.cyan),
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
        return _buildResultsList(combinations, status, count);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => Center(child: Text('Tracking Error', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildResultsList(List combinations, String status, int count) {
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
                    status == 'processing' ? 'Searching...' : '$count Schedules Found',
                    style: const TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold),
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
              IconButton(
                onPressed: () => ref.read(advisingNotifierProvider.notifier).reset(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: combinations.length,
            itemBuilder: (context, index) {
              final combo = combinations[index];
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
                          title: Text('$code - ${sec['section']}',
                              style: const TextStyle(color: Colors.white70)),
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
            const Text('Something went wrong loading drafts.', 
              style: TextStyle(color: Colors.white70)),
            Text('$e', style: TextStyle(color: Colors.grey[800], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

