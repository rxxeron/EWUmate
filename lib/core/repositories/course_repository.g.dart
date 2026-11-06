// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courseRepository)
final courseRepositoryProvider = CourseRepositoryProvider._();

final class CourseRepositoryProvider extends $FunctionalProvider<
    CourseRepository,
    CourseRepository,
    CourseRepository> with $Provider<CourseRepository> {
  CourseRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'courseRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$courseRepositoryHash();

  @$internal
  @override
  $ProviderElement<CourseRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CourseRepository create(Ref ref) {
    return courseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseRepository>(value),
    );
  }
}

String _$courseRepositoryHash() => r'653bb98093683beb3fec7fb2bde4475d7561a32e';

@ProviderFor(allCourses)
final allCoursesProvider = AllCoursesProvider._();

final class AllCoursesProvider extends $FunctionalProvider<
        AsyncValue<List<CourseMetadata>>,
        List<CourseMetadata>,
        FutureOr<List<CourseMetadata>>>
    with
        $FutureModifier<List<CourseMetadata>>,
        $FutureProvider<List<CourseMetadata>> {
  AllCoursesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allCoursesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allCoursesHash();

  @$internal
  @override
  $FutureProviderElement<List<CourseMetadata>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseMetadata>> create(Ref ref) {
    return allCourses(ref);
  }
}

String _$allCoursesHash() => r'2530f396f831eb58a1d88b129efc0c80176f59a6';

@ProviderFor(semesterCourses)
final semesterCoursesProvider = SemesterCoursesFamily._();

final class SemesterCoursesProvider extends $FunctionalProvider<
        AsyncValue<List<CourseMetadata>>,
        List<CourseMetadata>,
        FutureOr<List<CourseMetadata>>>
    with
        $FutureModifier<List<CourseMetadata>>,
        $FutureProvider<List<CourseMetadata>> {
  SemesterCoursesProvider._(
      {required SemesterCoursesFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'semesterCoursesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$semesterCoursesHash();

  @override
  String toString() {
    return r'semesterCoursesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CourseMetadata>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseMetadata>> create(Ref ref) {
    final argument = this.argument as String;
    return semesterCourses(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SemesterCoursesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$semesterCoursesHash() => r'2f2e99d9b9788bcda7af9426cefad974e0a1c96a';

final class SemesterCoursesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CourseMetadata>>, String> {
  SemesterCoursesFamily._()
      : super(
          retry: null,
          name: r'semesterCoursesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SemesterCoursesProvider call(
    String semesterCode,
  ) =>
      SemesterCoursesProvider._(argument: semesterCode, from: this);

  @override
  String toString() => r'semesterCoursesProvider';
}

@ProviderFor(courseSections)
final courseSectionsProvider = CourseSectionsFamily._();

final class CourseSectionsProvider extends $FunctionalProvider<
        AsyncValue<List<CourseSection>>,
        List<CourseSection>,
        FutureOr<List<CourseSection>>>
    with
        $FutureModifier<List<CourseSection>>,
        $FutureProvider<List<CourseSection>> {
  CourseSectionsProvider._(
      {required CourseSectionsFamily super.from,
      required ({
        String semesterCode,
        String courseCode,
      })
          super.argument})
      : super(
          retry: null,
          name: r'courseSectionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$courseSectionsHash();

  @override
  String toString() {
    return r'courseSectionsProvider'
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
      String semesterCode,
      String courseCode,
    });
    return courseSections(
      ref,
      semesterCode: argument.semesterCode,
      courseCode: argument.courseCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CourseSectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseSectionsHash() => r'54abdc946ecf4cfdcf6ee0a56db04169e1c85b6d';

final class CourseSectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<CourseSection>>,
            ({
              String semesterCode,
              String courseCode,
            })> {
  CourseSectionsFamily._()
      : super(
          retry: null,
          name: r'courseSectionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CourseSectionsProvider call({
    required String semesterCode,
    required String courseCode,
  }) =>
      CourseSectionsProvider._(argument: (
        semesterCode: semesterCode,
        courseCode: courseCode,
      ), from: this);

  @override
  String toString() => r'courseSectionsProvider';
}
