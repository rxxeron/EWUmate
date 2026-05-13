import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/faculty_providers.dart';
import 'widgets/faculty_card.dart';
import '../../../core/widgets/animations/skeleton_loader.dart';

class FacultyDirectoryScreen extends ConsumerWidget {
  const FacultyDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(facultyDirectoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Faculty Directory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              onChanged: (val) => ref.read(facultySearchQueryProvider.notifier).state = val,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, initials, or email...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                filled: true,
                fillColor: const Color(0xFF1E2836).withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Faculty List
          Expanded(
            child: facultyAsync.when(
              data: (facultyList) {
                if (facultyList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No faculty found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: facultyList.length,
                  itemBuilder: (context, index) => FacultyCard(
                    faculty: facultyList[index],
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 16),
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Failed to load directory: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
