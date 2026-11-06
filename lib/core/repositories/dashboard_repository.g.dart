// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardRepository)
final dashboardRepositoryProvider = DashboardRepositoryProvider._();

final class DashboardRepositoryProvider extends $FunctionalProvider<
    DashboardRepository,
    DashboardRepository,
    DashboardRepository> with $Provider<DashboardRepository> {
  DashboardRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dashboardRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dashboardRepositoryHash();

  @$internal
  @override
  $ProviderElement<DashboardRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardRepository create(Ref ref) {
    return dashboardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardRepository>(value),
    );
  }
}

String _$dashboardRepositoryHash() =>
    r'fa4ee127b630576464af0dc660c12feb3a2d89f8';

@ProviderFor(currentAnalytics)
final currentAnalyticsProvider = CurrentAnalyticsProvider._();

final class CurrentAnalyticsProvider extends $FunctionalProvider<
        AsyncValue<SemesterAnalytics?>,
        SemesterAnalytics?,
        FutureOr<SemesterAnalytics?>>
    with
        $FutureModifier<SemesterAnalytics?>,
        $FutureProvider<SemesterAnalytics?> {
  CurrentAnalyticsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentAnalyticsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentAnalyticsHash();

  @$internal
  @override
  $FutureProviderElement<SemesterAnalytics?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SemesterAnalytics?> create(Ref ref) {
    return currentAnalytics(ref);
  }
}

String _$currentAnalyticsHash() => r'bc7b408f99e3908d421810ef8aed818d8bb7f74a';

@ProviderFor(currentSemesterState)
final currentSemesterStateProvider = CurrentSemesterStateProvider._();

final class CurrentSemesterStateProvider extends $FunctionalProvider<
        AsyncValue<UserSemesterState?>,
        UserSemesterState?,
        FutureOr<UserSemesterState?>>
    with
        $FutureModifier<UserSemesterState?>,
        $FutureProvider<UserSemesterState?> {
  CurrentSemesterStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentSemesterStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentSemesterStateHash();

  @$internal
  @override
  $FutureProviderElement<UserSemesterState?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserSemesterState?> create(Ref ref) {
    return currentSemesterState(ref);
  }
}

String _$currentSemesterStateHash() =>
    r'2510b44b8d6afdffa612349c844746d0ac9d6fc2';
