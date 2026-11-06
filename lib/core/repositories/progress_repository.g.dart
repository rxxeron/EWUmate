// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progressRepository)
final progressRepositoryProvider = ProgressRepositoryProvider._();

final class ProgressRepositoryProvider extends $FunctionalProvider<
    ProgressRepository,
    ProgressRepository,
    ProgressRepository> with $Provider<ProgressRepository> {
  ProgressRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'progressRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$progressRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProgressRepository create(Ref ref) {
    return progressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressRepository>(value),
    );
  }
}

String _$progressRepositoryHash() =>
    r'bdc006a677a5100580fe042b5e3be9266c7ac761';

@ProviderFor(currentSemesterMarks)
final currentSemesterMarksProvider = CurrentSemesterMarksProvider._();

final class CurrentSemesterMarksProvider extends $FunctionalProvider<
        AsyncValue<List<SemesterCourseMarks>>,
        List<SemesterCourseMarks>,
        Stream<List<SemesterCourseMarks>>>
    with
        $FutureModifier<List<SemesterCourseMarks>>,
        $StreamProvider<List<SemesterCourseMarks>> {
  CurrentSemesterMarksProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentSemesterMarksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentSemesterMarksHash();

  @$internal
  @override
  $StreamProviderElement<List<SemesterCourseMarks>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<SemesterCourseMarks>> create(Ref ref) {
    return currentSemesterMarks(ref);
  }
}

String _$currentSemesterMarksHash() =>
    r'b0af93c206b26bfc41eb3cee5f04c19a8caacbbd';

@ProviderFor(allSemesterSummaries)
final allSemesterSummariesProvider = AllSemesterSummariesProvider._();

final class AllSemesterSummariesProvider extends $FunctionalProvider<
        AsyncValue<List<SemesterSummary>>,
        List<SemesterSummary>,
        Stream<List<SemesterSummary>>>
    with
        $FutureModifier<List<SemesterSummary>>,
        $StreamProvider<List<SemesterSummary>> {
  AllSemesterSummariesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allSemesterSummariesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allSemesterSummariesHash();

  @$internal
  @override
  $StreamProviderElement<List<SemesterSummary>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<SemesterSummary>> create(Ref ref) {
    return allSemesterSummaries(ref);
  }
}

String _$allSemesterSummariesHash() =>
    r'3553a23f191c83ce107c0e27d5664c24b28939fa';
