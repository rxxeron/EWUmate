// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationRepositoryHash() =>
    r'327e1554c8c855de1591dfa3c0eeb560e0f2cf00';

/// See also [notificationRepository].
@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    AutoDisposeProvider<NotificationRepository>.internal(
  notificationRepository,
  name: r'notificationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NotificationRepositoryRef
    = AutoDisposeProviderRef<NotificationRepository>;
String _$userNotificationsHash() => r'7316a30aac64b523a2a88d1b393c46cd89403e86';

/// See also [userNotifications].
@ProviderFor(userNotifications)
final userNotificationsProvider =
    StreamProvider<List<model.Notification>>.internal(
  userNotifications,
  name: r'userNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserNotificationsRef = StreamProviderRef<List<model.Notification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
