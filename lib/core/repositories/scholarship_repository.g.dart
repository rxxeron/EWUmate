// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scholarshipRepository)
final scholarshipRepositoryProvider = ScholarshipRepositoryProvider._();

final class ScholarshipRepositoryProvider extends $FunctionalProvider<
    ScholarshipRepository,
    ScholarshipRepository,
    ScholarshipRepository> with $Provider<ScholarshipRepository> {
  ScholarshipRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'scholarshipRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scholarshipRepositoryHash();

  @$internal
  @override
  $ProviderElement<ScholarshipRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScholarshipRepository create(Ref ref) {
    return scholarshipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScholarshipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScholarshipRepository>(value),
    );
  }
}

String _$scholarshipRepositoryHash() =>
    r'cec8e33e0c16fea0659855beabd638f33e40f589';

@ProviderFor(scholarshipPolicy)
final scholarshipPolicyProvider = ScholarshipPolicyFamily._();

final class ScholarshipPolicyProvider extends $FunctionalProvider<
        AsyncValue<ScholarshipRule?>,
        ScholarshipRule?,
        FutureOr<ScholarshipRule?>>
    with $FutureModifier<ScholarshipRule?>, $FutureProvider<ScholarshipRule?> {
  ScholarshipPolicyProvider._(
      {required ScholarshipPolicyFamily super.from,
      required (
        String, {
        String? admittedSemester,
      })
          super.argument})
      : super(
          retry: null,
          name: r'scholarshipPolicyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scholarshipPolicyHash();

  @override
  String toString() {
    return r'scholarshipPolicyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ScholarshipRule?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ScholarshipRule?> create(Ref ref) {
    final argument = this.argument as (
      String, {
      String? admittedSemester,
    });
    return scholarshipPolicy(
      ref,
      argument.$1,
      admittedSemester: argument.admittedSemester,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ScholarshipPolicyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scholarshipPolicyHash() => r'74a49cf6790f1963354bc21eb35d3b95bdfab65c';

final class ScholarshipPolicyFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<ScholarshipRule?>,
            (
              String, {
              String? admittedSemester,
            })> {
  ScholarshipPolicyFamily._()
      : super(
          retry: null,
          name: r'scholarshipPolicyProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ScholarshipPolicyProvider call(
    String programId, {
    String? admittedSemester,
  }) =>
      ScholarshipPolicyProvider._(argument: (
        programId,
        admittedSemester: admittedSemester,
      ), from: this);

  @override
  String toString() => r'scholarshipPolicyProvider';
}
