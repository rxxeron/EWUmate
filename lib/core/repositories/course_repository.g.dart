// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$courseRepositoryHash() => r'254627a506a75c133dc0b648f0c5d3b5d07a4062';

/// See also [courseRepository].
@ProviderFor(courseRepository)
final courseRepositoryProvider = AutoDisposeProvider<CourseRepository>.internal(
  courseRepository,
  name: r'courseRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$courseRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CourseRepositoryRef = AutoDisposeProviderRef<CourseRepository>;
String _$allCoursesHash() => r'4c14015d3bce64dad346645c24c4315f1478e7ed';

/// See also [allCourses].
@ProviderFor(allCourses)
final allCoursesProvider =
    AutoDisposeFutureProvider<List<CourseMetadata>>.internal(
  allCourses,
  name: r'allCoursesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allCoursesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllCoursesRef = AutoDisposeFutureProviderRef<List<CourseMetadata>>;
String _$semesterCoursesHash() => r'448914ab02c395ee60f307d51c85b9b10b9990d2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [semesterCourses].
@ProviderFor(semesterCourses)
const semesterCoursesProvider = SemesterCoursesFamily();

/// See also [semesterCourses].
class SemesterCoursesFamily extends Family<AsyncValue<List<CourseMetadata>>> {
  /// See also [semesterCourses].
  const SemesterCoursesFamily();

  /// See also [semesterCourses].
  SemesterCoursesProvider call(
    String semesterCode,
  ) {
    return SemesterCoursesProvider(
      semesterCode,
    );
  }

  @override
  SemesterCoursesProvider getProviderOverride(
    covariant SemesterCoursesProvider provider,
  ) {
    return call(
      provider.semesterCode,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'semesterCoursesProvider';
}

/// See also [semesterCourses].
class SemesterCoursesProvider
    extends AutoDisposeFutureProvider<List<CourseMetadata>> {
  /// See also [semesterCourses].
  SemesterCoursesProvider(
    String semesterCode,
  ) : this._internal(
          (ref) => semesterCourses(
            ref as SemesterCoursesRef,
            semesterCode,
          ),
          from: semesterCoursesProvider,
          name: r'semesterCoursesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$semesterCoursesHash,
          dependencies: SemesterCoursesFamily._dependencies,
          allTransitiveDependencies:
              SemesterCoursesFamily._allTransitiveDependencies,
          semesterCode: semesterCode,
        );

  SemesterCoursesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.semesterCode,
  }) : super.internal();

  final String semesterCode;

  @override
  Override overrideWith(
    FutureOr<List<CourseMetadata>> Function(SemesterCoursesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SemesterCoursesProvider._internal(
        (ref) => create(ref as SemesterCoursesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        semesterCode: semesterCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CourseMetadata>> createElement() {
    return _SemesterCoursesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SemesterCoursesProvider &&
        other.semesterCode == semesterCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, semesterCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SemesterCoursesRef on AutoDisposeFutureProviderRef<List<CourseMetadata>> {
  /// The parameter `semesterCode` of this provider.
  String get semesterCode;
}

class _SemesterCoursesProviderElement
    extends AutoDisposeFutureProviderElement<List<CourseMetadata>>
    with SemesterCoursesRef {
  _SemesterCoursesProviderElement(super.provider);

  @override
  String get semesterCode => (origin as SemesterCoursesProvider).semesterCode;
}

String _$courseSectionsHash() => r'8b33904542159f2415e4e172b8808cdc33155603';

/// See also [courseSections].
@ProviderFor(courseSections)
const courseSectionsProvider = CourseSectionsFamily();

/// See also [courseSections].
class CourseSectionsFamily extends Family<AsyncValue<List<CourseSection>>> {
  /// See also [courseSections].
  const CourseSectionsFamily();

  /// See also [courseSections].
  CourseSectionsProvider call({
    required String semesterCode,
    required String courseCode,
  }) {
    return CourseSectionsProvider(
      semesterCode: semesterCode,
      courseCode: courseCode,
    );
  }

  @override
  CourseSectionsProvider getProviderOverride(
    covariant CourseSectionsProvider provider,
  ) {
    return call(
      semesterCode: provider.semesterCode,
      courseCode: provider.courseCode,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'courseSectionsProvider';
}

/// See also [courseSections].
class CourseSectionsProvider
    extends AutoDisposeFutureProvider<List<CourseSection>> {
  /// See also [courseSections].
  CourseSectionsProvider({
    required String semesterCode,
    required String courseCode,
  }) : this._internal(
          (ref) => courseSections(
            ref as CourseSectionsRef,
            semesterCode: semesterCode,
            courseCode: courseCode,
          ),
          from: courseSectionsProvider,
          name: r'courseSectionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$courseSectionsHash,
          dependencies: CourseSectionsFamily._dependencies,
          allTransitiveDependencies:
              CourseSectionsFamily._allTransitiveDependencies,
          semesterCode: semesterCode,
          courseCode: courseCode,
        );

  CourseSectionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.semesterCode,
    required this.courseCode,
  }) : super.internal();

  final String semesterCode;
  final String courseCode;

  @override
  Override overrideWith(
    FutureOr<List<CourseSection>> Function(CourseSectionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CourseSectionsProvider._internal(
        (ref) => create(ref as CourseSectionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        semesterCode: semesterCode,
        courseCode: courseCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CourseSection>> createElement() {
    return _CourseSectionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseSectionsProvider &&
        other.semesterCode == semesterCode &&
        other.courseCode == courseCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, semesterCode.hashCode);
    hash = _SystemHash.combine(hash, courseCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CourseSectionsRef on AutoDisposeFutureProviderRef<List<CourseSection>> {
  /// The parameter `semesterCode` of this provider.
  String get semesterCode;

  /// The parameter `courseCode` of this provider.
  String get courseCode;
}

class _CourseSectionsProviderElement
    extends AutoDisposeFutureProviderElement<List<CourseSection>>
    with CourseSectionsRef {
  _CourseSectionsProviderElement(super.provider);

  @override
  String get semesterCode => (origin as CourseSectionsProvider).semesterCode;
  @override
  String get courseCode => (origin as CourseSectionsProvider).courseCode;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
