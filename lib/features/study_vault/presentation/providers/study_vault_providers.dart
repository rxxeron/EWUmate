import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/study_material.dart';
import '../../data/repositories/study_vault_repository.dart';

final vaultFiltersProvider = StateProvider<Map<String, String?>>((ref) => {
  'facultyInitial': null,
  'courseCode': null,
  'semester': null,
  'fileType': null,
  'searchQuery': null,
});

final studyMaterialsProvider = FutureProvider.autoDispose<List<StudyMaterial>>((ref) async {
  final filters = ref.watch(vaultFiltersProvider);
  final repository = ref.read(studyVaultRepositoryProvider);

  return repository.getMaterials(
    facultyInitial: filters['facultyInitial'],
    courseCode: filters['courseCode'],
    semester: filters['semester'],
    fileType: filters['fileType'],
    searchQuery: filters['searchQuery'],
  );
});

final semestersProvider = FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final semesterRes = await Supabase.instance.client
        .from('semesters')
        .select('code, title')
        .order('code', ascending: false);
        
    final List<Map<String, String>> list = [];
    final rows = semesterRes as List;
    for (var row in rows) {
      if (row['code'] != null) {
        list.add({
          'value': row['code'].toString(),
          'label': row['title']?.toString() ?? row['code'].toString(),
        });
      }
    }
    return list;
  } catch (e) {
    // Return hardcoded fallback if db query fails
    return [
      {'value': 'spring2024', 'label': 'Spring 2024'},
      {'value': 'summer2024', 'label': 'Summer 2024'},
      {'value': 'fall2024', 'label': 'Fall 2024'},
      {'value': 'spring2025', 'label': 'Spring 2025'},
      {'value': 'summer2025', 'label': 'Summer 2025'},
      {'value': 'fall2025', 'label': 'Fall 2025'},
      {'value': 'spring2026', 'label': 'Spring 2026'},
      {'value': 'summer2026', 'label': 'Summer 2026'},
      {'value': 'fall2026', 'label': 'Fall 2026'}
    ];
  }
});

final myStudyMaterialsProvider = FutureProvider.autoDispose<List<StudyMaterial>>((ref) async {
  final repository = ref.read(studyVaultRepositoryProvider);
  return repository.getMyMaterials();
});


