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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Official PDF Snapshots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'These catalogs are automatically generated every day at 2:00 AM from the university portal data.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildSnapshotsSection()),
              ],
            ),
          ),
        ),
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: snapshots.length,
          itemBuilder: (context, index) {
            final s = snapshots[index];
            final ts = DateTime.tryParse(s['timestamp'] ?? '');
            final dateStr = ts != null ? '${ts.day}/${ts.month}/${ts.year} @ ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}' : 'Recently';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.indigo.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: Text(
                  s['semester'] ?? 'Unknown Semester',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  'Archived: $dateStr',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                onTap: () => launchUrl(Uri.parse(s['url']), mode: LaunchMode.externalApplication),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
