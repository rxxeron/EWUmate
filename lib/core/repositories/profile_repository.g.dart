// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider extends $FunctionalProvider<
    ProfileRepository,
    ProfileRepository,
    ProfileRepository> with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'1ffed8b36307a5a183773215871a4f787be3cbda';

@ProviderFor(userProfile)
final userProfileProvider = UserProfileProvider._();

final class UserProfileProvider extends $FunctionalProvider<
        AsyncValue<Profile?>, Profile?, Stream<Profile?>>
    with $FutureModifier<Profile?>, $StreamProvider<Profile?> {
  UserProfileProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userProfileProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $StreamProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Profile?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'fdffc6b3e819ddea9d6b41b672e205604ec956da';
