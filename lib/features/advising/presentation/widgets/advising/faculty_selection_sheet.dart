import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user_academic_providers.dart';
import '../../advising_notifier.dart';

class FacultySelectionSheet extends ConsumerWidget {
  final String courseCode;

  const FacultySelectionSheet({super.key, required this.courseCode});

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
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
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
            error: (e, st) => const Center(child: Text('Error loading faculties', style: TextStyle(color: Colors.red))),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
