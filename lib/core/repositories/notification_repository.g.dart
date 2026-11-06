// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

final class NotificationRepositoryProvider extends $FunctionalProvider<
    NotificationRepository,
    NotificationRepository,
    NotificationRepository> with $Provider<NotificationRepository> {
  NotificationRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'8c750b025c27c67cc4903e934580484f8d66fb38';

@ProviderFor(userNotifications)
final userNotificationsProvider = UserNotificationsProvider._();

final class UserNotificationsProvider extends $FunctionalProvider<
        AsyncValue<List<model.Notification>>,
        List<model.Notification>,
        Stream<List<model.Notification>>>
    with
        $FutureModifier<List<model.Notification>>,
        $StreamProvider<List<model.Notification>> {
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
  $StreamProviderElement<List<model.Notification>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<model.Notification>> create(Ref ref) {
    return userNotifications(ref);
  }
}

String _$userNotificationsHash() => r'eebd52319011dc931574270c3437050c6a6f4b7e';
