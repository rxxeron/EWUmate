// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskRepository)
final taskRepositoryProvider = TaskRepositoryProvider._();

final class TaskRepositoryProvider
    extends $FunctionalProvider<TaskRepository, TaskRepository, TaskRepository>
    with $Provider<TaskRepository> {
  TaskRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'taskRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$taskRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskRepository create(Ref ref) {
    return taskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskRepository>(value),
    );
  }
}

String _$taskRepositoryHash() => r'ad18cbe98edcc69337a096cea459a1d015087c8f';

@ProviderFor(activeTasksConfig)
final activeTasksConfigProvider = ActiveTasksConfigProvider._();

final class ActiveTasksConfigProvider extends $FunctionalProvider<
        AsyncValue<List<Task>>, List<Task>, FutureOr<List<Task>>>
    with $FutureModifier<List<Task>>, $FutureProvider<List<Task>> {
  ActiveTasksConfigProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'activeTasksConfigProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeTasksConfigHash();

  @$internal
  @override
  $FutureProviderElement<List<Task>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Task>> create(Ref ref) {
    return activeTasksConfig(ref);
  }
}

String _$activeTasksConfigHash() => r'd01486e6e05a38c38757d7405f8e4df4cb5352f6';

@ProviderFor(allTasksStream)
final allTasksStreamProvider = AllTasksStreamProvider._();

final class AllTasksStreamProvider extends $FunctionalProvider<
        AsyncValue<List<Task>>, List<Task>, Stream<List<Task>>>
    with $FutureModifier<List<Task>>, $StreamProvider<List<Task>> {
  AllTasksStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allTasksStreamProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allTasksStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Task>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Task>> create(Ref ref) {
    return allTasksStream(ref);
  }
}

String _$allTasksStreamHash() => r'62390525e22529e38c70bb08c6664e14cf7b3163';

@ProviderFor(userNotifications)
final userNotificationsProvider = UserNotificationsProvider._();

final class UserNotificationsProvider extends $FunctionalProvider<
        AsyncValue<List<Notification>>,
        List<Notification>,
        Stream<List<Notification>>>
    with
        $FutureModifier<List<Notification>>,
        $StreamProvider<List<Notification>> {
  UserNotificationsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userNotificationsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userNotificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<Notification>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Notification>> create(Ref ref) {
    return userNotifications(ref);
  }
}

String _$userNotificationsHash() => r'b1bcee306cec25deed8ad6d91b03c87a882e8ba6';
