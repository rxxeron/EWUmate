// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scholarshipRepositoryHash() =>
    r'2f42c9e1ee7080454fef6bfce1720cd48d9fec93';

/// See also [scholarshipRepository].
@ProviderFor(scholarshipRepository)
final scholarshipRepositoryProvider =
    AutoDisposeProvider<ScholarshipRepository>.internal(
  scholarshipRepository,
  name: r'scholarshipRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scholarshipRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ScholarshipRepositoryRef
    = AutoDisposeProviderRef<ScholarshipRepository>;
String _$scholarshipPolicyHash() => r'351afecc1a62d636233a3c27ad663a727866e7f2';

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

/// See also [scholarshipPolicy].
@ProviderFor(scholarshipPolicy)
const scholarshipPolicyProvider = ScholarshipPolicyFamily();

/// See also [scholarshipPolicy].
class ScholarshipPolicyFamily extends Family<AsyncValue<ScholarshipRule?>> {
  /// See also [scholarshipPolicy].
  const ScholarshipPolicyFamily();

  /// See also [scholarshipPolicy].
  ScholarshipPolicyProvider call(
    String programId, {
    String? admittedSemester,
  }) {
    return ScholarshipPolicyProvider(
      programId,
      admittedSemester: admittedSemester,
    );
  }

  @override
  ScholarshipPolicyProvider getProviderOverride(
    covariant ScholarshipPolicyProvider provider,
  ) {
    return call(
      provider.programId,
      admittedSemester: provider.admittedSemester,
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
  String? get name => r'scholarshipPolicyProvider';
}

/// See also [scholarshipPolicy].
class ScholarshipPolicyProvider
    extends AutoDisposeFutureProvider<ScholarshipRule?> {
  /// See also [scholarshipPolicy].
  ScholarshipPolicyProvider(
    String programId, {
    String? admittedSemester,
  }) : this._internal(
          (ref) => scholarshipPolicy(
            ref as ScholarshipPolicyRef,
            programId,
            admittedSemester: admittedSemester,
          ),
          from: scholarshipPolicyProvider,
          name: r'scholarshipPolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scholarshipPolicyHash,
          dependencies: ScholarshipPolicyFamily._dependencies,
          allTransitiveDependencies:
              ScholarshipPolicyFamily._allTransitiveDependencies,
          programId: programId,
          admittedSemester: admittedSemester,
        );

  ScholarshipPolicyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.programId,
    required this.admittedSemester,
  }) : super.internal();

  final String programId;
  final String? admittedSemester;

  @override
  Override overrideWith(
    FutureOr<ScholarshipRule?> Function(ScholarshipPolicyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScholarshipPolicyProvider._internal(
        (ref) => create(ref as ScholarshipPolicyRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        programId: programId,
        admittedSemester: admittedSemester,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScholarshipRule?> createElement() {
    return _ScholarshipPolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScholarshipPolicyProvider &&
        other.programId == programId &&
        other.admittedSemester == admittedSemester;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, programId.hashCode);
    hash = _SystemHash.combine(hash, admittedSemester.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ScholarshipPolicyRef on AutoDisposeFutureProviderRef<ScholarshipRule?> {
  /// The parameter `programId` of this provider.
  String get programId;

  /// The parameter `admittedSemester` of this provider.
  String? get admittedSemester;
}

class _ScholarshipPolicyProviderElement
    extends AutoDisposeFutureProviderElement<ScholarshipRule?>
    with ScholarshipPolicyRef {
  _ScholarshipPolicyProviderElement(super.provider);

  @override
  String get programId => (origin as ScholarshipPolicyProvider).programId;
  @override
  String? get admittedSemester =>
      (origin as ScholarshipPolicyProvider).admittedSemester;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
