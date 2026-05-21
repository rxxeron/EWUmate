// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$progressRepositoryHash() =>
    r'bfa8254dc3b034fb03119a5592a8f7b8e3df1e7b';

/// See also [progressRepository].
@ProviderFor(progressRepository)
final progressRepositoryProvider =
    AutoDisposeProvider<ProgressRepository>.internal(
  progressRepository,
  name: r'progressRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progressRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProgressRepositoryRef = AutoDisposeProviderRef<ProgressRepository>;
String _$currentSemesterMarksHash() =>
    r'bfdf86f845b6c370058a83b4e3ed1bf4efd591d7';

/// See also [currentSemesterMarks].
@ProviderFor(currentSemesterMarks)
final currentSemesterMarksProvider =
    AutoDisposeStreamProvider<List<SemesterCourseMarks>>.internal(
  currentSemesterMarks,
  name: r'currentSemesterMarksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSemesterMarksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentSemesterMarksRef
    = AutoDisposeStreamProviderRef<List<SemesterCourseMarks>>;
String _$allSemesterSummariesHash() =>
    r'2e2ca7cc5072cfeddf903ab5a97c268cccc8ec71';

/// See also [allSemesterSummaries].
@ProviderFor(allSemesterSummaries)
final allSemesterSummariesProvider =
    AutoDisposeStreamProvider<List<SemesterSummary>>.internal(
  allSemesterSummaries,
  name: r'allSemesterSummariesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allSemesterSummariesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllSemesterSummariesRef
    = AutoDisposeStreamProviderRef<List<SemesterSummary>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
