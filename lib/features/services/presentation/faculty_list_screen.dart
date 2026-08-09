import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/academic_providers.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});

  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {
  static const String driveFolderUrl = "https://drive.google.com/drive/folders/117C1TyXx4Q1q1ihcgJoE1xk7CzCYniSD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty List'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(facultySnapshotsProvider.future),
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    final snapshotsAsync = ref.watch(facultySnapshotsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Main Prominent Google Drive Folder Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF00E5FF), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Official Faculty List Drive',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Access all faculty PDFs directly in Google Drive',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(driveFolderUrl), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'Open Google Drive Folder',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Faculty List Snapshots (Google Drive)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),

        snapshotsAsync.when(
          data: (snapshots) {
            if (snapshots.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No archived snapshots found.', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            final grouped = <String, List<Map<String, dynamic>>>{};
            for (final s in snapshots) {
              String rawSem = s['semester'] ?? 'Unknown';
              String sem = rawSem.replaceAllMapped(RegExp(r'(?<!\s)(\d{4})'), (match) => ' ${match.group(1)}').trim();
              grouped.putIfAbsent(sem, () => []).add(s);
            }

            final semesterList = grouped.keys.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: semesterList.length,
              itemBuilder: (context, index) {
                final semester = semesterList[index];
                final items = grouped[semester]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open_rounded, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            semester,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
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
                      final String targetUrl = s['drive_link'] ?? s['drive_folder_url'] ?? s['url'] ?? driveFolderUrl;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: const Color(0xFF1E293B).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_to_drive_rounded, color: Color(0xFF4285F4), size: 20),
                          ),
                          title: Text(
                            i == 0 ? 'Current Faculty List (Drive)' : 'Faculty List Snapshot ($dateStr)',
                            style: TextStyle(
                              fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                              color: i == 0 ? Colors.white : Colors.grey[300],
                            ),
                          ),
                          subtitle: Text(
                            'Tap to open Google Drive',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF00E5FF), size: 18),
                          onTap: () => launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        ),
      ],
    );
  }
}
