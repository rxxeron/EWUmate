import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/glass_kit.dart';
import '../../user_academic_providers.dart';
import '../../advising_notifier.dart';

class AdvisingGenerationHistoryTab extends ConsumerWidget {
  const AdvisingGenerationHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
