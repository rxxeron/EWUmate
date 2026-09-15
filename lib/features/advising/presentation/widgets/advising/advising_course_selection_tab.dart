import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/active_semester.dart';
import '../../../../../core/repositories/auth_repository.dart';
import '../../../../../core/utils/error_utils.dart';
import '../../../../../core/widgets/glass_kit.dart';
import '../../user_academic_providers.dart';
import '../../advising_notifier.dart';
import 'faculty_selection_sheet.dart';

class AdvisingCourseSelectionTab extends ConsumerStatefulWidget {
  final ActiveSemester? activeSem;

  const AdvisingCourseSelectionTab({super.key, required this.activeSem});

  @override
  ConsumerState<AdvisingCourseSelectionTab> createState() => _AdvisingCourseSelectionTabState();
}

class _AdvisingCourseSelectionTabState extends ConsumerState<AdvisingCourseSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        return FacultySelectionSheet(courseCode: courseCode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCoursesAsync = ref.watch(availableAdvisingCoursesProvider);
    final advisingState = ref.watch(advisingNotifierProvider);
    final activeSem = widget.activeSem;

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
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
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
}
