import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/progress_repository.dart';
import 'screens/course_marks_editor_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMarksAsync = ref.watch(currentSemesterMarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: currentMarksAsync.when(
        data: (marks) {
          if (marks.isEmpty) {
            return const Center(child: Text('No course marks found for this semester.', style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: marks.length,
            itemBuilder: (context, index) {
              final mark = marks[index];
              return Card(
                color: const Color(0xFF1E1E2E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(mark.courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(mark.courseName ?? '', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      const Text('Tap to view Outline & Obtained marks', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseMarksEditorScreen(courseMarks: mark),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
