// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flag_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(isAdvisingOpen)
final isAdvisingOpenProvider = IsAdvisingOpenProvider._();

final class IsAdvisingOpenProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsAdvisingOpenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isAdvisingOpenProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isAdvisingOpenHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isAdvisingOpen(ref);
  }
}

String _$isAdvisingOpenHash() => r'0b4d90f3f9c3356acb8bc2a1ec30a238fe4954aa';

@ProviderFor(isNextSemesterOpen)
final isNextSemesterOpenProvider = IsNextSemesterOpenProvider._();

final class IsNextSemesterOpenProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsNextSemesterOpenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isNextSemesterOpenProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isNextSemesterOpenHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isNextSemesterOpen(ref);
  }
}

String _$isNextSemesterOpenHash() =>
    r'd3cd3ff03a2ce7749a32ee263b3c98f013435a5b';
