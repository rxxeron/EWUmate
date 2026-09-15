import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/repositories/auth_repository.dart';
import '../../../../../core/repositories/schedule_repository.dart';
import '../../../../../core/widgets/glass_kit.dart';
import '../../../../../core/utils/error_utils.dart';
import '../../user_academic_providers.dart';

class AdvisingSavedDraftsTab extends ConsumerWidget {
  const AdvisingSavedDraftsTab({super.key});

  static String formatSessions(dynamic sessions) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        subtitle: Text(formatSessions(sessions), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
}
