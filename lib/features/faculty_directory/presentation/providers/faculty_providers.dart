import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/faculty_repository.dart';
import '../../../../core/models/faculty.dart';

final facultySearchQueryProvider = StateProvider<String>((ref) => '');
final facultyDepartmentFilterProvider = StateProvider<String>((ref) => 'All');

final facultyDirectoryProvider = FutureProvider<List<Faculty>>((ref) async {
  final query = ref.watch(facultySearchQueryProvider).trim();
  final selectedDept = ref.watch(facultyDepartmentFilterProvider);
  final repo = ref.watch(facultyRepositoryProvider);
  
  List<Faculty> list;
  if (query.isEmpty) {
    list = await repo.getAllFaculty();
  } else {
    list = await repo.searchFaculty(query);
  }

  if (selectedDept != 'All') {
    list = list.where((f) => f.department.toUpperCase() == selectedDept.toUpperCase()).toList();
  }
  return list;
});
