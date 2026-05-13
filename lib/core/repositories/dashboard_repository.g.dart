// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardRepositoryHash() =>
    r'499ad7ee7bee68377f5e9b210bf69021297e0069';

/// See also [dashboardRepository].
@ProviderFor(dashboardRepository)
final dashboardRepositoryProvider =
    AutoDisposeProvider<DashboardRepository>.internal(
  dashboardRepository,
  name: r'dashboardRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardRepositoryRef = AutoDisposeProviderRef<DashboardRepository>;
String _$currentAnalyticsHash() => r'25fe1597b482dcb02daef796cede578b6c6cc4ea';

/// See also [currentAnalytics].
@ProviderFor(currentAnalytics)
final currentAnalyticsProvider =
    AutoDisposeFutureProvider<SemesterAnalytics?>.internal(
  currentAnalytics,
  name: r'currentAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentAnalyticsRef = AutoDisposeFutureProviderRef<SemesterAnalytics?>;
String _$currentSemesterStateHash() =>
    r'4c44ed412c233fbfcd7a3f3fa5bb58f4b34d3a98';

/// See also [currentSemesterState].
@ProviderFor(currentSemesterState)
final currentSemesterStateProvider =
    AutoDisposeFutureProvider<UserSemesterState?>.internal(
  currentSemesterState,
  name: r'currentSemesterStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSemesterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentSemesterStateRef
    = AutoDisposeFutureProviderRef<UserSemesterState?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
