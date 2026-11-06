// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_semester_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeSemesterRepository)
final activeSemesterRepositoryProvider = ActiveSemesterRepositoryProvider._();

final class ActiveSemesterRepositoryProvider extends $FunctionalProvider<
    ActiveSemesterRepository,
    ActiveSemesterRepository,
    ActiveSemesterRepository> with $Provider<ActiveSemesterRepository> {
  ActiveSemesterRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'activeSemesterRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeSemesterRepositoryHash();

  @$internal
  @override
  $ProviderElement<ActiveSemesterRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActiveSemesterRepository create(Ref ref) {
    return activeSemesterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveSemesterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveSemesterRepository>(value),
    );
  }
}

String _$activeSemesterRepositoryHash() =>
    r'0a63013cc1bad43fc447e960d26c9f184487ad6b';
