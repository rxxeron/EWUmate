// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faculty_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(facultyRepository)
final facultyRepositoryProvider = FacultyRepositoryProvider._();

final class FacultyRepositoryProvider extends $FunctionalProvider<
    FacultyRepository,
    FacultyRepository,
    FacultyRepository> with $Provider<FacultyRepository> {
  FacultyRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'facultyRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$facultyRepositoryHash();

  @$internal
  @override
  $ProviderElement<FacultyRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FacultyRepository create(Ref ref) {
    return facultyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FacultyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FacultyRepository>(value),
    );
  }
}

String _$facultyRepositoryHash() => r'2c3744fbac5b51891a5b123b94fcd795ef09ba34';

@ProviderFor(allFaculty)
final allFacultyProvider = AllFacultyProvider._();

final class AllFacultyProvider extends $FunctionalProvider<
        AsyncValue<List<Faculty>>, List<Faculty>, FutureOr<List<Faculty>>>
    with $FutureModifier<List<Faculty>>, $FutureProvider<List<Faculty>> {
  AllFacultyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allFacultyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allFacultyHash();

  @$internal
  @override
  $FutureProviderElement<List<Faculty>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Faculty>> create(Ref ref) {
    return allFaculty(ref);
  }
}

String _$allFacultyHash() => r'3d9b2f46b95c436c7d900e33b7779277154af39b';

@ProviderFor(facultySections)
final facultySectionsProvider = FacultySectionsFamily._();

final class FacultySectionsProvider extends $FunctionalProvider<
        AsyncValue<List<CourseSection>>,
        List<CourseSection>,
        FutureOr<List<CourseSection>>>
    with
        $FutureModifier<List<CourseSection>>,
        $FutureProvider<List<CourseSection>> {
  FacultySectionsProvider._(
      {required FacultySectionsFamily super.from,
      required ({
        String initials,
        String semesterCode,
      })
          super.argument})
      : super(
          retry: null,
          name: r'facultySectionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$facultySectionsHash();

  @override
  String toString() {
    return r'facultySectionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<CourseSection>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseSection>> create(Ref ref) {
    final argument = this.argument as ({
      String initials,
      String semesterCode,
    });
    return facultySections(
      ref,
      initials: argument.initials,
      semesterCode: argument.semesterCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FacultySectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$facultySectionsHash() => r'1cb76b7312bf58856ad4c834ffe3dc54c614ad5b';

final class FacultySectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<CourseSection>>,
            ({
              String initials,
              String semesterCode,
            })> {
  FacultySectionsFamily._()
      : super(
          retry: null,
          name: r'facultySectionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  FacultySectionsProvider call({
    required String initials,
    required String semesterCode,
  }) =>
      FacultySectionsProvider._(argument: (
        initials: initials,
        semesterCode: semesterCode,
      ), from: this);

  @override
  String toString() => r'facultySectionsProvider';
}
