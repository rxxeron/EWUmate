import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/providers/academic_providers.dart';
import '../../../core/services/azure_functions_service.dart';
import '../../../core/providers/supabase_provider.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});

  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty List'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(facultySnapshotsProvider.future),
        child: _buildSnapshotsSection(),
      ),
    );
  }

  Widget _buildSnapshotsSection() {
    final snapshotsAsync = ref.watch(facultySnapshotsProvider);

    return snapshotsAsync.when(
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No snapshots archived yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Group by Semester with normalization
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final s in snapshots) {
          String rawSem = s['semester'] ?? 'Unknown';
          // Normalize: "Summer2026" -> "Summer 2026"
          String sem = rawSem.replaceAllMapped(RegExp(r'(?<!\s)(\d{4})'), (match) => ' ${match.group(1)}').trim();
          grouped.putIfAbsent(sem, () => []).add(s);
        }

        final semesterList = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: semesterList.length,
          itemBuilder: (context, index) {
            final semester = semesterList[index];
            final items = grouped[semester]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_rounded, color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        semester,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ...items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final ts = DateTime.tryParse(s['timestamp'] ?? '');
                  final dateStr = ts != null ? '${ts.day}/${ts.month}/${ts.year} @ ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}' : 'Recently';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: const Color(0xFF1E293B).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 22),
                      ),
                      title: Text(
                        i == 0 ? 'Current Faculty List' : 'Archive: $dateStr',
                        style: TextStyle(
                          fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w500, 
                          fontSize: 15,
                          color: i == 0 ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      subtitle: i == 0 ? Text(
                        'Last updated: $dateStr',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ) : null,
                      trailing: Icon(
                        i == 0 ? Icons.file_download_outlined : Icons.history_rounded, 
                        color: i == 0 ? const Color(0xFF00E5FF) : Colors.grey[600], 
                        size: 20
                      ),
                      onTap: () => launchUrl(Uri.parse(s['url']), mode: LaunchMode.externalApplication),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
