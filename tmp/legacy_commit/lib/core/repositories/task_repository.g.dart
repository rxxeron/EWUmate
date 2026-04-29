// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskRepositoryHash() => r'9e7988bfbe891c27f3edb7806c66fb099e579966';

/// See also [taskRepository].
@ProviderFor(taskRepository)
final taskRepositoryProvider = AutoDisposeProvider<TaskRepository>.internal(
  taskRepository,
  name: r'taskRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TaskRepositoryRef = AutoDisposeProviderRef<TaskRepository>;
String _$activeTasksConfigHash() => r'b1ac84bc6044227978f0210e063b776e58fc9c80';

/// See also [activeTasksConfig].
@ProviderFor(activeTasksConfig)
final activeTasksConfigProvider =
    AutoDisposeFutureProvider<List<Task>>.internal(
      activeTasksConfig,
      name: r'activeTasksConfigProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeTasksConfigHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveTasksConfigRef = AutoDisposeFutureProviderRef<List<Task>>;
String _$allTasksStreamHash() => r'63ff74aa73c15c53cbcc1764657eba6aa383c81f';

/// See also [allTasksStream].
@ProviderFor(allTasksStream)
final allTasksStreamProvider = AutoDisposeStreamProvider<List<Task>>.internal(
  allTasksStream,
  name: r'allTasksStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTasksStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTasksStreamRef = AutoDisposeStreamProviderRef<List<Task>>;
String _$userNotificationsHash() => r'a31a9ff9c94d7fea8fe657f52f63929cfa48ce22';

/// See also [userNotifications].
@ProviderFor(userNotifications)
final userNotificationsProvider =
    AutoDisposeStreamProvider<List<Notification>>.internal(
      userNotifications,
      name: r'userNotificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userNotificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserNotificationsRef = AutoDisposeStreamProviderRef<List<Notification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
