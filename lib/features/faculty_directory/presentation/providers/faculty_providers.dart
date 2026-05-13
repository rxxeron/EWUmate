import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/faculty_repository.dart';
import '../../../../core/models/faculty.dart';

final facultySearchQueryProvider = StateProvider<String>((ref) => '');

final facultyDirectoryProvider = FutureProvider<List<Faculty>>((ref) async {
  final query = ref.watch(facultySearchQueryProvider);
  final repo = ref.watch(facultyRepositoryProvider);
  
  if (query.isEmpty) {
    return repo.getAllFaculty();
  } else {
    return repo.searchFaculty(query);
  }
});
