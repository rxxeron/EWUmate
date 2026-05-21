// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskRepositoryHash() => r'bca5e4152a8e16760cba91930c8f039cb4a24ae9';

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

typedef TaskRepositoryRef = AutoDisposeProviderRef<TaskRepository>;
String _$activeTasksConfigHash() => r'2691d365e902c1ccf70840da36096b720fb621f3';

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

typedef ActiveTasksConfigRef = AutoDisposeFutureProviderRef<List<Task>>;
String _$allTasksStreamHash() => r'd9f991c9f3ef24de84e45ad8b511068eb1616ec1';

/// See also [allTasksStream].
@ProviderFor(allTasksStream)
final allTasksStreamProvider = StreamProvider<List<Task>>.internal(
  allTasksStream,
  name: r'allTasksStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTasksStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllTasksStreamRef = StreamProviderRef<List<Task>>;
String _$userNotificationsHash() => r'0f5ac00b5c87baf692fe07e205028909638195ec';

/// See also [userNotifications].
@ProviderFor(userNotifications)
final userNotificationsProvider = StreamProvider<List<Notification>>.internal(
  userNotifications,
  name: r'userNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserNotificationsRef = StreamProviderRef<List<Notification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
