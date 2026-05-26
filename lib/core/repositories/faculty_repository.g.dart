// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faculty_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$facultyRepositoryHash() => r'4018d19e5f40c9877b9003654210e96b0004dd65';

/// See also [facultyRepository].
@ProviderFor(facultyRepository)
final facultyRepositoryProvider =
    AutoDisposeProvider<FacultyRepository>.internal(
  facultyRepository,
  name: r'facultyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$facultyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FacultyRepositoryRef = AutoDisposeProviderRef<FacultyRepository>;
String _$allFacultyHash() => r'd9162b034c7d5436667fdcd3e76cd9da9efb6777';

/// See also [allFaculty].
@ProviderFor(allFaculty)
final allFacultyProvider = AutoDisposeFutureProvider<List<Faculty>>.internal(
  allFaculty,
  name: r'allFacultyProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allFacultyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllFacultyRef = AutoDisposeFutureProviderRef<List<Faculty>>;
String _$facultySectionsHash() => r'b633334bc6df305c72dff2b7b8f9a22a093b6879';

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

/// See also [facultySections].
@ProviderFor(facultySections)
const facultySectionsProvider = FacultySectionsFamily();

/// See also [facultySections].
class FacultySectionsFamily extends Family<AsyncValue<List<CourseSection>>> {
  /// See also [facultySections].
  const FacultySectionsFamily();

  /// See also [facultySections].
  FacultySectionsProvider call({
    required String initials,
    required String semesterCode,
  }) {
    return FacultySectionsProvider(
      initials: initials,
      semesterCode: semesterCode,
    );
  }

  @override
  FacultySectionsProvider getProviderOverride(
    covariant FacultySectionsProvider provider,
  ) {
    return call(
      initials: provider.initials,
      semesterCode: provider.semesterCode,
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
  String? get name => r'facultySectionsProvider';
}

/// See also [facultySections].
class FacultySectionsProvider
    extends AutoDisposeFutureProvider<List<CourseSection>> {
  /// See also [facultySections].
  FacultySectionsProvider({
    required String initials,
    required String semesterCode,
  }) : this._internal(
          (ref) => facultySections(
            ref as FacultySectionsRef,
            initials: initials,
            semesterCode: semesterCode,
          ),
          from: facultySectionsProvider,
          name: r'facultySectionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$facultySectionsHash,
          dependencies: FacultySectionsFamily._dependencies,
          allTransitiveDependencies:
              FacultySectionsFamily._allTransitiveDependencies,
          initials: initials,
          semesterCode: semesterCode,
        );

  FacultySectionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initials,
    required this.semesterCode,
  }) : super.internal();

  final String initials;
  final String semesterCode;

  @override
  Override overrideWith(
    FutureOr<List<CourseSection>> Function(FacultySectionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FacultySectionsProvider._internal(
        (ref) => create(ref as FacultySectionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initials: initials,
        semesterCode: semesterCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CourseSection>> createElement() {
    return _FacultySectionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FacultySectionsProvider &&
        other.initials == initials &&
        other.semesterCode == semesterCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initials.hashCode);
    hash = _SystemHash.combine(hash, semesterCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FacultySectionsRef on AutoDisposeFutureProviderRef<List<CourseSection>> {
  /// The parameter `initials` of this provider.
  String get initials;

  /// The parameter `semesterCode` of this provider.
  String get semesterCode;
}

class _FacultySectionsProviderElement
    extends AutoDisposeFutureProviderElement<List<CourseSection>>
    with FacultySectionsRef {
  _FacultySectionsProviderElement(super.provider);

  @override
  String get initials => (origin as FacultySectionsProvider).initials;
  @override
  String get semesterCode => (origin as FacultySectionsProvider).semesterCode;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
