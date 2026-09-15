import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/active_semester.dart';
import '../../../../../core/utils/error_utils.dart';
import '../../../../../core/widgets/glass_kit.dart';
import '../../user_academic_providers.dart';
import '../../advising_notifier.dart';
import '../../../../../core/services/screen_protection_service.dart';

class AdvisingGenerationOverviewView extends ConsumerStatefulWidget {
  final String genId;
  final ActiveSemester? activeSem;

  const AdvisingGenerationOverviewView({
    super.key,
    required this.genId,
    required this.activeSem,
  });

  @override
  ConsumerState<AdvisingGenerationOverviewView> createState() =>
      _AdvisingGenerationOverviewViewState();
}

class _AdvisingGenerationOverviewViewState
    extends ConsumerState<AdvisingGenerationOverviewView> {
  final Set<String> _hiddenFaculties = {};

  @override
  void initState() {
    super.initState();
    ScreenProtectionService.enableProtection();
  }

  String _formatSessions(dynamic sessions) {
    if (sessions == null || sessions is! List || sessions.isEmpty) {
      return 'No timing available';
    }

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

  Widget _buildCapacityIndicator(String capacity) {
    if (capacity.isEmpty || !capacity.contains('/')) {
      return const SizedBox.shrink();
    }
    try {
      final parts = capacity.split('/');
      final enrolled = int.parse(parts[0].trim());
      final total = int.parse(parts[1].trim());
      final bool isFull =
          (total > 0 && enrolled >= total) || (total == 0 && enrolled > 0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0.5),
        decoration: BoxDecoration(
          color: (isFull ? Colors.redAccent : Colors.cyan).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: (isFull ? Colors.redAccent : Colors.cyan).withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Text(
          isFull ? 'Full' : '${total - enrolled} Left',
          style: TextStyle(
              color: isFull ? Colors.redAccent : Colors.cyan,
              fontSize: 8,
              fontWeight: FontWeight.bold),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _showLocalFacultyFilterSheet(
      BuildContext context, Set<String> allFaculties) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      const Text('Filter by Faculty',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white54))
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                      'Deselect faculties to hide their combinations from the results:',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                            labelStyle: TextStyle(
                                color: isSelected ? Colors.cyan : Colors.white70),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.cyan
                                  : Colors.grey.withValues(alpha: 0.3),
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
          },
        );
      },
    );
  }

  Widget _buildResultsList(List allCombinations, String status, int count,
      String semesterName) {
    final Set<String> allFaculties = {};
    for (var combo in allCombinations) {
      final sections = combo['sections'] as Map<String, dynamic>? ?? {};
      for (var sec in sections.values) {
        final faculty =
            (sec['faculty_initials'] ?? sec['faculty'] ?? '').toString();
        if (faculty.isNotEmpty && faculty != 'TBA') {
          allFaculties.add(faculty);
        }
      }
    }

    final filteredCombinations = allCombinations.where((combo) {
      if (_hiddenFaculties.isEmpty) return true;
      final sections = combo['sections'] as Map<String, dynamic>? ?? {};
      for (var sec in sections.values) {
        final faculty =
            (sec['faculty_initials'] ?? sec['faculty'] ?? '').toString();
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
                    status == 'processing'
                        ? 'Searching...'
                        : '${filteredCombinations.length} Schedules Found',
                    style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
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
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan),
                ),
              if (allFaculties.isNotEmpty)
                IconButton(
                  onPressed: () =>
                      _showLocalFacultyFilterSheet(context, allFaculties),
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
                                final activeSem = await ref
                                    .read(activeSemesterProvider.future);
                                final sem = activeSem?.nextSemesterCode;
                                if (sem == null) return;

                                await ref
                                    .read(advisingNotifierProvider.notifier)
                                    .saveSchedule(
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
                        final code =
                            sec['course_code'] ?? sec['code'] ?? '???';
                        final faculty = (sec['faculty_initials'] ??
                                sec['faculty'] ??
                                'TBA')
                            .toString();

                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Text('$code - ${sec['section']}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              const SizedBox(width: 8),
                              _buildCapacityIndicator(
                                  sec['capacity']?.toString() ?? ''),
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

  @override
  Widget build(BuildContext context) {
    final trackerAsync = ref.watch(generationTrackerProvider(widget.genId));
    final semesterName = widget.activeSem?.nextSemesterCode ?? 'Next Semester';

    return trackerAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(
              child: Text('Generation session missing.',
                  style: TextStyle(color: Colors.white)));
        }

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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have found $count combinations so far.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () =>
                      ref.read(advisingNotifierProvider.notifier).reset(),
                  child: const Text('Cancel & Start Over',
                      style: TextStyle(color: Colors.redAccent)),
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
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.redAccent),
                  const SizedBox(height: 24),
                  const Text('No valid combinations found',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Try removing one or two courses. This usually happens when time slots overlap heavily.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () =>
                        ref.read(advisingNotifierProvider.notifier).reset(),
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
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.cyan)),
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
}
